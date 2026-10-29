"""Run production XCUITest on a GitHub-hosted small iPhone, never locally."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess

from iphone_interaction_evidence import TESTS, expected_captures, validate_capture, validate_results


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def command(args, log=None, check=True):
    print("+ " + " ".join(map(str, args)), flush=True)
    result = subprocess.run(list(map(str, args)), text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if log:
        Path(log).write_text(result.stdout, encoding="utf-8")
    if result.returncode or not log:
        print(result.stdout[-18000:], flush=True)
    if check:
        result.check_returncode()
    return result


def export_evidence(root, category, device_id):
    bundle = root / f"{category}.xcresult"
    summary = json.loads(command(["xcrun", "xcresulttool", "get", "test-results", "summary",
                                  "--path", bundle, "--compact"], root / f"{category}-summary.json").stdout)
    tree = json.loads(command(["xcrun", "xcresulttool", "get", "test-results", "tests",
                               "--path", bundle, "--compact"], root / f"{category}-tests.json").stdout)
    exported = root / f"{category}-attachments"
    command(["xcrun", "xcresulttool", "export", "attachments", "--path", bundle, "--output-path", exported])
    validate_results(summary, tree, category, device_id)
    entries = json.loads((exported / "manifest.json").read_text())
    indexed = {}
    for entry in entries:
        for attachment in entry.get("attachments", []):
            filename = attachment.get("exportedFileName", "")
            source = exported / filename
            if not filename or not source.resolve().is_relative_to(exported.resolve()):
                raise ValueError("Unsafe exported attachment path")
            suggested = attachment.get("suggestedHumanReadableName", "")
            for name in expected_captures(category):
                for suffix in ("", "-provenance"):
                    key = name + suffix
                    if suggested == key or suggested.startswith(key + "_") or suggested.startswith(key + "."):
                        if key in indexed or attachment.get("deviceId") != device_id:
                            raise ValueError("Duplicated attachment or wrong exact simulator UDID")
                        indexed[key] = (source, entry.get("testIdentifier"))
    if set(indexed) != expected_captures(category) | {n + "-provenance" for n in expected_captures(category)}:
        raise ValueError("All eleven original screenshots and their provenance are required")
    evidence = root / "evidence"
    evidence.mkdir(exist_ok=True)
    records = []
    for name in sorted(expected_captures(category)):
        image, test = indexed[name]
        provenance, provenance_test = indexed[name + "-provenance"]
        header = image.read_bytes()[:24]
        if header[:8] != b"\x89PNG\r\n\x1a\n":
            raise ValueError("Original XCUIScreen attachment must be PNG")
        document = json.loads(provenance.read_text())
        validate_capture(document, category, struct.unpack(">II", header[16:24]))
        if test != provenance_test:
            raise ValueError("Screenshot and actions must come from the same actual test")
        shutil.copyfile(image, evidence / (name + ".png"))
        shutil.copyfile(provenance, evidence / (name + ".json"))
        records.append({"name": name, "testIdentifier": test,
                        "sha256": hashlib.sha256(image.read_bytes()).hexdigest(),
                        "provenanceSha256": hashlib.sha256(provenance.read_bytes()).hexdigest()})
    return records


def main():
    if os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("RUNNER_ENVIRONMENT") != "github-hosted":
        raise SystemExit("Only a real GitHub-hosted runner may build or operate a simulator")
    root = Path("iphone-interaction-results")
    root.mkdir(exist_ok=True)
    sha = command(["git", "rev-parse", "HEAD"]).stdout.strip()
    if sha != os.environ["GITHUB_SHA"] or (os.environ.get("EXPECTED_SHA") and sha != os.environ["EXPECTED_SHA"]):
        raise SystemExit("Requested and checked-out commit SHA must match exactly")
    manifest = {"schemaVersion": 1, "source": "public-XCUITest-production-app", "commitSha": sha,
                "branch": os.environ["GITHUB_REF_NAME"], "runId": os.environ["GITHUB_RUN_ID"],
                "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"], "workflow": "iPhone Interaction",
                "realInferenceVerified": False, "signedDistributionVerified": False,
                "outcomes": {}, "captures": []}
    write_json(root / "manifest.json", manifest)
    command(["xcodebuild", "-version"], root / "xcode-version.log")
    runtimes = json.loads(command(["xcrun", "simctl", "list", "runtimes", "--json"], root / "runtimes.json").stdout)
    available = [r for r in runtimes["runtimes"] if r.get("isAvailable") and ".iOS-" in r["identifier"]]
    runtime = max(available, key=lambda r: tuple(map(int, r["version"].split("."))))
    device_id = command(["xcrun", "simctl", "create", "LocalGemma small phone interaction",
                         "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation", runtime["identifier"]]).stdout.strip()
    if not re.fullmatch(r"[A-Fa-f0-9-]{36}", device_id):
        raise ValueError("simctl must return a full simulator UDID")
    manifest.update({"deviceId": device_id, "deviceType": "iPhone SE (3rd generation)",
                     "runtime": runtime, "screenPoints": [375, 667]})
    write_json(root / "manifest.json", manifest)
    command(["xcrun", "simctl", "boot", device_id])
    command(["xcrun", "simctl", "bootstatus", device_id, "-b"], root / "boot.log")
    command(["xcrun", "simctl", "status_bar", device_id, "override", "--time", "9:41",
             "--batteryState", "charged", "--batteryLevel", "100"])
    base = ["xcodebuild", "-project", "LocalGemma.xcodeproj", "-scheme", "LocalGemmaInteraction",
            "-configuration", "Debug", "-sdk", "iphonesimulator", "-destination", f"platform=iOS Simulator,id={device_id}",
            "-derivedDataPath", ".derivedData-interaction", "CODE_SIGNING_ALLOWED=NO"]
    build = command(base + ["-resultBundlePath", root / "build.xcresult", "build-for-testing"], root / "build.log", check=False)
    manifest["outcomes"]["build"] = "success" if build.returncode == 0 else "failure"
    for category, setting in (("large", "large"), ("accessibility5", "accessibility-extra-extra-extra-large")):
        if build.returncode:
            manifest["outcomes"][category] = "not-run-build-failed"
            continue
        try:
            command(["xcrun", "simctl", "ui", device_id, "content_size", setting])
            actual = command(["xcrun", "simctl", "ui", device_id, "content_size"], root / f"{category}-system-content-size.txt").stdout
            if setting not in actual:
                raise ValueError("Actual simulator Dynamic Type setting must match requested category")
            tests = [f"-only-testing:LocalGemmaUITests/CompactSummaryInteractionTests/{name}" for name in sorted(TESTS[category])]
            test = command(base + ["-resultBundlePath", root / f"{category}.xcresult", "-parallel-testing-enabled", "NO",
                                   "-test-timeouts-enabled", "YES", "-maximum-test-execution-time-allowance", "240",
                                   *tests, "test-without-building"], root / f"{category}-test.log", check=False)
            records = export_evidence(root, category, device_id)
            if test.returncode:
                raise RuntimeError(f"xcodebuild test failed: {test.returncode}")
            manifest["captures"].extend(records)
            manifest["outcomes"][category] = "success"
        except Exception as error:
            manifest["outcomes"][category] = "failure"
            (root / f"{category}-error.txt").write_text(str(error) + "\n")
            print(f"{category}: {error}", flush=True)
        write_json(root / "manifest.json", manifest)
    write_json(root / "manifest.json", manifest)
    if set(manifest["outcomes"].values()) != {"success"} or len(manifest["captures"]) != 22:
        raise SystemExit("Required iPhone UI interactions or original screenshot evidence failed")


if __name__ == "__main__":
    main()
