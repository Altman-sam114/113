"""Cloud-only real inference using an explicitly supplied encrypted draft fixture."""
import hashlib
import json
import math
import os
import platform
import re
import subprocess
from pathlib import Path

from prepare_llama_dependency import require, require_hosted_macos

ROOT = Path(__file__).resolve().parents[1]
FIXTURE_SHA256 = "3626e245220ca4a1c5911eb4010b3ecb7bdbf5bc53c79403c21355354d1e2dc6"
FIXTURE_BYTES = 241_410_624
PRODUCTION_MODEL_FILENAME = "gemma-3-270m-it-qat-Q4_0.gguf"
PRODUCTION_MODEL_ID = "5D5BA6B9-6EBC-43A9-A7B6-21FA9332C270"


def validate_production_report(report, expected_sha, run_id, attempt):
    require(report.get("schemaVersion") == 2 and report.get("status") == "success"
            and report.get("source") == "cloud-Catalyst-production-state-and-LlamaTextRuntime",
            "Bottom-level fixture evidence cannot replace the production state flow")
    require(report.get("commitSha") == expected_sha and report.get("runId") == run_id
            and report.get("runAttempt") == attempt and report.get("modelSHA256") == FIXTURE_SHA256
            and report.get("modelBytes") == FIXTURE_BYTES,
            "Production inference evidence has the wrong source or model identity")
    require(report.get("fixtureOnly") is False and report.get("productionModelVerified") is True
            and report.get("deviceMemoryOrMetalVerified") is False
            and report.get("signedDistributionVerified") is False,
            "CPU production verification must retain its physical-device and signing limits")
    flow = report.get("productionFlow", {})
    require(flow.get("source") == "headless-production-ModelCatalog-VerifiedLlamaRuntime-InferenceEngine"
            and flow.get("modelID") == PRODUCTION_MODEL_ID and flow.get("modelName") == "Gemma 3 270M"
            and flow.get("fileName") == PRODUCTION_MODEL_FILENAME and flow.get("sha256") == FIXTURE_SHA256,
            "The production catalogue, runtime and engine must use the same pinned model")
    for key in ["importedAndVerified", "backupExcluded", "unverifiedDraftPreserved", "exportPreservesFullHistory",
                "stoppedAfterActualText", "lateEventsIsolated", "changedManagedFileRejected", "sourceUnmodified",
                "fullContextRejectedWithoutTruncation"]:
        require(flow.get(key) is True, f"Missing actual production evidence: {key}")
    require(flow.get("UIFilePickerExercised") is False and flow.get("deviceMemoryOrMetalVerified") is False,
            "The headless probe cannot claim Files UI or physical-device verification")
    turns = flow.get("turns")
    require(isinstance(turns, list) and len(turns) == 2, "Two actual production conversation turns are required")
    for turn in turns + [flow.get("reloadAfterStop", {}), flow.get("reimportRecovery", {})]:
        rate = turn.get("tokensPerSecond")
        require("ORCHID" in turn.get("text", "").upper() and type(turn.get("outputTokens")) is int
                and turn["outputTokens"] > 0 and type(rate) in {int, float} and math.isfinite(rate) and rate > 0
                and turn.get("simulated") is False and turn.get("backend") == "llamaCpp",
                "Production responses must contain native text and actual metrics, never simulated success")


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
    quality_input = os.environ.get("INCLUDE_TASK_QUALITY", "false")
    require(quality_input in {"true", "false"}, "Task-quality mode must be an explicit boolean")
    include_quality = quality_input == "true"
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
    encrypted, model = private / "fixture.enc", private / PRODUCTION_MODEL_FILENAME
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
        "modelSHA256": digest, "modelBytes": model.stat().st_size, "fixtureOnly": False,
        "modelRole": "registered-production-model", "modelFileName": PRODUCTION_MODEL_FILENAME,
        "modelIncludedInArtifacts": False, "signedDistributionVerified": False,
        "taskQualityRequested": include_quality,
    }, indent=2) + "\n")
    sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()
    architecture = platform.machine()
    require(architecture in {"arm64", "x86_64"}, "Unsupported hosted architecture")
    framework = ROOT / ".runtime/app-bundle/llama.xcframework/ios-arm64_x86_64-maccatalyst"
    support = Path(sdk) / "System/iOSSupport"
    executable = private / "native-text-smoke"
    command = ["xcrun", "swiftc", "-swift-version", "6", "-sdk", sdk,
               "-target", f"{architecture}-apple-ios17.0-macabi",
               "-F", str(support / "System/Library/Frameworks"),
               "-I", str(support / "usr/include"), "-L", str(support / "usr/lib"), "-F", str(framework),
               "-framework", "llama", "-Xlinker", "-rpath", "-Xlinker", str(framework),
               *[str(ROOT / name) for name in [
                   "LocalGemma/AppState.swift", "LocalGemma/ArtifactImport.swift",
                   "LocalGemma/ConversationStore.swift", "LocalGemma/RuntimeStreaming.swift",
                   "LocalGemma/LlamaTextRuntime.swift", "Tools/NativeProductionSmoke.swift", "Tools/NativeTextSmoke.swift"
               ]],
               "-o", str(executable)]
    with (result / "build.log").open("w") as log:
        subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
    environment = dict(os.environ, NATIVE_FIXTURE_PATH=str(model), NATIVE_PROBE_OUTPUT=str(result / "probe.json"))
    environment.pop("NATIVE_QUALITY_CASES_PATH", None)
    if include_quality:
        environment["NATIVE_QUALITY_CASES_PATH"] = str(ROOT / "Tools/fixtures/task_quality_270m.json")
    environment.pop("GH_TOKEN", None)
    environment.pop("LOCALGEMMA_NATIVE_FIXTURE_KEY", None)
    with (result / "run.log").open("w") as log:
        subprocess.run([str(executable)], env=environment, stdout=log, stderr=subprocess.STDOUT,
                       check=True, timeout=600 if include_quality else 300)
    probe = json.loads((result / "probe.json").read_text())
    validate_production_report(probe, expected, os.environ["GITHUB_RUN_ID"], os.environ["GITHUB_RUN_ATTEMPT"])
    if include_quality:
        from task_quality_evidence import validate_task_quality_report
        cases = ROOT / "Tools/fixtures/task_quality_270m.json"
        review = validate_task_quality_report(probe, cases, expected,
                                              os.environ["GITHUB_RUN_ID"], os.environ["GITHUB_RUN_ATTEMPT"])
        (result / "task-quality-cases.json").write_bytes(cases.read_bytes())
        (result / "task-quality-checks.json").write_text(json.dumps(review, indent=2) + "\n")
        require(review["automaticFailureCount"] == 0,
                "Frozen task checks failed; all original answers and criteria remain in the artifact")
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
