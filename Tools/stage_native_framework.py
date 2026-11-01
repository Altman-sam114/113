"""Stage an immutable dependency cache into Apple's versioned Catalyst layout."""
import json
import os
from pathlib import Path
import plistlib
import shutil
import stat
import subprocess
import zipfile

import prepare_llama_dependency as dependency

ROOT = Path(__file__).resolve().parents[1]
CATALYST_LINKS = {
    "Versions/Current": "A",
    "Headers": "Versions/Current/Headers",
    "Modules": "Versions/Current/Modules",
    "Resources": "Versions/Current/Resources",
    "llama": "Versions/Current/llama",
    "LICENSE": "Versions/Current/Resources/LICENSE",
    "THIRD_PARTY_NOTICES.txt": "Versions/Current/Resources/THIRD_PARTY_NOTICES.txt",
}


def version_catalyst_framework(framework):
    expected = {"Headers", "Modules", "Info.plist", "llama", "LICENSE", "THIRD_PARTY_NOTICES.txt"}
    dependency.require({p.name for p in framework.iterdir()} == expected,
                       "Unexpected shallow Catalyst framework contents")
    version = framework / "Versions/A"
    (version / "Resources").mkdir(parents=True)
    for name in ["Headers", "Modules", "llama"]:
        (framework / name).rename(version / name)
    for name in ["Info.plist", "LICENSE", "THIRD_PARTY_NOTICES.txt"]:
        (framework / name).rename(version / "Resources" / name)
    for name, target in CATALYST_LINKS.items():
        (framework / name).symlink_to(target, target_is_directory=name in {"Versions/Current", "Headers", "Modules", "Resources"})


def app_framework_fingerprints(root):
    metadata = plistlib.loads(dependency.safe_path(root, "Info.plist").read_bytes())
    selected = dependency.validate_metadata(metadata, set(dependency.PLATFORMS))
    prefix = selected["maccatalyst"]["LibraryIdentifier"] + "/llama.framework/"
    expected_links = {prefix + name: target for name, target in CATALYST_LINKS.items()}
    version = root / prefix / "Versions/A"
    dependency.require(version.is_dir() and not version.is_symlink(), "Missing physical Catalyst framework version")
    records, links = {}, {}
    # Never traverse directory aliases. Only the exact locally constructed
    # framework aliases may resolve, and every target must remain inside A.
    for directory, dirs, files in os.walk(root, followlinks=False):
        for name in sorted(dirs + files):
            path = Path(directory) / name
            relative = path.relative_to(root).as_posix()
            if path.is_symlink():
                target = os.readlink(path)
                dependency.require(expected_links.get(relative) == target
                                   and path.resolve(strict=True).is_relative_to(version.resolve()),
                                   "Unexpected or escaping Catalyst framework alias")
                links[relative] = target
                records[relative] = {"symlink": target}
            else:
                dependency.safe_path(root, relative)
                dependency.require(path.is_file() or path.is_dir(), "Non-regular app framework entry")
                if path.is_file():
                    records[relative] = dependency.fingerprint(path)
    dependency.require(links == expected_links, "Missing exact versioned Catalyst framework aliases")
    dependency.require(not (root / prefix / "Info.plist").exists(), "Catalyst must not retain shallow Info.plist")
    dependency.require((version / "Resources/Info.plist").is_file(), "Missing versioned Catalyst Info.plist")
    dependency.validate_frameworks(root)
    return records


def stage_framework(source, destination):
    dependency.require(not destination.exists() and not destination.is_symlink(), "App framework staging requires a new path")
    original = dependency.tree_fingerprints(source)
    selected = dependency.validate_frameworks(source)
    shutil.copytree(source, destination)
    identifier = selected["maccatalyst"]["LibraryIdentifier"]
    version_catalyst_framework(destination / identifier / "llama.framework")
    metadata = plistlib.loads((destination / "Info.plist").read_bytes())
    for record in metadata["AvailableLibraries"]:
        if record["LibraryIdentifier"] == identifier:
            record["BinaryPath"] = "llama.framework/Versions/A/llama"
    (destination / "Info.plist").write_bytes(plistlib.dumps(metadata))
    records = app_framework_fingerprints(destination)
    dependency.require(dependency.tree_fingerprints(source) == original, "Immutable dependency cache changed during staging")
    # Moving bundles must never change native code or its matching dSYM bytes.
    for record in selected.values():
        path = record["LibraryIdentifier"] + "/llama.framework/llama"
        dependency.require((source / path).read_bytes() == (destination / path).read_bytes(),
                           "Framework layout staging changed native code")
    return records


def package_framework(framework, path):
    app_framework_fingerprints(framework)
    with zipfile.ZipFile(path, "x", compression=zipfile.ZIP_DEFLATED) as output:
        for directory, dirs, files in os.walk(framework, followlinks=False):
            for name in sorted(dirs + files):
                source = Path(directory) / name
                relative = "llama.xcframework/" + source.relative_to(framework).as_posix()
                if source.is_symlink():
                    entry = zipfile.ZipInfo(relative)
                    entry.create_system = 3
                    entry.external_attr = (stat.S_IFLNK | 0o777) << 16
                    output.writestr(entry, os.readlink(source))
                elif source.is_file():
                    output.write(source, relative)


def main():
    dependency.require_hosted_macos(os.environ)
    root = ROOT / ".runtime"
    xcode = subprocess.check_output(["xcodebuild", "-version"], text=True).strip()
    sdk = subprocess.check_output(["xcrun", "--sdk", "macosx", "--show-sdk-version"], text=True).strip()
    source_manifest = dependency.validate_cache(root, dependency.input_identity({"xcode": xcode, "macosSdkVersion": sdk}))
    destination = dependency.safe_path(root, "app-bundle/llama.xcframework")
    records = stage_framework(root / "llama.xcframework", destination)
    manifest = {"schemaVersion": 1, "status": "success", "layout": "versioned-catalyst-v1",
                "commitSha": os.environ["GITHUB_SHA"], "runId": os.environ["GITHUB_RUN_ID"],
                "runAttempt": os.environ["GITHUB_RUN_ATTEMPT"],
                "sourceManifest": dependency.fingerprint(root / "manifest.json"),
                "sourceInputs": source_manifest["inputs"], "nativeCodeChanged": False,
                "inferenceVerified": False, "files": records}
    (destination.parent / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    package_framework(destination, destination.parent / "llama.xcframework.zip")
    print("Staged versioned Catalyst framework; all five native slices and immutable cache verified")


if __name__ == "__main__":
    main()
