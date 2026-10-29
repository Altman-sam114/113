"""Validate release resources without claiming signing or App Store approval."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import struct
import zlib


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_PRIVACY = {
    "NSPrivacyTracking": False,
    "NSPrivacyTrackingDomains": [],
    "NSPrivacyCollectedDataTypes": [],
    "NSPrivacyAccessedAPITypes": [{
        "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
        "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
    }],
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def fingerprint(path):
    data = path.read_bytes()
    require(bool(data), f"Empty resource: {path.name}")
    return {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def png_size(path, opaque=False):
    data = path.read_bytes()
    require(data[:8] == b"\x89PNG\r\n\x1a\n", f"Not a PNG: {path.name}")
    require(len(data) >= 33, "Truncated PNG header")
    header_offset = data.find(b"IHDR")
    require(12 <= header_offset <= 40, "Invalid PNG header position")
    width, height, depth, color = struct.unpack(">IIBB", data[header_offset + 4:header_offset + 14])
    require(width > 0 and height > 0, "Invalid PNG header")
    if opaque:
        require(depth == 8 and color == 2, "App icon must be opaque 8-bit RGB")
    offset, ended, cgbi, payload = 8, False, False, bytearray()
    while offset + 12 <= len(data):
        size = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        chunk = data[offset + 4:offset + 8 + size]
        require(offset + 12 + size <= len(data), "Truncated PNG")
        crc = struct.unpack(">I", data[offset + 8 + size:offset + 12 + size])[0]
        require(zlib.crc32(chunk) & 0xffffffff == crc, "PNG checksum mismatch")
        if kind == b"IDAT":
            payload.extend(data[offset + 8:offset + 8 + size])
        if kind == b"CgBI":
            cgbi = True
        offset += 12 + size
        if kind == b"IEND":
            ended = True
            break
    require(ended and offset == len(data), "PNG missing end marker or has trailing content")
    require(bool(payload) and bool(zlib.decompress(payload, -15 if cgbi else zlib.MAX_WBITS)),
            "PNG has no image data")
    return width, height


def validate_privacy(path):
    document = plistlib.loads(path.read_bytes())
    require(document == EXPECTED_PRIVACY, "Privacy manifest differs from the audited local-only API contract")
    return fingerprint(path)


def validate_app_resource_registration(project):
    def objects(section):
        begin, end = f"/* Begin {section} section */", f"/* End {section} section */"
        require(project.count(begin) == project.count(end) == 1, f"Missing {section} section")
        text = project.split(begin, 1)[1].split(end, 1)[0]
        return dict(re.findall(r"([A-F0-9]{24})\s*/\*[^*]*\*/\s*=\s*\{(.*?)\};", text, re.S))

    def references(body, key):
        match = re.search(rf"\b{key}\s*=\s*\((.*?)\);", body, re.S)
        require(match is not None, f"Missing {key} references")
        return re.findall(r"\b[A-F0-9]{24}\b", match[1])

    targets = objects("PBXNativeTarget")
    apps = [body for body in targets.values()
            if re.search(r'\bname\s*=\s*"?LocalGemma"?\s*;', body)
            and 'productType = "com.apple.product-type.application";' in body]
    require(len(apps) == 1, "Expected one LocalGemma app target")
    phases = objects("PBXResourcesBuildPhase")
    app_phases = [phases[identifier] for identifier in references(apps[0], "buildPhases") if identifier in phases]
    require(len(app_phases) == 1, "App must reference exactly one resources phase")
    build_files, file_references = objects("PBXBuildFile"), objects("PBXFileReference")
    paths = set()
    for identifier in references(app_phases[0], "files"):
        require(identifier in build_files, "App resource build file is missing")
        file_ref = re.search(r"\bfileRef\s*=\s*([A-F0-9]{24})", build_files[identifier])
        require(file_ref is not None and file_ref[1] in file_references, "App resource file reference is missing")
        path = re.search(r'\bpath\s*=\s*"?([^;"\n]+)"?\s*;', file_references[file_ref[1]])
        require(path is not None, "App resource path is missing")
        paths.add(path[1].strip())
    require({"Assets.xcassets", "PrivacyInfo.xcprivacy"} <= paths,
            "App resources phase must include the asset catalog and privacy manifest")


def validate_source(root):
    icons = root / "LocalGemma/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((icons / "Contents.json").read_text())
    expected = set()
    for idiom, sizes in [
        ("iphone", [(20, [2, 3]), (29, [2, 3]), (40, [2, 3]), (60, [2, 3])]),
        ("ipad", [(20, [1, 2]), (29, [1, 2]), (40, [1, 2]), (76, [1, 2]), (83.5, [2])]),
        ("mac", [(16, [1, 2]), (32, [1, 2]), (128, [1, 2]), (256, [1, 2]), (512, [1, 2])]),
        ("ios-marketing", [(1024, [1])]),
    ]:
        expected.update((idiom, f"{size}x{size}", f"{scale}x") for size, scales in sizes for scale in scales)
    slots = contents["images"]
    actual = [(slot["idiom"], slot["size"], slot["scale"]) for slot in slots]
    require(len(actual) == len(expected) and set(actual) == expected, "Missing or duplicate icon slots")
    resources = {}
    for slot in slots:
        filename = slot["filename"]
        require(Path(filename).name == filename and filename.endswith(".png"), "Invalid icon path")
        expected_pixels = int(float(slot["size"].split("x")[0]) * float(slot["scale"][:-1]))
        require(png_size(icons / filename, opaque=True) == (expected_pixels, expected_pixels),
                f"Wrong icon dimensions: {filename}")
        resources[filename] = fingerprint(icons / filename)
    privacy = validate_privacy(root / "LocalGemma/PrivacyInfo.xcprivacy")
    project = (root / "LocalGemma.xcodeproj/project.pbxproj").read_text()
    require(project.count("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;") == 2,
            "Both app build configurations must select AppIcon")
    validate_app_resource_registration(project)
    return {"iconSlotCount": len(slots), "icons": resources, "privacyManifest": privacy}


def validate_bundle(app):
    require(app.is_dir() and app.suffix == ".app", "Expected an existing .app directory")
    info = plistlib.loads((app / "Info.plist").read_bytes())
    require(info.get("CFBundleIdentifier") == "com.localgemma.prototype", "Unexpected bundle identifier")
    require(info.get("CFBundleSupportedPlatforms") == ["iPhoneOS"], "Expected a device build, not Simulator")
    require(info.get("DTPlatformName") == "iphoneos", "Missing iPhoneOS build provenance")
    require(info.get("MinimumOSVersion") == "17.0", "Unexpected minimum OS")
    require(set(info.get("UIDeviceFamily", [])) == {1, 2}, "Phone and tablet families must remain supported")
    for key in ["CFBundleShortVersionString", "CFBundleVersion", "NSPhotoLibraryUsageDescription"]:
        require(isinstance(info.get(key), str) and bool(info[key].strip()), f"Missing {key}")
    for key in ["CFBundleIcons", "CFBundleIcons~ipad"]:
        icon = info.get(key, {}).get("CFBundlePrimaryIcon", {})
        require(icon.get("CFBundleIconName") == "AppIcon" and bool(icon.get("CFBundleIconFiles")),
                f"Missing compiled icon declaration: {key}")
    executable_name = info.get("CFBundleExecutable", "")
    require(bool(executable_name) and Path(executable_name).name == executable_name, "Invalid executable path")
    executable = app / executable_name
    header = executable.read_bytes()[:32]
    require(len(header) == 32, "Missing Mach-O executable")
    magic, cpu, _, filetype = struct.unpack("<IIII", header[:16])
    require(magic == 0xfeedfacf and cpu == 0x0100000c and filetype == 2,
            "Release executable must be a 64-bit arm64 Mach-O executable")
    validate_privacy(app / "PrivacyInfo.xcprivacy")
    files = [app / "Info.plist", app / "Assets.car", app / "PrivacyInfo.xcprivacy", executable]
    icon_files = sorted(app.glob("AppIcon*.png"))
    require(bool(icon_files), "Compiled app icon PNGs are missing")
    for path in icon_files:
        png_size(path)
    files.extend(icon_files)
    return {
        "bundleIdentifier": info["CFBundleIdentifier"], "version": info["CFBundleShortVersionString"],
        "build": info["CFBundleVersion"], "minimumOS": info["MinimumOSVersion"],
        "platform": "iPhoneOS", "architecture": "arm64", "signingVerified": False,
        "files": {path.name: fingerprint(path) for path in files},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-only", action="store_true")
    parser.add_argument("--app", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    require(args.source_only != bool(args.app), "Select exactly one of --source-only or --app")
    report = {"source": validate_source(ROOT)}
    if args.app:
        require(os.environ.get("GITHUB_ACTIONS") == "true", "Built-app validation is cloud-only")
        report["bundle"] = validate_bundle(args.app)
        report.update(commitSha=os.environ["GITHUB_SHA"], runId=os.environ["GITHUB_RUN_ID"],
                      runAttempt=os.environ["GITHUB_RUN_ATTEMPT"], branch=os.environ["GITHUB_REF_NAME"])
    report["status"] = "success"
    serialized = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(serialized)
    print(serialized)


if __name__ == "__main__":
    main()
