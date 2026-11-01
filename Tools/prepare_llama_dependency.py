"""Prepare a pinned llama XCFramework on GitHub-hosted macOS; never fetch models."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import stat
import struct
import subprocess
import tarfile
import tempfile
import urllib.parse
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parents[1]
TAG = "b12032"
COMMIT = "dde879bc4f954b809892fd0d660515f42536394a"
SOURCE_URL = f"https://codeload.github.com/ggml-org/llama.cpp/tar.gz/{COMMIT}"
SOURCE_SHA256 = "83f099b6bbb531ca72d22cdd76d86641438469a214fd49a38f026c6a868598ed"
BINARY_URL = f"https://github.com/ggml-org/llama.cpp/releases/download/{TAG}/llama-{TAG}-xcframework.zip"
BINARY_SHA256 = "ac8244300899cb619d3725a95caf101e853050d7ddb016dc343b01816545ad6e"
SOURCE_PREFIX = f"llama.cpp-{COMMIT}"
BINARY_PREFIX = "build-apple/llama.xcframework"
MAX_DOWNLOAD = 128 * 1024 * 1024
MAX_EXTRACTED = 768 * 1024 * 1024
MAX_ENTRIES = 20000
DOWNLOAD_HOSTS = {"github.com", "codeload.github.com", "release-assets.githubusercontent.com", "objects.githubusercontent.com"}
PLATFORMS = {"device": (2, {"arm64"}), "simulator": (7, {"arm64", "x86_64"}),
             "maccatalyst": (6, {"arm64", "x86_64"})}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def require_hosted_macos(environment):
    require(environment.get("GITHUB_ACTIONS") == "true"
            and environment.get("RUNNER_ENVIRONMENT") == "github-hosted"
            and environment.get("RUNNER_OS") == "macOS"
            and environment.get("GITHUB_REPOSITORY") == "Altman-sam114/113",
            "Native preparation is permitted only on this repository's GitHub-hosted macOS runner")


def safe_path(root, relative):
    require(isinstance(relative, str) and relative and "\\" not in relative and "\0" not in relative,
            "Invalid dependency-relative path")
    parts = relative.split("/")
    require(not PurePosixPath(relative).is_absolute() and all(p not in {"", ".", ".."} for p in parts),
            "Dependency path traversal is forbidden")
    root = Path(root)
    require(not root.is_symlink(), "Dependency root cannot be a symbolic link")
    current = root
    for part in parts:
        current = current / part
        require(not current.is_symlink(), "Dependency paths cannot traverse symbolic links")
    require(current.resolve().is_relative_to(root.resolve()), "Dependency path escaped its root")
    return current


def fingerprint(path):
    require(path.is_file() and not path.is_symlink(), "Expected regular dependency file")
    hasher, size = hashlib.sha256(), 0
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
            size += len(chunk)
    return {"sha256": hasher.hexdigest(), "bytes": size, "mode": stat.S_IMODE(path.stat().st_mode)}


def tree_fingerprints(root):
    require(root.is_dir() and not root.is_symlink(), "Dependency tree is missing or linked")
    records = {}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root).as_posix()
        safe_path(root, relative)
        require(path.is_file() or path.is_dir(), "Non-regular dependency entry")
        if path.is_file():
            records[relative] = fingerprint(path)
    require(bool(records), "Dependency tree is empty")
    return records


class PinnedRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, newurl):
        destination = urllib.parse.urlparse(newurl)
        require(destination.scheme == "https" and destination.hostname in DOWNLOAD_HOSTS,
                "Unexpected upstream download redirect")
        return super().redirect_request(request, response, code, message, headers, newurl)


def download_verified(url, destination, expected_sha):
    require(url in {SOURCE_URL, BINARY_URL}, "Only the two pinned upstream dependencies may be downloaded")
    require(expected_sha == {SOURCE_URL: SOURCE_SHA256, BINARY_URL: BINARY_SHA256}[url],
            "Upstream dependency checksum cannot be overridden")
    require(not destination.exists(), "Refusing to overwrite a dependency download")
    request = urllib.request.Request(url, headers={"User-Agent": "LocalGemma-pinned-runtime-builder"})
    hasher, size = hashlib.sha256(), 0
    opener = urllib.request.build_opener(PinnedRedirectHandler())
    with opener.open(request, timeout=120) as response, destination.open("xb") as output:
        final = urllib.parse.urlparse(response.url)
        require(final.scheme == "https" and final.hostname in DOWNLOAD_HOSTS, "Unexpected upstream download redirect")
        while chunk := response.read(1024 * 1024):
            size += len(chunk)
            require(size <= MAX_DOWNLOAD, "Dependency download exceeds the fixed size budget")
            hasher.update(chunk)
            output.write(chunk)
    require(size > 0 and hasher.hexdigest() == expected_sha, "Pinned dependency SHA-256 mismatch")
    return fingerprint(destination)


def extract_source(archive, destination):
    require(not destination.exists(), "Source extraction requires a new directory")
    with tarfile.open(archive, "r:gz") as source:
        entries = source.getmembers()
        require(len(entries) <= MAX_ENTRIES and sum(e.size for e in entries) <= MAX_EXTRACTED,
                "Source archive exceeds extraction limits")
        names = set()
        for entry in entries:
            name = entry.name.rstrip("/")
            safe_path(destination, name)
            require(name not in names and (name == SOURCE_PREFIX or name.startswith(SOURCE_PREFIX + "/")),
                    "Unexpected or duplicate source entry")
            require(entry.isfile() or entry.isdir(), "Source archive contains links or special files")
            names.add(name)
        destination.mkdir(parents=True)
        for entry in entries:
            path = safe_path(destination, entry.name.rstrip("/"))
            if entry.isdir():
                path.mkdir(parents=True, exist_ok=True)
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                with source.extractfile(entry) as input_file, path.open("xb") as output:
                    shutil.copyfileobj(input_file, output)
                path.chmod(0o755 if entry.mode & 0o111 else 0o644)
    return destination / SOURCE_PREFIX


def validate_metadata(document, variants):
    require(isinstance(document, dict) and document.get("XCFrameworkFormatVersion") == "1.0",
            "Expected XCFramework metadata")
    records = document.get("AvailableLibraries")
    require(isinstance(records, list) and all(isinstance(r, dict) for r in records),
            "Missing XCFramework library metadata")
    selected, identifiers = {}, set()
    for record in records:
        identifier = record.get("LibraryIdentifier")
        safe_path(Path("."), identifier)
        require("/" not in identifier and identifier not in identifiers, "Duplicate or invalid library identifier")
        identifiers.add(identifier)
        variant = record.get("SupportedPlatformVariant", "device")
        if record.get("SupportedPlatform") != "ios" or variant not in variants:
            continue
        require(variant not in selected and record.get("LibraryPath") == "llama.framework",
                "Duplicate variant or unexpected framework path")
        architectures = record.get("SupportedArchitectures", [])
        require(isinstance(architectures, list) and all(isinstance(a, str) for a in architectures)
                and len(architectures) == len(set(architectures)) and set(architectures) == PLATFORMS[variant][1],
                "Incomplete dependency architectures")
        symbols = record.get("DebugSymbolsPath")
        if symbols is not None:
            safe_path(Path("."), symbols)
        selected[variant] = record
    require(set(selected) == set(variants), "Required XCFramework platform variant is missing")
    return selected


def extract_ios_frameworks(archive, destination):
    require(not destination.exists(), "Binary extraction requires a new directory")
    with zipfile.ZipFile(archive) as binary:
        entries = binary.infolist()
        require(len(entries) <= MAX_ENTRIES and sum(e.file_size for e in entries) <= MAX_EXTRACTED,
                "XCFramework archive exceeds extraction limits")
        names = [e.filename.rstrip("/") for e in entries]
        require(len(names) == len(set(names)), "Duplicate binary archive entry")
        for name in names:
            safe_path(destination, name)
        metadata = f"{BINARY_PREFIX}/Info.plist"
        require(metadata in names, "Pinned archive does not contain the expected XCFramework")
        selected = validate_metadata(plistlib.loads(binary.read(metadata)), {"device", "simulator"})
        prefixes = tuple(f"{BINARY_PREFIX}/{r['LibraryIdentifier']}/" for r in selected.values())
        destination.mkdir(parents=True)
        for entry in entries:
            if not entry.filename.startswith(prefixes):
                continue
            kind = stat.S_IFMT(entry.external_attr >> 16)
            require(kind in {0, stat.S_IFDIR, stat.S_IFREG}, "Selected iOS slice contains links or special files")
            path = safe_path(destination, entry.filename.rstrip("/"))
            if entry.is_dir():
                path.mkdir(parents=True, exist_ok=True)
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                with binary.open(entry) as input_file, path.open("xb") as output:
                    shutil.copyfileobj(input_file, output)
                path.chmod(0o755 if entry.external_attr >> 16 & 0o111 else 0o644)
    return destination / BINARY_PREFIX, selected


def macho_slices(data):
    """Read platform load commands instead of trusting a renamed macOS binary."""
    require(len(data) >= 32, "Truncated Mach-O dependency")
    magic = struct.unpack_from(">I", data)[0]
    if magic in {0xCAFEBABE, 0xCAFEBABF}:
        count = struct.unpack_from(">I", data, 4)[0]
        require(1 <= count <= 8, "Invalid universal architecture count")
        result = {}
        for index in range(count):
            position = 8 + index * (32 if magic == 0xCAFEBABF else 20)
            require(position + (32 if magic == 0xCAFEBABF else 20) <= len(data), "Truncated universal header")
            offset, length = struct.unpack_from(">QQ" if magic == 0xCAFEBABF else ">II", data, position + 8)
            require(offset + length <= len(data) and length >= 32, "Universal slice escaped the binary")
            nested = macho_slices(data[offset:offset + length])
            require(not set(result) & set(nested), "Duplicate universal architecture")
            result.update(nested)
        return result
    require(struct.unpack_from("<I", data)[0] == 0xFEEDFACF, "Expected a 64-bit Apple Mach-O binary")
    _, cpu, _, filetype, count, commands_size = struct.unpack_from("<IIIIII", data)
    architecture = {0x0100000C: "arm64", 0x01000007: "x86_64"}.get(cpu)
    require(architecture is not None and filetype == 6 and 32 + commands_size <= len(data),
            "Expected an arm64/x86_64 dynamic framework")
    position, platforms = 32, []
    for _ in range(count):
        require(position + 8 <= 32 + commands_size, "Truncated load command")
        command, size = struct.unpack_from("<II", data, position)
        require(size >= 8 and position + size <= 32 + commands_size, "Invalid load command extent")
        if command == 0x32:
            require(size >= 24, "Truncated build-version command")
            platforms.append(struct.unpack_from("<I", data, position + 8)[0])
        position += size
    require(position == 32 + commands_size and len(platforms) == 1, "Missing unique native build platform")
    return {architecture: platforms[0]}


def validate_frameworks(framework):
    metadata = plistlib.loads((framework / "Info.plist").read_bytes())
    selected = validate_metadata(metadata, set(PLATFORMS))
    require(len(metadata["AvailableLibraries"]) == 3, "Delivery must contain exactly three supported variants")
    for variant, record in selected.items():
        library = safe_path(framework, record["LibraryIdentifier"] + "/llama.framework")
        require((library / "Headers/llama.h").is_file() and (library / "Modules/module.modulemap").is_file(),
                "Missing public llama headers/module")
        require((library / "LICENSE").is_file() and (library / "THIRD_PARTY_NOTICES.txt").is_file(),
                "Redistributed frameworks must preserve upstream legal notices")
        platform, architectures = PLATFORMS[variant]
        require(macho_slices((library / "llama").read_bytes()) == {a: platform for a in architectures},
                "Framework Mach-O platform or architecture does not match its metadata")
    return selected


def run(arguments, log, timeout=1800):
    require_hosted_macos(os.environ)
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as output:
        output.write("+ " + " ".join(map(str, arguments)) + "\n")
        output.flush()
        completed = subprocess.run(list(map(str, arguments)), cwd=ROOT, stdout=output,
                                   stderr=subprocess.STDOUT, timeout=timeout, check=False)
    text = log.read_text(encoding="utf-8", errors="replace")
    if completed.returncode:
        print(text[-20000:], flush=True)
        raise subprocess.CalledProcessError(completed.returncode, arguments)
    return "\n".join(text.splitlines()[1:]).strip()


def catalyst_cmake_arguments(source, build, architecture, sdk, clang, clangxx):
    require(architecture in {"arm64", "x86_64"}, "Unsupported Catalyst architecture")
    target = f"{architecture}-apple-ios17.0-macabi"
    flags = f"-target {target} -g -O2"
    return ["cmake", "-S", source, "-B", build, "-G", "Unix Makefiles", "-DCMAKE_BUILD_TYPE=Release",
            "-DCMAKE_SYSTEM_NAME=Darwin", f"-DCMAKE_SYSTEM_PROCESSOR={architecture}",
            f"-DCMAKE_OSX_SYSROOT={sdk}", f"-DCMAKE_OSX_ARCHITECTURES={architecture}",
            "-DCMAKE_OSX_DEPLOYMENT_TARGET=", "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
            f"-DCMAKE_C_COMPILER={clang}", f"-DCMAKE_CXX_COMPILER={clangxx}",
            f"-DCMAKE_C_FLAGS={flags}", f"-DCMAKE_CXX_FLAGS={flags}",
            "-DCMAKE_POSITION_INDEPENDENT_CODE=ON", "-DBUILD_SHARED_LIBS=OFF",
            "-DLLAMA_BUILD_COMMON=OFF", "-DLLAMA_BUILD_TESTS=OFF", "-DLLAMA_BUILD_TOOLS=OFF",
            "-DLLAMA_BUILD_EXAMPLES=OFF", "-DLLAMA_BUILD_SERVER=OFF", "-DLLAMA_BUILD_APP=OFF",
            "-DLLAMA_BUILD_MTMD=OFF", "-DLLAMA_OPENSSL=OFF", "-DLLAMA_SUBPROCESS=OFF",
            "-DLLAMA_CONNECT=OFF", "-DGGML_NATIVE=OFF", "-DGGML_METAL=OFF", "-DGGML_ACCELERATE=OFF",
            "-DGGML_BLAS=OFF", "-DGGML_OPENMP=OFF", "-DGGML_BACKEND_DL=OFF", "-DGGML_CCACHE=OFF",
            "-DGGML_LLAMAFILE=OFF", "-DFETCHCONTENT_FULLY_DISCONNECTED=ON",
            f"-DLLAMA_BUILD_COMMIT={COMMIT}", f"-DLLAMA_BUILD_NUMBER={TAG[1:]}"]


def build_catalyst(source, work, headers, sdk, logs):
    clang = run(["xcrun", "--find", "clang"], logs / "clang-path.log")
    clangxx = run(["xcrun", "--find", "clang++"], logs / "clangxx-path.log")
    binaries = []
    for architecture in ["arm64", "x86_64"]:
        build = work / f"catalyst-{architecture}"
        run(catalyst_cmake_arguments(source, build, architecture, sdk, clang, clangxx),
            logs / f"catalyst-{architecture}-configure.log")
        run(["cmake", "--build", build, "--target", "llama", "vendor-hash", "--parallel", "3"],
            logs / f"catalyst-{architecture}-build.log")
        libraries = [build / "src/libllama.a", build / "ggml/src/libggml.a",
                     build / "ggml/src/libggml-base.a", build / "ggml/src/libggml-cpu.a",
                     build / "vendor/hash/libvendor-hash.a"]
        require(all(p.is_file() for p in libraries), "A required Catalyst static library was not built")
        combined = build / "combined.a"
        run(["xcrun", "libtool", "-static", "-o", combined, *libraries], logs / f"catalyst-{architecture}-combine.log")
        binary = build / "llama"
        run([clangxx, "-target", f"{architecture}-apple-ios17.0-macabi", "-isysroot", sdk,
             "-dynamiclib", "-Wl,-force_load," + str(combined), "-install_name", "@rpath/llama.framework/llama",
             "-o", binary], logs / f"catalyst-{architecture}-link.log")
        require(macho_slices(binary.read_bytes()) == {architecture: 6}, "Catalyst compiler emitted a different platform")
        binaries.append(binary)
    framework = work / "catalyst/llama.framework"
    framework.mkdir(parents=True)
    shutil.copytree(headers, framework / "Headers", ignore=shutil.ignore_patterns("mtmd*.h", "ggml-metal.h", "ggml-blas.h"))
    (framework / "Modules").mkdir()
    (framework / "Modules/module.modulemap").write_text(
        'framework module llama { umbrella "Headers" link "c++" export * }\n', encoding="ascii")
    (framework / "Info.plist").write_bytes(plistlib.dumps({
        "CFBundleExecutable": "llama", "CFBundleIdentifier": "org.ggml.llama", "CFBundleName": "llama",
        "CFBundlePackageType": "FMWK", "CFBundleShortVersionString": "0.8.0", "CFBundleVersion": TAG[1:],
        "CFBundleSupportedPlatforms": ["MacOSX"], "DTPlatformName": "macosx", "UIDeviceFamily": [6],
        "MinimumOSVersion": "17.0"}))
    run(["xcrun", "lipo", "-create", *binaries, "-output", framework / "llama"], logs / "catalyst-lipo.log")
    symbols = work / "catalyst/llama.dSYM"
    run(["xcrun", "dsymutil", framework / "llama", "-o", symbols], logs / "catalyst-dsym.log")
    return framework, symbols


def legal_notices(source):
    sections = [f"llama.cpp {TAG}, source commit {COMMIT}.\n"
                "These notices cover the native library, not any model weights.\n"]
    files = sorted(p for p in source.rglob("*") if p.is_file() and p.name.upper().startswith(("LICENSE", "COPYING", "NOTICE"))
                   and p.suffix.lower() not in {".cmake"})
    for path in files:
        sections.append(f"\n--- {path.relative_to(source)} ---\n" + path.read_text(encoding="utf-8", errors="strict"))
    for relative, tail in [("vendor/hash/sha1/sha1.c", False), ("vendor/sheredom/subprocess.h", False),
                           ("ggml/src/ggml-cpu/llamafile/sgemm.cpp", False),
                           ("vendor/stb/stb_image.h", True), ("vendor/miniaudio/miniaudio.h", True)]:
        text = (source / relative).read_text(encoding="utf-8")
        if tail:
            start = text.rfind("/*")
            require(start >= 0, "Expected embedded third-party license block")
            notice = text[start:]
        elif text.lstrip().startswith("/*"):
            comments = re.match(r"\s*(?:(?:/\*.*?\*/)\s*)+", text, re.S)
            require(comments is not None, "Expected leading third-party license comments")
            notice = comments[0]
        else:
            notice = "\n".join(text.splitlines()[:23])
        sections.append(f"\n--- Embedded notice from {relative} ---\n{notice}\n")
    return "\n".join(sections)


def input_identity(toolchain):
    return {"tag": TAG, "commit": COMMIT, "sourceUrl": SOURCE_URL, "sourceSha256": SOURCE_SHA256,
            "binaryUrl": BINARY_URL, "binarySha256": BINARY_SHA256, "toolchain": toolchain,
            "builderSha256": fingerprint(Path(__file__))["sha256"],
            "catalyst": "CPU-only; no Metal, Accelerate, OpenMP, dynamic backend loading or network tools"}


def validate_cache(root, expected_identity):
    manifest = json.loads(safe_path(root, "manifest.json").read_text(encoding="utf-8"))
    require(manifest.get("schemaVersion") == 1 and manifest.get("status") == "success"
            and manifest.get("inputs") == expected_identity, "Dependency cache identity/toolchain mismatch")
    require(manifest.get("runtimeVerified") is False and manifest.get("modelWeightsDownloaded") is False,
            "Dependency cache must not claim model inference verification")
    downloads = manifest.get("downloads", {})
    require(all(downloads.get(name, {}).get("sha256") == digest and downloads[name].get("bytes", 0) > 0
                for name, digest in [("source", SOURCE_SHA256), ("binary", BINARY_SHA256)]),
            "Dependency cache lacks pinned download receipts")
    require(manifest.get("nativeLinkChecks") == [f"{v}:{a}" for v in sorted(PLATFORMS) for a in sorted(PLATFORMS[v][1])],
            "Dependency cache lacks required native link checks")
    framework = safe_path(root, "llama.xcframework")
    validate_frameworks(framework)
    require(manifest.get("files") == tree_fingerprints(framework), "Dependency cache file SHA-256 or mode mismatch")
    return manifest


def link_smoke(framework, work, logs, mac_sdk):
    source = work / "link-smoke.cpp"
    source.write_text('#include <llama/llama.h>\nint main() { llama_backend_init(); '
                      'auto p = llama_model_default_params(); llama_backend_free(); return p.n_gpu_layers; }\n', encoding="ascii")
    selected = validate_frameworks(framework)
    for variant, record in selected.items():
        sdk = mac_sdk if variant == "maccatalyst" else run(
            ["xcrun", "--sdk", "iphoneos" if variant == "device" else "iphonesimulator", "--show-sdk-path"],
            logs / f"{variant}-sdk-path.log")
        for architecture in sorted(PLATFORMS[variant][1]):
            suffix = "-macabi" if variant == "maccatalyst" else ("-simulator" if variant == "simulator" else "")
            run(["xcrun", "clang++", "-target", f"{architecture}-apple-ios17.0{suffix}", "-isysroot", sdk,
                 "-std=c++17", "-F", framework / record["LibraryIdentifier"], "-framework", "llama", source,
                 "-o", work / f"link-smoke-{variant}-{architecture}"], logs / f"link-smoke-{variant}-{architecture}.log")


def main():
    require_hosted_macos(os.environ)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", type=Path, default=ROOT / ".runtime")
    args = parser.parse_args()
    root = args.output_root.resolve()
    require(not args.output_root.is_symlink(), "Output root cannot be a symbolic link")
    root.mkdir(parents=True, exist_ok=True)
    run_id, attempt = os.environ.get("GITHUB_RUN_ID", ""), os.environ.get("GITHUB_RUN_ATTEMPT", "")
    require(re.fullmatch(r"[1-9][0-9]*", run_id) and re.fullmatch(r"[1-9][0-9]*", attempt), "Missing valid hosted run identity")
    logs = safe_path(root, f"logs/run{run_id}-attempt{attempt}")
    logs.mkdir(parents=True, exist_ok=True)
    stage = "toolchain"
    try:
        xcode = run(["xcodebuild", "-version"], logs / "xcode-version.log")
        mac_sdk = run(["xcrun", "--sdk", "macosx", "--show-sdk-path"], logs / "macos-sdk-path.log")
        sdk_version = run(["xcrun", "--sdk", "macosx", "--show-sdk-version"], logs / "macos-sdk-version.log")
        identity = input_identity({"xcode": xcode, "macosSdkVersion": sdk_version})
        stage = "cache-validation"
        if (root / "llama.xcframework").exists() or (root / "manifest.json").exists():
            validate_cache(root, identity)
            print("Verified cached pinned llama XCFramework; no model weights downloaded", flush=True)
            return 0
        work_root = safe_path(root, "work")
        work_root.mkdir(exist_ok=True)
        work = Path(tempfile.mkdtemp(prefix="build-", dir=work_root))
        stage = "download-and-extract"
        source_archive, binary_archive = work / "source.tar.gz", work / "prebuilt.zip"
        downloads = {"source": download_verified(SOURCE_URL, source_archive, SOURCE_SHA256),
                     "binary": download_verified(BINARY_URL, binary_archive, BINARY_SHA256)}
        source = extract_source(source_archive, work / "source")
        official, records = extract_ios_frameworks(binary_archive, work / "official")
        stage = "catalyst-build"
        device = official / records["device"]["LibraryIdentifier"] / "llama.framework"
        require((device / "Headers/llama.h").read_bytes() == (source / "include/llama.h").read_bytes(),
                "Official public C API does not match the pinned source revision")
        catalyst, catalyst_symbols = build_catalyst(source, work, device / "Headers", mac_sdk, logs)
        stage = "package"
        arguments = ["xcrun", "xcodebuild", "-create-xcframework"]
        notices = legal_notices(source)
        for path in [*(official / r["LibraryIdentifier"] / "llama.framework" for r in records.values()), catalyst]:
            shutil.copyfile(source / "LICENSE", path / "LICENSE")
            (path / "THIRD_PARTY_NOTICES.txt").write_text(notices, encoding="utf-8")
            arguments += ["-framework", path]
            symbols = catalyst_symbols if path == catalyst else path.parent / records[
                "device" if path == device else "simulator"].get("DebugSymbolsPath", "dSYMs")
            candidates = [symbols] if symbols.suffix == ".dSYM" else sorted(symbols.glob("*.dSYM"))
            require(len(candidates) == 1, "Missing unique upstream/Catalyst dependency dSYM")
            arguments += ["-debug-symbols", candidates[0]]
        output = work / "llama.xcframework"
        run(arguments + ["-output", output], logs / "create-xcframework.log")
        stage = "native-link-validation"
        link_smoke(output, work, logs, mac_sdk)
        files = tree_fingerprints(output)
        manifest = {"schemaVersion": 1, "status": "success", "inputs": identity, "downloads": downloads,
                    "runtimeVerified": False, "modelWeightsDownloaded": False, "files": files,
                    "producedBy": {"commitSha": os.environ.get("GITHUB_SHA"), "runId": os.environ.get("GITHUB_RUN_ID"),
                                   "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT")},
                    "nativeLinkChecks": [f"{v}:{a}" for v in sorted(PLATFORMS) for a in sorted(PLATFORMS[v][1])]}
        output.rename(root / "llama.xcframework")
        (root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        validate_cache(root, identity)
        print("Prepared pinned iOS/Simulator and CPU-only Mac Catalyst llama XCFramework; real inference remains unverified", flush=True)
        return 0
    except Exception as error:
        failure = {"status": "failure", "stage": stage, "type": type(error).__name__, "message": str(error),
                   "runtimeVerified": False, "modelWeightsDownloaded": False}
        safe_path(root, "failure.json").write_text(json.dumps(failure, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(failure), flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
