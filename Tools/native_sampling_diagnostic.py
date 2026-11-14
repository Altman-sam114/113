"""Cloud-only, predeclared sampler comparison; production quality evidence is separate."""
import difflib
import hashlib
import json
import math
import os
import platform
import re
import subprocess
from pathlib import Path

from prepare_llama_dependency import COMMIT, require, require_hosted_macos
from run_native_text_smoke import FIXTURE_BYTES, FIXTURE_SHA256, PRODUCTION_MODEL_FILENAME, find_draft_fixture
from task_quality_evidence import normalized

ROOT = Path(__file__).resolve().parents[1]
PROFILES_SHA256 = "a9126daa8d013622264632ad0dcfe88426ae71f378e6139eebb1ee561f11144b"
CASES_SHA256 = "faea8e8be6f458f496a4c51b26718764c04c23019c8e651ee155411d7ca9ed46"
RUNTIME_SHA256 = "64477baea1cacee4f56447a6e3479acd6d0c3dd721e43d71eb330858d3455930"
SAMPLER_CREATION = "guard let sampler = llama_sampler_init_greedy() else { throw LlamaTextRuntimeError.allocationFailed }"
EXPERIMENTAL_CREATION = "guard let sampler = try NativeSamplingFactory.makeSampler() else { throw LlamaTextRuntimeError.allocationFailed }"
PROFILE_IDS = ["greedy", "aitrans-seed42", "aitrans-seed1337", "aitrans-seed2026"]


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def load_definitions(cases_data, profiles_data):
    require(sha256(cases_data) == CASES_SHA256 and sha256(profiles_data) == PROFILES_SHA256,
            "The full task set, criteria, profiles and seeds must remain frozen")
    cases, profiles = json.loads(cases_data), json.loads(profiles_data)
    require([p["id"] for p in profiles["profiles"]] == PROFILE_IDS
            and profiles["runtimeSHA256"] == RUNTIME_SHA256 and profiles["casesSHA256"] == CASES_SHA256,
            "Frozen profile identity differs")
    return cases, profiles


def diagnostic_source(data):
    require(sha256(data) == RUNTIME_SHA256, "Production runtime changed; review and freeze a new experiment first")
    text = data.decode()
    require(text.count(SAMPLER_CREATION) == 1, "Exactly one original sampler creation is required")
    return text.replace(SAMPLER_CREATION, EXPERIMENTAL_CREATION, 1).encode()


