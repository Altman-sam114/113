"""Cloud-only comparison with an unmodified, pinned upstream llama.cpp example."""
import hashlib
import json
import subprocess
from pathlib import Path
from prepare_llama_dependency import COMMIT, require, require_hosted_macos

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA256 = "5f3160b48b5c0adff984dfdc6ad39cf9ee113b4d63600596f2127f9a0b9a869e"
SOURCE_BLOB = "ebb1969fb5d5c53679087154c0d2dfae234865c9"
LICENSE_SHA256 = "94f29bbed6a22c35b992c5c6ebf0e7c92f13b836b90f36f461c9cf2f0f1d010d"
DIAGNOSTIC_CASES = ("translate-en-zh", "control-en-arithmetic")


def validate_reference_source(directory):
    source = directory / "llama-simple.cpp"
    license_file = directory / "llama-LICENSE"
    metadata = json.loads((directory / "source.json").read_text())
    data = source.read_bytes()
    require(not source.is_symlink() and not license_file.is_symlink()
            and hashlib.sha256(data).hexdigest() == SOURCE_SHA256
            and hashlib.sha1(("blob " + str(len(data)) + "\0").encode() + data).hexdigest() == SOURCE_BLOB
            and hashlib.sha256(license_file.read_bytes()).hexdigest() == LICENSE_SHA256,
            "The independent comparison requires the exact pinned upstream program and MIT notice")
    require(metadata.get("sourceCommit") == COMMIT and metadata.get("sourcePath") == "examples/simple/simple.cpp"
            and metadata.get("sourceSHA256") == SOURCE_SHA256 and metadata.get("sourceGitBlob") == SOURCE_BLOB
            and metadata.get("unmodifiedUpstreamSource") is True and metadata.get("license") == "MIT"
            and metadata.get("licenseSHA256") == LICENSE_SHA256,
            "Independent program provenance cannot be changed")
    return source, metadata


def rendered_gemma_user(prompt):
    require(isinstance(prompt, str) and bool(prompt.strip()) and "\0" not in prompt,
            "A complete single-user synthetic prompt is required")
    # Exact single-user framing from the pinned src/llama-chat.cpp Gemma branch.
    # BOS is added by the example's actual model tokenizer, not inserted twice.
    return "<start_of_turn>user\n" + prompt.strip() + "<end_of_turn>\n<start_of_turn>model\n"


def parse_reference_output(stdout, rendered):
    prefix = "<bos>" + rendered
    require(stdout.startswith(prefix) and stdout.endswith("\n"),
            "Reference stdout did not contain the complete round-tripped prompt and program terminator")
    # Remove only the example's prompt echo and its final printf newline.
    return stdout[len(prefix):-1]


def run_reference_diagnostic(model, framework, sdk, architecture, private, result, environment, probe):
    require_hosted_macos(environment)
    source, metadata = validate_reference_source(ROOT / "Tools/reference")
    require(architecture in {"arm64", "x86_64"}, "Unsupported independent diagnostic architecture")
    executable = private / "upstream-simple"
    command = ["xcrun", "--sdk", "macosx", "clang++", "-std=c++17", "-isysroot", sdk,
               "-target", f"{architecture}-apple-ios17.0-macabi",
               "-I", str(framework / "llama.framework/Headers"), "-F", str(framework),
               "-framework", "llama", "-Xlinker", "-rpath", "-Xlinker", str(framework),
               str(source), "-o", str(executable)]
    with (result / "reference-build.log").open("w") as log:
        subprocess.run(command, env=environment, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180)
    records = {r["id"]: r for r in probe["taskQuality"]["cases"]}
    comparisons = []
    for identifier in DIAGNOSTIC_CASES:
        production = records[identifier]
        rendered = rendered_gemma_user(production["prompt"])
        completed = subprocess.run([str(executable), "-m", str(model), "-ngl", "0", "-n", "512", rendered],
                                   env=environment, text=True, capture_output=True, check=False, timeout=120)
        (result / f"reference-{identifier}-stdout.log").write_text(completed.stdout)
        (result / f"reference-{identifier}-stderr.log").write_text(completed.stderr)
        require(completed.returncode == 0, "The upstream diagnostic failed; raw stdout/stderr remain available")
        text = parse_reference_output(completed.stdout, rendered)
        comparisons.append({"id": identifier, "prompt": production["prompt"], "renderedPrompt": rendered,
                            "referenceText": text, "productionText": production["text"],
                            "exactTextMatch": text == production["text"],
                            "trimmedTextMatch": text.strip() == production["text"].strip()})
    report = {"schemaVersion": 1, "status": "collected", "source": "unmodified-pinned-upstream-simple-cpp",
              "commitSha": probe["commitSha"], "runId": probe["runId"], "runAttempt": probe["runAttempt"],
              "modelSHA256": probe["modelSHA256"], "upstream": metadata,
              "caseCount": len(comparisons), "comparisons": comparisons,
              "sameProductionSettings": False, "productionQualityGateReplaced": False,
              "limitation": "The upstream example uses its own batch/context defaults and a greedy CPU sampler; this diagnoses a separate code path, not general quality or device equivalence."}
    (result / "reference-diagnostic.json").write_text(json.dumps(report, indent=2) + "\n")
    return report
