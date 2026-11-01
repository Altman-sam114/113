"""Cloud-only real inference using an explicitly supplied encrypted draft fixture."""
import hashlib
import json
import os
import platform
import re
import subprocess
from pathlib import Path

from prepare_llama_dependency import require, require_hosted_macos

ROOT = Path(__file__).resolve().parents[1]
FIXTURE_SHA256 = "3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6"
FIXTURE_BYTES = 241_410_624


def validate_draft_fixture(release, expected_tag):
    require(re.fullmatch(r"agentx-native-fixture-[a-z0-9-]{1,60}", expected_tag) is not None,
            "Only the task's temporary fixture draft is accepted")
    require(release.get("draft") is True and release.get("tag_name") == expected_tag,
            "The supplied model must remain a private, unpublished draft asset")
    assets = [asset for asset in release.get("assets", []) if asset.get("name") == "native-fixture.gguf.enc"]
    require(len(assets) == 1 and type(assets[0].get("id")) is int and assets[0]["id"] > 0,
            "Exactly one encrypted local model fixture is required")
    require(FIXTURE_BYTES < assets[0].get("size", 0) < FIXTURE_BYTES + 1024,
            "Unexpected encrypted fixture size")
    return assets[0]["id"]


def find_draft_fixture(releases, expected_tag):
    require(isinstance(releases, list), "Expected the authenticated release list")
    matches = [release for release in releases if release.get("tag_name") == expected_tag]
    require(len(matches) == 1, "The temporary fixture draft is missing or ambiguous")
    return validate_draft_fixture(matches[0], expected_tag)


def main():
    require_hosted_macos(os.environ)
    expected = os.environ["EXPECTED_SHA"]
    require(re.fullmatch(r"[a-f0-9]{40}", expected) is not None
            and os.environ.get("GITHUB_REF") == "refs/heads/main"
            and expected == os.environ["GITHUB_SHA"]
            == subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
            "The exact current main SHA is required")
    key = os.environ.get("LOCALGEMMA_NATIVE_FIXTURE_KEY", "")
    require(len(key) >= 32, "The one-use decryption key is missing")
    tag = os.environ["FIXTURE_RELEASE_TAG"]
    require(re.fullmatch(r"agentx-native-fixture-[a-z0-9-]{1,60}", tag) is not None,
            "Only a task-specific fixture draft is accepted")
    # The by-tag endpoint exposes published releases. Authenticated listing also
    # includes drafts without creating a public git tag or publishing the model.
    releases = json.loads(subprocess.check_output([
        "gh", "api", "repos/Altman-sam114/113/releases?per_page=100"], text=True))
    asset_id = find_draft_fixture(releases, tag)
    private = Path(os.environ["RUNNER_TEMP"]) / "localgemma-native-fixture"
    private.mkdir(mode=0o700)
    encrypted, model = private / "fixture.enc", private / "fixture.gguf"
    with encrypted.open("wb") as stream:
        subprocess.run(["gh", "api", f"repos/Altman-sam114/113/releases/assets/{asset_id}",
                        "-H", "Accept: application/octet-stream"], stdout=stream, check=True, timeout=600)
    subprocess.run(["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "100000",
                    "-in", str(encrypted), "-out", str(model),
                    "-pass", "env:LOCALGEMMA_NATIVE_FIXTURE_KEY"], check=True, timeout=120)
    with model.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    require(model.stat().st_size == FIXTURE_BYTES and digest == FIXTURE_SHA256,
            "Decrypted bytes differ from the user's explicitly authorized local fixture")
    result = ROOT / "native-text-results"
    result.mkdir()
    (result / "identity.json").write_text(json.dumps({
        "commitSha": expected, "runId": os.environ["GITHUB_RUN_ID"], "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"],
        "modelSHA256": digest, "modelBytes": model.stat().st_size, "fixtureOnly": True,
        "modelIncludedInArtifacts": False, "signedDistributionVerified": False,
    }, indent=2) + "\n")
    sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()
    architecture = platform.machine()
    require(architecture in {"arm64", "x86_64"}, "Unsupported hosted architecture")
    framework = ROOT / ".runtime/llama.xcframework/ios-arm64_x86_64-maccatalyst"
    executable = private / "native-text-smoke"
    command = ["xcrun", "swiftc", "-swift-version", "6", "-sdk", sdk,
               "-target", f"{architecture}-apple-ios17.0-macabi", "-F", str(framework),
               "-framework", "llama", "-Xlinker", "-rpath", "-Xlinker", str(framework),
               str(ROOT / "LocalGemma/LlamaTextRuntime.swift"), str(ROOT / "Tools/NativeTextSmoke.swift"),
               "-o", str(executable)]
    with (result / "build.log").open("w") as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
    environment = dict(os.environ, NATIVE_FIXTURE_PATH=str(model), NATIVE_PROBE_OUTPUT=str(result / "probe.json"))
    environment.pop("GH_TOKEN", None)
    environment.pop("LOCALGEMMA_NATIVE_FIXTURE_KEY", None)
    with (result / "run.log").open("w") as log:
        subprocess.run([str(executable)], env=environment, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=300)
    print("Real native fixture evidence saved; no weights or keys are in the result artifact")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        require_hosted_macos(os.environ)
        result = ROOT / "native-text-results"
        result.mkdir(exist_ok=True)
        (result / "failure.json").write_text(json.dumps({
            "status": "failure", "commitSha": os.environ.get("GITHUB_SHA"),
            "runId": os.environ.get("GITHUB_RUN_ID"), "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
            "error": str(error), "modelIncludedInArtifacts": False,
        }, indent=2) + "\n")
        raise
