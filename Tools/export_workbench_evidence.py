"""Export production-view XCTest attachments on GitHub Actions, never locally."""
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess


def xcresult_json(bundle, command, destination):
    args = ["xcrun", "xcresulttool", "get", "test-results", command,
            "--path", str(bundle), "--compact"]
    result = subprocess.run(args, text=True, capture_output=True)
    if result.returncode:
        print(result.stderr.strip() or result.stdout.strip())
        result.check_returncode()
    document = json.loads(result.stdout)
    destination.write_text(result.stdout + "\n", encoding="utf-8")
    print(f"Exported {command}: {destination}")
    return document


def attachment_name_matches(suggested_name, expected_name):
    return (suggested_name == expected_name
            or suggested_name.startswith(expected_name + "_")
            or suggested_name.startswith(expected_name + "."))


def main():
    if os.environ.get("GITHUB_ACTIONS") != "true":
        raise SystemExit("Cloud-only evidence export requires GITHUB_ACTIONS=true")

    results = Path(os.environ["CI_RESULTS_DIR"])
    bundle = results / "LocalGemma-tests.xcresult"
    if not bundle.is_dir():
        raise RuntimeError(f"Missing XCTest result bundle: {bundle}")
    output = results / "layout-renders"
    attachments_dir = output / "attachments"
    output.mkdir(parents=True, exist_ok=True)
    xcresult_json(bundle, "summary", results / "xctest-summary.json")
    xcresult_json(bundle, "tests", results / "xctest-tests.json")
    # Public xcresulttool export syntax; preserve its original attachment index.
    subprocess.run([
        "xcrun", "xcresulttool", "export", "attachments",
        "--path", str(bundle), "--output-path", str(attachments_dir)
    ], check=True)
    index = json.loads((attachments_dir / "manifest.json").read_text(encoding="utf-8"))
    exported = []
    documents = []
    for entry in index:
        test_identifier = entry.get("testIdentifier", "")
        for attachment in entry.get("attachments", []):
            filename = attachment.get("exportedFileName", "")
            source = attachments_dir / filename
            if not filename or not source.resolve().is_relative_to(attachments_dir.resolve()):
                raise RuntimeError(f"Invalid attachment export path: {filename}")
            suggested_name = attachment.get("suggestedHumanReadableName", "")
            exported.append((suggested_name, source, test_identifier))
            for name in ["workbench-wide-provenance", "workbench-readiness-provenance"]:
                if attachment_name_matches(suggested_name, name):
                    document = json.loads(source.read_text(encoding="utf-8"))
                    documents.append((name, document, test_identifier))

    if {name for name, _document, _test in documents} != {
        "workbench-wide-provenance", "workbench-readiness-provenance"
    } or len(documents) != 2:
        raise RuntimeError("Expected exactly two production-render provenance attachments")

    captures = []
    for _name, document, exported_test in documents:
        test_identifier = document["testIdentifier"]
        test_method = test_identifier.split("/")[-1].removesuffix("()")
        if test_method not in exported_test:
            raise RuntimeError(f"Provenance test mismatch: {exported_test}")
        for capture in document["captures"]:
            name = capture["attachmentName"]
            matches = [item for item in exported if attachment_name_matches(item[0], name)]
            if len(matches) != 1:
                raise RuntimeError(f"Expected one exported image for {name}, got {len(matches)}")
            _suggested_name, source, image_test = matches[0]
            if image_test != exported_test:
                raise RuntimeError(f"Image/provenance test mismatch: {name}")
            data = source.read_bytes()
            if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
                raise RuntimeError(f"Expected PNG attachment: {source}")
            width, height = struct.unpack(">II", data[16:24])
            if not (0 < width <= 1600 and 0 < height <= 1600):
                raise RuntimeError(f"Unexpected render dimensions for {name}: {width}x{height}")
            if (abs(width - capture["imageWidth"]) > 1
                    or abs(height - capture["imageHeight"]) > 1):
                raise RuntimeError(f"PNG/provenance dimensions disagree: {name}")
            if capture["evidenceKind"] == "image-renderer-production-view":
                if (capture["referenceRootWidth"] != 1366
                        or capture["globalSidebarWidth"] != 288
                        or capture["workspacePaneWidth"] != 1078
                        or capture["referenceRootWidth"] != capture["globalSidebarWidth"]
                        + capture["workspacePaneWidth"]):
                    raise RuntimeError(f"Incorrect reference root/pane accounting: {name}")
                if capture["workspace"] == "chat" and (
                    capture["chatLayoutMode"] != "split"
                    or capture["chatSurfaceWidth"] < 620
                    or abs(capture["chatSessionSidebarWidth"]
                           + capture["chatSurfaceWidth"] - 1078) > 0.01
                ):
                    raise RuntimeError(f"Incorrect real chat pane allocation: {name}")
            captures.append({
                **capture,
                "file": source.relative_to(output).as_posix(),
                "pixelWidth": width,
                "pixelHeight": height,
                "sha256": hashlib.sha256(data).hexdigest(),
                "testIdentifier": test_identifier,
                "exportedTestIdentifier": image_test,
            })

    expected_wide = {
        f"workbench-wide-{theme}-{workspace}"
        for theme in ["light", "dark"]
        for workspace in ["chat", "models", "prompts", "settings"]
    }
    expected_readiness = {
        f"workbench-readiness-{theme}-{size}"
        for theme in ["light", "dark"]
        for size in ["large", "accessibility3"]
    }
    if (len(captures) != 12
            or {capture["attachmentName"] for capture in captures}
            != expected_wide | expected_readiness):
        raise RuntimeError("Incomplete or duplicate production-render capture matrix")
    manifest = {
        "commitSha": os.environ["GITHUB_SHA"],
        "runId": os.environ["GITHUB_RUN_ID"],
        "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"],
        "captureMethod": "SwiftUI.ImageRenderer in cloud XCTest",
        "notSimulatorScreenshot": True,
        "notMacGUI": True,
        "sourceResultBundle": "LocalGemma-tests.xcresult",
        "sourceAttachmentIndex": "attachments/manifest.json",
        "wideWorkspaceCaptureCount": 8,
        "readinessComponentCaptureCount": 4,
        "captureCount": len(captures),
        "captures": captures,
    }
    (output / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Verified {len(captures)} production-render images with PNG dimensions and SHA-256")


if __name__ == "__main__":
    main()