def validate_reports(reports, cases_data, profiles_data, expected_sha, run_id, attempt):
    definition, profiles = load_definitions(cases_data, profiles_data)
    require(isinstance(reports, list) and len(reports) == 4
            and [r.get("profileID") for r in reports] == PROFILE_IDS,
            "All four predeclared profiles are required in order")
    checks = []
    for report in reports:
        require(type(report.get("schemaVersion")) is int and report["schemaVersion"] == 1 and report.get("status") == "collected"
                and report.get("source") == "cloud-Catalyst-isolated-sampling-diagnostic"
                and report.get("commitSha") == expected_sha and report.get("runId") == run_id
                and report.get("runAttempt") == attempt,
                "Sampling evidence must match its actual source, SHA, run and attempt")
        require(report.get("modelSHA256") == FIXTURE_SHA256 and report.get("modelBytes") == FIXTURE_BYTES
                and report.get("casesSHA256") == CASES_SHA256 and report.get("profilesSHA256") == PROFILES_SHA256
                and report.get("contextLength") == 4096 and report.get("maximumOutputTokens") == 512,
                "Model bytes, original tasks and budgets cannot change between profiles")
        for key in ["productionDefaultChanged", "productionStateFlowVerified", "deviceMemoryOrMetalVerified",
                    "generalTaskQualityVerified"]:
            require(report.get(key) is False, "Isolated sampler evidence cannot claim production, device or quality acceptance")
        require(report.get("manualReviewRequired") is True, "Every answer still requires semantic review")
        results = report.get("cases")
        require(isinstance(results, list) and [r.get("id") for r in results] == [c["id"] for c in definition["cases"]],
                "Each profile must retain all ten tasks and original order")
        case_checks = []
        for task, result in zip(definition["cases"], results):
            require(result.get("templateID") == (task["templateID"] or "")
                    and result.get("prompt") == task["expectedTemplatePrompt"] + task["input"],
                    "The original complete prompt must be preserved")
            text = result.get("text")
            require(isinstance(text, str) and isinstance(result.get("error"), str)
                    and type(result.get("runtimeSucceeded")) is bool and result.get("simulated") is False
                    and result.get("backend") == "llamaCpp", "Original text, errors and native identity are required")
            require(type(result.get("promptTokens")) is int and 0 <= result["promptTokens"] <= 3584
                    and type(result.get("outputTokens")) is int and 0 <= result["outputTokens"] <= 512,
                    "Actual prompt and output token counts must be bounded")
            for key in ["tokensPerSecond", "loadSeconds", "prefillSeconds", "generationSeconds", "elapsedSeconds"]:
                require(type(result.get(key)) in {int, float} and math.isfinite(result[key]) and result[key] >= 0,
                        "Actual finite metrics are required")
            succeeded = result["runtimeSucceeded"]
            if succeeded:
                require(not result["error"] and bool(text.strip()) and result["promptTokens"] > 0
                        and result["outputTokens"] > 0 and result["tokensPerSecond"] > 0
                        and result.get("finishReason") in {"endOfGeneration", "outputLimit"},
                        "A successful sample requires native text, metrics and a completion reason")
                require(result["finishReason"] != "outputLimit" or result["outputTokens"] == 512,
                        "An output limit must retain the full frozen output budget")
            else:
                require(bool(result["error"]) and result.get("finishReason") == "error",
                        "A runtime failure must retain its original error")
            value = normalized(text)
            missing = [g for g in task["requiredConcepts"] if not any(normalized(t) in value for t in g)]
            exact = task.get("acceptedExact")
            exact_passed = exact is None or text.strip() in exact
            case_checks.append({"id": task["id"], "runtimeSucceeded": succeeded, "missingConcepts": missing,
                                "exactInstructionPassed": exact_passed,
                                "automaticChecksPassed": succeeded and not missing and exact_passed,
                                "outputLimited": result["finishReason"] == "outputLimit",
                                "rubric": task["rubric"], "humanSemanticReview": "required"})
        checks.append({"profileID": report["profileID"], "caseCount": 10,
                       "automaticFailureCount": sum(not c["automaticChecksPassed"] for c in case_checks),
                       "outputLimitedCount": sum(c["outputLimited"] for c in case_checks), "checks": case_checks})
    sampled_passed = all(c["automaticFailureCount"] == 0 for c in checks[1:])
    return {"schemaVersion": 1, "commitSha": expected_sha, "runId": run_id, "runAttempt": attempt,
            "source": "isolated-sampling-diagnostic-review", "caseCount": 40, "profiles": checks,
            "status": "automatic-checks-passed-awaiting-human-review" if sampled_passed else "candidate-automatic-checks-failed",
            "allSampledAutomaticChecksPassed": sampled_passed, "manualReviewRequired": True,
            "productionDefaultChanged": False, "productionQualityGateReplaced": False,
            "generalTaskQualityVerified": False,
            "limitation": "Same frozen fact/exact checks; every full answer still requires its original semantic rubric. CPU diagnostic copies do not verify production state flow, UI, Metal, device memory or signing."}


