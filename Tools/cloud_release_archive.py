"""Produce a verified unsigned iOS xcarchive only on GitHub-hosted macOS."""
import argparse
from contextlib import ExitStack
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import stat
import subprocess
import zipfile

from verify_release_bundle import require, validate_bundle, validate_source


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_NAME = "LocalGemma.xcarchive"
CLAIMS = {"signingVerified": False, "appStoreReady": False, "runtimeVerified": False}
VERSION = r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)(?:\.(?:0|[1-9][0-9]*))?"


def validate_inputs(expected_sha, version, build_number, baseline_version=None, baseline_build=None):
    require(isinstance(expected_sha, str) and re.fullmatch(r"[0-9a-f]{40}", expected_sha),
            "expected_sha must be an exact lowercase 40-character commit SHA")
    require(isinstance(version, str) and len(version) <= 18 and re.fullmatch(VERSION, version),
            "Marketing version must contain two or three canonical integer components")
    require(isinstance(build_number, str) and re.fullmatch(r"[1-9][0-9]{0,9}", build_number)
            and int(build_number) <= 2147483647, "Build number must be a positive canonical 32-bit integer")
    if baseline_version is not None:
        require(isinstance(baseline_version, str) and re.fullmatch(VERSION, baseline_version),
                "Invalid checked-in marketing-version baseline")
        def components(value):
            parts = tuple(map(int, value.split(".")))
            return parts + (0,) * (3 - len(parts))
        require(components(version) >= components(baseline_version), "Marketing version cannot decrease")
    if baseline_build is not None:
        require(isinstance(baseline_build, str) and re.fullmatch(r"[1-9][0-9]*", baseline_build),
                "Invalid checked-in build-number baseline")
        require(int(build_number) > int(baseline_build), "Build number must increase over the checked-in project")
    return {"expectedSha": expected_sha, "marketingVersion": version, "buildNumber": build_number}


def safe_path(root, relative):
    require(isinstance(relative, str) and relative and "\\" not in relative and "\0" not in relative,
            "Invalid artifact-relative path")
    path = PurePosixPath(relative)
    require(not path.is_absolute() and all(part not in {"", ".", ".."} for part in relative.split("/")),
            "Artifact paths must remain inside the result directory")
    target = root / relative
    require(target.resolve().is_relative_to(root.resolve()), "Artifact path escaped its result directory")
    current = root
    require(not current.is_symlink(), "Artifact evidence root may not be a symbolic link")
    for part in path.parts:
        current = current / part
        require(not current.is_symlink(), "Artifact evidence may not use symbolic links")
    return target


def fingerprint(path, allow_empty=False):
    require(path.is_file() and not path.is_symlink(), "Evidence must be a regular file")
    hasher, size = hashlib.sha256(), 0
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
            size += len(chunk)
    require(size > 0 or allow_empty, f"Empty evidence file: {path.name}")
    return {"bytes": size, "sha256": hasher.hexdigest()}


def archive_files(archive):
    require(archive.is_dir() and archive.name == ARCHIVE_NAME and not archive.is_symlink(),
            "Expected the actual LocalGemma.xcarchive directory")
    records = {}
    for path in sorted(archive.rglob("*")):
        require(not path.is_symlink(), "Archive may not contain symbolic links")
        require(path.is_file() or path.is_dir(), "Archive contains a non-regular entry")
        if path.is_file():
            relative = path.relative_to(archive).as_posix()
            safe_path(archive, relative)
            records[relative] = {**fingerprint(path, allow_empty=True), "mode": stat.S_IMODE(path.stat().st_mode)}
    require(bool(records), "Archive has no files")
    return records


