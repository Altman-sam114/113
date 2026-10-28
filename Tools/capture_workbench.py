"""Capture production UI on GitHub-hosted simulators; never run locally."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import subprocess
import struct
import time
from workbench_capture_preflight import validate_capture_input

if os.environ.get("GITHUB_ACTIONS") != "true":
    raise SystemExit("Cloud-only UI capture requires GITHUB_ACTIONS=true")

def sim(*args, attempts=3):
    """Run simctl with bounded retries for transient CoreSimulator service errors."""
    command = ["xcrun", "simctl", *args]
    last_error = None
    for attempt in range(1, attempts + 1):
        result = subprocess.run(command, text=True, capture_output=True)
        if result.returncode == 0:
            return result.stdout.strip()
        last_error = result.stderr.strip() or result.stdout.strip() or "simctl failed"
        if attempt < attempts:
            time.sleep(2)
    raise RuntimeError(f"{' '.join(command)} failed after {attempts} attempts: {last_error}")

output = Path(os.environ["CI_RESULTS_DIR"]) / "visuals"
output.mkdir(parents=True, exist_ok=True)
app = Path(os.environ["DERIVED_DATA_PATH"]) / "Build/Products/Debug-iphonesimulator/LocalGemma.app"
try:
    build = (Path(os.environ["CI_RESULTS_DIR"]) / "outcomes/build").read_text().strip()
    validate_capture_input(app, build)
except (RuntimeError, OSError, ValueError, plistlib.InvalidFileException) as error:
    (output / "manifest.json").write_text(json.dumps({
        "commitSha": os.environ["GITHUB_SHA"], "runId": os.environ["GITHUB_RUN_ID"],
        "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"], "captures": [],
        "expectedCaptureCount": 16, "failures": [str(error)],
    }, indent=2))
    raise RuntimeError(f"Production capture input is invalid: {error}") from error
validator = Path(".build/validate-workbench-screenshot")
validator.parent.mkdir(parents=True, exist_ok=True)
subprocess.run([
    "xcrun", "swiftc", "Tools/ValidateWorkbenchScreenshot.swift", "-o", str(validator)
], check=True)
markers = {
    "chat": "ON-DEVICE WORKSPACE", "models": "MODEL LIBRARY",
    "prompts": "PROMPTS", "settings": "SETTINGS",
}
compact_markers = {
    "chat": "想聊点什么", "models": "导入模型文件",
    "prompts": "部署方案", "settings": "外观模式",
}
devices = json.loads(sim("list", "devices", "available", "--json"))["devices"]
available = [d for group in devices.values() for d in group]
records = []
failures = []
for family in ["iPhone", "iPad"]:
    device = next((d for d in available if d["name"].startswith(family)), None)
    if device is None:
        failures.append(f"No available {family} simulator")
        continue
    udid = device["udid"]
    try:
        if device["state"] != "Booted":
            sim("boot", udid)
        sim("bootstatus", udid, "-b")
        sim("install", udid, str(app))
        for theme in ["dark", "light"]:
            for workspace in ["chat", "models", "prompts", "settings"]:
                filename = f"{family}-{theme}-{workspace}.png"
                path = output / filename
                marker = (compact_markers if family == "iPhone" else markers)[workspace]
                record = dict(file=filename, device=device["name"], udid=udid,
                              theme=theme, workspace=workspace, captureAttempt=0,
                              requiredTextMarker=marker, pageContentValidated=False,
                              validationDiagnostics=[])
                try:
                    sim("launch", "--terminate-running-process", udid,
                        "com.localgemma.prototype", "--ui-workspace", workspace,
                        "-appThemeMode", theme)
                    # Preserve every page's evidence even when a preceding page fails OCR.
                    for capture_attempt in range(1, 6):
                        time.sleep(2)
                        sim("io", udid, "screenshot", str(path))
                        validation = subprocess.run(
                            [str(validator), str(path), marker], text=True, capture_output=True
                        )
                        record["captureAttempt"] = capture_attempt
                        diagnostic = dict(attempt=capture_attempt, exitCode=validation.returncode,
                                          stderr=validation.stderr.strip(), stdout=validation.stdout.strip())
                        record["validationDiagnostics"].append(diagnostic)
                        try:
                            content = json.loads(validation.stdout)
                        except json.JSONDecodeError:
                            content = {}
                        if isinstance(content, dict):
                            record["recognizedText"] = content.get("recognizedText", "")
                            record["recognitionPasses"] = content.get("recognitionPasses", [])
                        if (validation.returncode == 0 and isinstance(content, dict)
                                and content.get("requiredTextMarker") == marker
                                and content.get("pageContentValidated") is True):
                            record["pageContentValidated"] = True
                            break
                        print(f"Waiting for {filename}, attempt {capture_attempt}: "
                              f"stderr={validation.stderr.strip()} stdout={validation.stdout.strip()}", flush=True)
                    else:
                        raise RuntimeError(f"Target page content never appeared: {filename}")
                except (RuntimeError, OSError) as error:
                    record["error"] = str(error)
                    failures.append(f"{filename}: {error}")
                if path.is_file():
                    data = path.read_bytes()
                    if (len(data) >= 24 and data[:8] == b"\x89PNG\r\n\x1a\n"
                            and data[12:16] == b"IHDR"):
                        width, height = struct.unpack(">II", data[16:24])
                        record.update(pixelWidth=width, pixelHeight=height,
                                      sha256=hashlib.sha256(data).hexdigest())
                        if width == 0 or height == 0:
                            record["pageContentValidated"] = False
                            failures.append(f"Empty PNG dimensions: {filename}")
                    else:
                        record["pageContentValidated"] = False
                        failures.append(f"Invalid PNG: {filename}")
                else:
                    record["pageContentValidated"] = False
                    failures.append(f"Missing PNG: {filename}")
                records.append(record)
    except (RuntimeError, OSError) as error:
        failures.append(f"{family} setup: {error}")
    finally:
        try:
            sim("shutdown", udid)
        except RuntimeError as error:
            failures.append(f"{family} shutdown: {error}")
(output / "manifest.json").write_text(json.dumps({
    "commitSha": os.environ["GITHUB_SHA"], "runId": os.environ["GITHUB_RUN_ID"],
    "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"], "captures": records,
    "expectedCaptureCount": 16, "failures": failures,
}, indent=2))
if failures or len(records) != 16 or not all(record["pageContentValidated"] for record in records):
    raise RuntimeError("Incomplete production screenshot evidence: " + "; ".join(failures)
                       + f"; validated {sum(record['pageContentValidated'] for record in records)}/16")
