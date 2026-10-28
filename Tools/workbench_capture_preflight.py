"""Static capture-input checks; never launch a compiler, app, or device."""
from pathlib import Path
import plistlib


def validate_capture_input(app: Path, build_outcome: str):
    if build_outcome != "success":
        raise RuntimeError(f"Production capture requires a successful build, got {build_outcome!r}")
    info_path = app / "Info.plist"
    if not info_path.is_file():
        raise RuntimeError(f"Missing built app Info.plist: {info_path}")
    info = plistlib.loads(info_path.read_bytes())
    name = info.get("CFBundleExecutable")
    if (not isinstance(name, str) or not name or name in {".", ".."}
            or "/" in name or "\\" in name or "\0" in name):
        raise RuntimeError("Built app has an invalid executable name")
    executable = app / name
    if not executable.is_file() or executable.stat().st_size == 0:
        raise RuntimeError(f"Missing or empty built app executable: {executable}")