def validate_archive(archive, version, build_number):
    files = archive_files(archive)
    info = plistlib.loads((archive / "Info.plist").read_bytes())
    require(isinstance(info, dict) and info.get("ArchiveVersion") == 2 and info.get("SchemeName") == "LocalGemma",
            "Not a LocalGemma Xcode archive")
    properties = info.get("ApplicationProperties")
    require(isinstance(properties, dict), "Archive lacks ApplicationProperties")
    application = properties.get("ApplicationPath")
    app = safe_path(archive / "Products", application)
    require(PurePosixPath(application).parts == ("Applications", "LocalGemma.app"),
            "Archive must contain the expected device application")
    require(properties.get("CFBundleIdentifier") == "com.localgemma.prototype", "Archive bundle identifier mismatch")
    require(properties.get("CFBundleShortVersionString") == version
            and str(properties.get("CFBundleVersion")) == build_number, "Archive version/build mismatch")
    require(properties.get("Architectures") == ["arm64"], "Archive must describe the arm64 device executable")
    bundle = validate_bundle(app)
    require(bundle["version"] == version and bundle["build"] == build_number, "App version/build mismatch")
    dsym = archive / "dSYMs/LocalGemma.app.dSYM"
    dsym_info = plistlib.loads((dsym / "Contents/Info.plist").read_bytes())
    require(dsym_info.get("CFBundlePackageType") == "dSYM", "Archive lacks a valid dSYM bundle")
    dwarf = dsym / "Contents/Resources/DWARF/LocalGemma"
    fingerprint(dwarf)
    return {"applicationPath": f"{ARCHIVE_NAME}/Products/{application}",
            "dSYMPath": f"{ARCHIVE_NAME}/dSYMs/LocalGemma.app.dSYM", "bundle": bundle, "files": files}


def validate_uuid_pair(app_output, dsym_output):
    def arm64_uuid(output):
        matches = re.findall(r"^UUID: ([0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}) \(arm64\) .+$",
                             output, re.M)
        require(len(matches) == 1, "Expected one actual arm64 Mach-O UUID")
        return matches[0].upper()
    app, dsym = arm64_uuid(app_output), arm64_uuid(dsym_output)
    require(app == dsym, "dSYM UUID does not match the archived executable")
    return {"architecture": "arm64", "executableUUID": app, "dSYMUUID": dsym}


def package_archive(archive, destination):
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for relative in archive_files(archive):
            bundle.write(archive / relative, f"{ARCHIVE_NAME}/{relative}")
    return fingerprint(destination)


def validate_delivery(root, manifest):
    require(manifest.get("schemaVersion") == 1 and manifest.get("status") == "success"
            and manifest.get("kind") == "unsigned-ios-xcarchive", "Not a successful unsigned archive delivery")
    require(all(manifest.get(key) is False for key in CLAIMS), "Unsigned archives cannot claim release/runtime approval")
    inputs = manifest["inputs"]
    validate_inputs(inputs["expectedSha"], inputs["marketingVersion"], inputs["buildNumber"])
    require(manifest.get("commitSha") == inputs["expectedSha"] and manifest.get("branch") == "main",
            "Delivery identity does not match the requested main commit")
    require(all(isinstance(manifest.get(key), str) and re.fullmatch(r"[1-9][0-9]*", manifest[key])
                for key in ["runId", "runAttempt"]), "Delivery lacks the exact run identity")
    require(manifest.get("outcomes") == {"source": "success", "archive": "success", "validation": "success"},
            "Required archive stages did not all pass")
    archive = safe_path(root, ARCHIVE_NAME)
    actual = validate_archive(archive, inputs["marketingVersion"], inputs["buildNumber"])
    require(manifest.get("archive") == actual, "Archive metadata or file evidence changed")
    evidence = manifest.get("uuidEvidence")
    require(isinstance(evidence, dict), "Missing original dSYM evidence")
    outputs = []
    for key in ["executable", "dSYM"]:
        record = evidence[key]
        path = safe_path(root, record["path"])
        require(fingerprint(path) == record["fingerprint"], "UUID log evidence changed")
        outputs.append(path.read_text(encoding="utf-8"))
    require(validate_uuid_pair(*outputs) == manifest.get("symbols"), "Symbol evidence mismatch")
    packaged = manifest["package"]
    expected_name = f"LocalGemma-unsigned-{inputs['marketingVersion']}-{inputs['buildNumber']}-{manifest['commitSha'][:7]}.xcarchive.zip"
    require(packaged.get("path") == expected_name, "Unexpected unsigned archive package name")
    path = safe_path(root, packaged["path"])
    require(fingerprint(path) == packaged.get("fingerprint"), "Archive ZIP digest mismatch")
    with zipfile.ZipFile(path) as bundle:
        names = bundle.namelist()
        expected = {f"{ARCHIVE_NAME}/{relative}" for relative in actual["files"]}
        require(len(names) == len(set(names)) and set(names) == expected, "ZIP archive entries differ from the verified xcarchive")
        for name in names:
            safe_path(root, name)
            entry = bundle.getinfo(name)
            original = actual["files"][name[len(ARCHIVE_NAME) + 1:]]
            require(not entry.is_dir() and stat.S_ISREG(entry.external_attr >> 16),
                    "ZIP evidence must contain regular files, never symbolic links")
            require(stat.S_IMODE(entry.external_attr >> 16) == original["mode"], "ZIP file permissions changed")
            hasher, size = hashlib.sha256(), 0
            with bundle.open(name) as stream:
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    hasher.update(chunk)
                    size += len(chunk)
            require(size == original["bytes"] and hasher.hexdigest() == original["sha256"],
                    "ZIP content does not match the validated archive")
        require(bundle.testzip() is None, "Archive ZIP CRC check failed")


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def write_failure_report(root, manifest, stage, error):
    report = {**manifest, **CLAIMS, "status": "failure", "failureStage": stage,
              "error": {"type": type(error).__name__, "message": str(error)}}
    report["outcomes"] = {**manifest.get("outcomes", {}), stage: "failure"}
    write_json(root / "failure.json", report)
    write_json(root / "manifest.json", report)
    return report