def main():
    require_hosted_macos(os.environ)
    expected = os.environ["EXPECTED_SHA"]
    require(re.fullmatch(r"[a-f0-9]{40}", expected) is not None
            and os.environ.get("GITHUB_REF") == "refs/heads/main"
            and expected == os.environ["GITHUB_SHA"]
            == subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
            "The exact current main SHA is required")
    result = ROOT / "sampling-results"
    result.mkdir()
    cases_data = (ROOT / "Tools/fixtures/task_quality_270m.json").read_bytes()
    profiles_data = (ROOT / "Tools/fixtures/sampling_profiles_270m.json").read_bytes()
    _, profiles = load_definitions(cases_data, profiles_data)
    original = (ROOT / "LocalGemma/LlamaTextRuntime.swift").read_bytes()
    modified = diagnostic_source(original)
    sources = result / "sources"
    sources.mkdir()
    (sources / "ProductionLlamaTextRuntime.swift").write_bytes(original)
    diagnostic = sources / "DiagnosticLlamaTextRuntime.swift"
    diagnostic.write_bytes(modified)
    probe = sources / "NativeSamplingProbe.swift"
    probe.write_bytes((ROOT / "Tools/NativeSamplingProbe.swift").read_bytes())
    (sources / "sampler-only.diff").write_text("".join(difflib.unified_diff(
        original.decode().splitlines(True), modified.decode().splitlines(True),
        fromfile="ProductionLlamaTextRuntime.swift", tofile="DiagnosticLlamaTextRuntime.swift")))
    cases_path, profiles_path = result / "task_quality_270m.json", result / "sampling_profiles_270m.json"
    cases_path.write_bytes(cases_data)
    profiles_path.write_bytes(profiles_data)
    identity = {"schemaVersion": 1, "commitSha": expected, "runId": os.environ["GITHUB_RUN_ID"],
                "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"], "modelSHA256": FIXTURE_SHA256,
                "modelBytes": FIXTURE_BYTES, "casesSHA256": CASES_SHA256, "profilesSHA256": PROFILES_SHA256,
                "productionRuntimeSHA256": sha256(original), "diagnosticRuntimeSHA256": sha256(modified),
                "probeSHA256": sha256(probe.read_bytes()), "upstreamCommit": COMMIT,
                "productionDefaultChanged": False, "modelIncludedInArtifacts": False,
                "source": "isolated-sampling-diagnostic-not-production-state-flow"}
    (result / "identity.json").write_text(json.dumps(identity, indent=2) + "\n")
    require(len(os.environ.get("LOCALGEMMA_SAMPLING_FIXTURE_KEY", "")) >= 32, "The one-use sampling key is missing")
    tag = os.environ["FIXTURE_RELEASE_TAG"]
    releases = json.loads(subprocess.check_output([
        "gh", "api", "repos/Altman-sam114/113/releases?per_page=100"], text=True))
    asset_id = find_draft_fixture(releases, tag)
    private = Path(os.environ["RUNNER_TEMP"]) / "localgemma-sampling-fixture"
    private.mkdir(mode=0o700)
    encrypted, model = private / "fixture.enc", private / PRODUCTION_MODEL_FILENAME
    with encrypted.open("wb") as stream:
        subprocess.run(["gh", "api", f"repos/Altman-sam114/113/releases/assets/{asset_id}",
                        "-H", "Accept: application/octet-stream"], stdout=stream, check=True, timeout=600)
    require(encrypted.stat().st_size == FIXTURE_BYTES + 32, "Unexpected encrypted fixture size")
    subprocess.run(["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "100000", "-md", "sha256",
                    "-in", str(encrypted), "-out", str(model), "-pass", "env:LOCALGEMMA_SAMPLING_FIXTURE_KEY"],
                   check=True, timeout=120)
    with model.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    require(model.stat().st_size == FIXTURE_BYTES and digest == FIXTURE_SHA256, "User model bytes differ")
    environment = {k: v for k, v in os.environ.items()
                   if k not in {"GH_TOKEN", "GITHUB_TOKEN"} and not k.endswith("FIXTURE_KEY")}
    sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()
    architecture = platform.machine()
    require(architecture in {"arm64", "x86_64"}, "Unsupported hosted architecture")
    framework = ROOT / ".runtime/app-bundle/llama.xcframework/ios-arm64_x86_64-maccatalyst"
    support = Path(sdk) / "System/iOSSupport"
    executable = private / "sampling-probe"
    command = ["xcrun", "swiftc", "-swift-version", "6", "-sdk", sdk,
               "-target", f"{architecture}-apple-ios17.0-macabi",
               "-F", str(support / "System/Library/Frameworks"), "-I", str(support / "usr/include"),
               "-L", str(support / "usr/lib"), "-F", str(framework), "-framework", "llama",
               "-Xlinker", "-rpath", "-Xlinker", str(framework), str(diagnostic), str(probe), "-o", str(executable)]
    with (result / "build.log").open("w") as log:
        subprocess.run(command, env=environment, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
    for name, path in [("native-manifest.json", ROOT / ".runtime/manifest.json"),
                       ("native-staging-manifest.json", ROOT / ".runtime/app-bundle/manifest.json")]:
        (result / name).write_bytes(path.read_bytes())
    reports, failures = [], []
    for profile in profiles["profiles"]:
        identifier = profile["id"]
        output = result / f"{identifier}.json"
        child = dict(environment, NATIVE_FIXTURE_PATH=str(model), SAMPLING_OUTPUT=str(output),
                     SAMPLING_CASES_PATH=str(cases_path), SAMPLING_PROFILES_PATH=str(profiles_path),
                     SAMPLING_PROFILE_ID=identifier)
        try:
            with (result / f"{identifier}.log").open("w") as log:
                completed = subprocess.run([str(executable)], env=child, stdout=log, stderr=subprocess.STDOUT,
                                           check=False, timeout=360)
            require(completed.returncode == 0, f"Profile {identifier} failed; original partial evidence is retained")
            reports.append(json.loads(output.read_text()))
        except (subprocess.TimeoutExpired, ValueError) as error:
            failures.append(str(error))
    require(not failures, "; ".join(failures))
    review = validate_reports(reports, cases_data, profiles_data, expected,
                              os.environ["GITHUB_RUN_ID"], os.environ["GITHUB_RUN_ATTEMPT"])
    (result / "automatic-review.json").write_text(json.dumps(review, ensure_ascii=False, indent=2) + "\n")
    with model.open("rb") as stream:
        require(hashlib.file_digest(stream, "sha256").hexdigest() == FIXTURE_SHA256, "Source model changed")
    require(review["allSampledAutomaticChecksPassed"],
            "Sampling candidates failed frozen fact/exact checks; all 40 original answers remain in the artifact")
    print("Collected all 40 answers; semantic review and production quality acceptance remain required")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        require_hosted_macos(os.environ)
        result = ROOT / "sampling-results"
        result.mkdir(exist_ok=True)
        (result / "failure.json").write_text(json.dumps({
            "status": "failure", "commitSha": os.environ.get("GITHUB_SHA"), "runId": os.environ.get("GITHUB_RUN_ID"),
            "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT"), "error": str(error), "modelIncludedInArtifacts": False
        }, indent=2) + "\n")
        raise
