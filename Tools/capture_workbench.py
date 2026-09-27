"""Capture production UI on GitHub-hosted simulators; never run locally."""
import json
import os
from pathlib import Path
import subprocess
import time

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
devices = json.loads(sim("list", "devices", "available", "--json"))["devices"]
available = [d for group in devices.values() for d in group]
records = []
for family in ["iPhone", "iPad"]:
    device = next(d for d in available if d["name"].startswith(family))
    udid = device["udid"]
    if device["state"] != "Booted":
        sim("boot", udid)
    sim("bootstatus", udid, "-b")
    sim("install", udid, str(app))
    for theme in ["dark", "light"]:
        for workspace in ["chat", "models", "prompts", "settings"]:
            sim("launch", "--terminate-running-process", udid,
                "com.localgemma.prototype", "--ui-workspace", workspace,
                "-appThemeMode", theme)
            time.sleep(3)
            filename = f"{family}-{theme}-{workspace}.png"
            sim("io", udid, "screenshot", str(output / filename))
            records.append(dict(file=filename, device=device["name"], udid=udid,
                                theme=theme, workspace=workspace))
    sim("shutdown", udid)
(output / "manifest.json").write_text(json.dumps({
    "commitSha": os.environ["GITHUB_SHA"], "runId": os.environ["GITHUB_RUN_ID"],
    "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"], "captures": records
}, indent=2))