def require_hosted_macos(environment):
    require(environment.get("GITHUB_ACTIONS") == "true"
            and environment.get("RUNNER_ENVIRONMENT") == "github-hosted"
            and environment.get("RUNNER_OS") == "macOS",
            "Archive execution requires a real GitHub-hosted macOS runner; local execution is forbidden")
    require(environment.get("GITHUB_EVENT_NAME") == "workflow_dispatch"
            and environment.get("GITHUB_REF") == "refs/heads/main"
            and environment.get("GITHUB_REPOSITORY") == "Altman-sam114/113",
            "Only a manual dispatch on this repository's main branch may archive")


def command(arguments, log, separate_stderr=False):
    print("+ " + " ".join(map(str, arguments)), flush=True)
    with ExitStack() as stack:
        stream = stack.enter_context(log.open("w", encoding="utf-8"))
        stderr = stack.enter_context(log.with_name(log.stem + "-stderr.log").open("w", encoding="utf-8")) if separate_stderr else subprocess.STDOUT
        completed = subprocess.run(list(map(str, arguments)), cwd=ROOT, stdout=stream, stderr=stderr,
                                   text=True, timeout=1800, check=False)
    output = log.read_text(encoding="utf-8", errors="replace")
    if completed.returncode:
        print(output[-16000:], flush=True)
        raise subprocess.CalledProcessError(completed.returncode, arguments)
    return output


def main():
    require_hosted_macos(os.environ)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expected-sha", default=os.environ.get("EXPECTED_SHA", ""))
    parser.add_argument("--marketing-version", default=os.environ.get("MARKETING_VERSION", ""))
    parser.add_argument("--build-number", default=os.environ.get("BUILD_NUMBER", ""))
    args = parser.parse_args()
    result = ROOT / "release-archive-results"
    require(not result.exists(), "Archive results must start in a fresh checkout")
    result.mkdir()
    manifest = {"schemaVersion": 1, "kind": "unsigned-ios-xcarchive", "status": "running", **CLAIMS,
                "commitSha": os.environ.get("GITHUB_SHA", ""), "branch": os.environ.get("GITHUB_REF_NAME", ""),
                "runId": os.environ.get("GITHUB_RUN_ID", ""), "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT", ""),
                "workflow": "Unsigned Release Archive", "outcomes": {},
                "buildIncrementScope": "checked-in-project-only; App Store history is not verified"}
    stage = "inputs"
    try:
        manifest["inputs"] = validate_inputs(args.expected_sha, args.marketing_version, args.build_number)
        sha = command(["git", "rev-parse", "HEAD"], result / "git-head.log").strip()
        require(sha == manifest["commitSha"] == args.expected_sha, "Requested, event and checked-out SHAs must match exactly")
        command(["git", "diff", "--exit-code", "HEAD", "--"], result / "tracked-source-diff.log")
        write_json(result / "manifest.json", manifest)
        stage = "source"
        manifest["source"] = validate_source(ROOT)
        manifest["outcomes"][stage] = "success"
        command(["xcodebuild", "-version"], result / "xcode-version.log")
        base = ["xcodebuild", "-project", "LocalGemma.xcodeproj", "-scheme", "LocalGemma", "-configuration", "Release",
                "-sdk", "iphoneos", "-destination", "generic/platform=iOS", "CODE_SIGNING_ALLOWED=NO"]
        settings = json.loads(command(base + ["-showBuildSettings", "-json"], result / "build-settings.json", separate_stderr=True))
        apps = [entry["buildSettings"] for entry in settings if entry.get("target") == "LocalGemma"]
        require(len(apps) == 1 and apps[0].get("PRODUCT_BUNDLE_IDENTIFIER") == "com.localgemma.prototype",
                "Expected the existing LocalGemma application target")
        baseline = {"marketingVersion": apps[0]["MARKETING_VERSION"], "buildNumber": apps[0]["CURRENT_PROJECT_VERSION"]}
        validate_inputs(args.expected_sha, args.marketing_version, args.build_number,
                        baseline["marketingVersion"], baseline["buildNumber"])
        manifest["projectBaseline"] = baseline
        stage = "archive"
        write_json(result / "manifest.json", manifest)
        command(base + ["-archivePath", result / ARCHIVE_NAME, "-derivedDataPath", ROOT / ".derivedData-release-archive",
                        "-resultBundlePath", result / "archive.xcresult", "ARCHS=arm64", "ONLY_ACTIVE_ARCH=NO",
                        "CODE_SIGNING_REQUIRED=NO", "CODE_SIGN_IDENTITY=", "DEBUG_INFORMATION_FORMAT=dwarf-with-dsym",
                        f"MARKETING_VERSION={args.marketing_version}", f"CURRENT_PROJECT_VERSION={args.build_number}", "archive"],
                result / "archive.log")
        manifest["outcomes"][stage] = "success"
        stage = "validation"
        manifest["archive"] = validate_archive(result / ARCHIVE_NAME, args.marketing_version, args.build_number)
        app = safe_path(result, manifest["archive"]["applicationPath"])
        info = plistlib.loads((app / "Info.plist").read_bytes())
        executable = app / info["CFBundleExecutable"]
        dsym = safe_path(result, manifest["archive"]["dSYMPath"])
        app_log, dsym_log = result / "executable-uuid.log", result / "dsym-uuid.log"
        app_uuid = command(["xcrun", "dwarfdump", "--uuid", executable], app_log)
        dsym_uuid = command(["xcrun", "dwarfdump", "--uuid", dsym], dsym_log)
        manifest["symbols"] = validate_uuid_pair(app_uuid, dsym_uuid)
        manifest["uuidEvidence"] = {
            "executable": {"path": app_log.name, "fingerprint": fingerprint(app_log)},
            "dSYM": {"path": dsym_log.name, "fingerprint": fingerprint(dsym_log)}}
        name = f"LocalGemma-unsigned-{args.marketing_version}-{args.build_number}-{sha[:7]}.xcarchive.zip"
        manifest["package"] = {"path": name, "fingerprint": package_archive(result / ARCHIVE_NAME, result / name)}
        manifest["outcomes"][stage] = "success"
        manifest["status"] = "success"
        validate_delivery(result, manifest)
        write_json(result / "manifest.json", manifest)
        print(f"Verified unsigned archive: {name}; signing, App Store readiness and real runtime remain unverified", flush=True)
        return 0
    except Exception as error:
        write_failure_report(result, manifest, stage, error)
        print(f"Unsigned archive failed at {stage}: {error}", flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
