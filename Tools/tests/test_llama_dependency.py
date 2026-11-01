"""Synthetic archives and Mach-O headers only; never invoke a native compiler."""
import copy
import io
import json
from pathlib import Path
import plistlib
import stat
import struct
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import urllib.request
import zipfile


sys.path.insert(0, str(Path(__file__).parents[1]))
import prepare_llama_dependency as CHECK
import stage_native_framework as STAGE


def macho(architecture, platform):
    cpu = {"arm64": 0x0100000C, "x86_64": 0x01000007}[architecture]
    header = struct.pack("<IIIIIIII", 0xFEEDFACF, cpu, 0, 6, 1, 24, 0, 0)
    return header + struct.pack("<IIIIII", 0x32, 24, platform, 0x110000, 0x1A0000, 0)


def universal(slices):
    cursor = 8 + 20 * len(slices)
    header, payload = struct.pack(">II", 0xCAFEBABE, len(slices)), b""
    for architecture, binary in slices.items():
        cpu = {"arm64": 0x0100000C, "x86_64": 0x01000007}[architecture]
        header += struct.pack(">IIIII", cpu, 0, cursor, len(binary), 0)
        payload += binary
        cursor += len(binary)
    return header + payload


def metadata(variants):
    records = []
    for variant in sorted(variants):
        record = {"LibraryIdentifier": "ios-" + variant, "LibraryPath": "llama.framework",
                  "SupportedArchitectures": sorted(CHECK.PLATFORMS[variant][1]), "SupportedPlatform": "ios"}
        if variant != "device":
            record["SupportedPlatformVariant"] = variant
        records.append(record)
    return {"XCFrameworkFormatVersion": "1.0", "AvailableLibraries": records}


class LlamaDependencyTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="localgemma-dependency-fixture-")
        self.root = Path(self.temporary.name)

    def tearDown(self):
        self.temporary.cleanup()

    def framework(self):
        root = self.root / "llama.xcframework"
        root.mkdir()
        info = metadata(CHECK.PLATFORMS)
        (root / "Info.plist").write_bytes(plistlib.dumps(info))
        for variant, record in CHECK.validate_metadata(info, set(CHECK.PLATFORMS)).items():
            framework = root / record["LibraryIdentifier"] / "llama.framework"
            (framework / "Headers").mkdir(parents=True)
            (framework / "Modules").mkdir()
            (framework / "Headers/llama.h").write_text("/* fixture header, not executable code */\n")
            (framework / "Modules/module.modulemap").write_text('framework module llama { umbrella "Headers" export * }\n')
            (framework / "LICENSE").write_text("fixture upstream license\n")
            (framework / "THIRD_PARTY_NOTICES.txt").write_text("fixture third-party notices\n")
            (framework / "Info.plist").write_bytes(plistlib.dumps({"CFBundleExecutable": "llama", "CFBundlePackageType": "FMWK"}))
            platform, architectures = CHECK.PLATFORMS[variant]
            binaries = {a: macho(a, platform) for a in sorted(architectures)}
            (framework / "llama").write_bytes(universal(binaries) if len(binaries) > 1 else next(iter(binaries.values())))
            (framework / "llama").chmod(0o755)
        return root

    def cache(self):
        framework = self.framework()
        identity = CHECK.input_identity({"xcode": "synthetic-fixture", "macosSdkVersion": "fixture"})
        manifest = {"schemaVersion": 1, "status": "success", "inputs": identity,
                    "runtimeVerified": False, "modelWeightsDownloaded": False,
                    "downloads": {"source": {"sha256": CHECK.SOURCE_SHA256, "bytes": 1},
                                  "binary": {"sha256": CHECK.BINARY_SHA256, "bytes": 1}},
                    "nativeLinkChecks": [f"{v}:{a}" for v in sorted(CHECK.PLATFORMS) for a in sorted(CHECK.PLATFORMS[v][1])],
                    "files": CHECK.tree_fingerprints(framework)}
        (self.root / "manifest.json").write_text(json.dumps(manifest))
        return identity, manifest

    def test_local_guard_rejects_before_any_command_download_or_directory_creation(self):
        with patch.object(CHECK.os, "environ", {}), patch.object(CHECK, "run") as run, \
                patch.object(CHECK, "download_verified") as download, patch.object(CHECK.Path, "mkdir") as mkdir:
            with self.assertRaisesRegex(ValueError, "GitHub-hosted"):
                CHECK.main()
            run.assert_not_called()
            download.assert_not_called()
            mkdir.assert_not_called()

    def test_command_wrapper_independently_rejects_local_native_commands(self):
        with patch.object(CHECK.os, "environ", {}), patch.object(CHECK.subprocess, "run") as process:
            with self.assertRaisesRegex(ValueError, "GitHub-hosted"):
                CHECK.run(["xcodebuild", "-version"], self.root / "never-created.log")
            process.assert_not_called()
        self.assertFalse((self.root / "never-created.log").exists())

    def test_pinned_urls_and_checksums_cannot_be_replaced_by_model_downloads(self):
        with self.assertRaisesRegex(ValueError, "pinned upstream"):
            CHECK.download_verified("https://huggingface.co/example/model.gguf", self.root / "model", "a" * 64)
        with self.assertRaisesRegex(ValueError, "cannot be overridden"):
            CHECK.download_verified(CHECK.SOURCE_URL, self.root / "source", "a" * 64)
        self.assertFalse(any(self.root.iterdir()))

    def test_redirect_rejects_nonhttps_or_other_hosts_before_following(self):
        handler = CHECK.PinnedRedirectHandler()
        request = urllib.request.Request(CHECK.SOURCE_URL)
        for url in ["http://github.com/file", "https://example.org/file", "https://127.0.0.1/model", "file:///etc/passwd"]:
            with self.subTest(url=url), self.assertRaisesRegex(ValueError, "redirect"):
                handler.redirect_request(request, None, 302, "Found", {}, url)

    def test_download_rejects_wrong_checksum_and_oversized_payload_without_network(self):
        for limit in [CHECK.MAX_DOWNLOAD, 1]:
            response = io.BytesIO(b"synthetic dependency fixture, never a real model")
            response.url = CHECK.SOURCE_URL
            with patch.object(CHECK.urllib.request, "build_opener") as opener, patch.object(CHECK, "MAX_DOWNLOAD", limit):
                opener.return_value.open.return_value = response
                with self.assertRaisesRegex(ValueError, "SHA-256 mismatch|size budget"):
                    CHECK.download_verified(CHECK.SOURCE_URL, self.root / f"source-{limit}", CHECK.SOURCE_SHA256)

    def test_relative_paths_reject_escape_duplicate_separators_and_links(self):
        for path in ["../escape", "/absolute", "a/../b", "a//b", "a\\b", "a\0b", "", "."]:
            with self.subTest(path=path), self.assertRaises(ValueError):
                CHECK.safe_path(self.root, path)
        (self.root / "linked").symlink_to(self.root, target_is_directory=True)
        with self.assertRaises(ValueError):
            CHECK.safe_path(self.root, "linked/file")

    def test_metadata_requires_all_architectures_and_distinct_variants(self):
        valid = metadata(CHECK.PLATFORMS)
        self.assertEqual(set(CHECK.validate_metadata(valid, set(CHECK.PLATFORMS))), set(CHECK.PLATFORMS))
        wrong_path = copy.deepcopy(valid)
        wrong_path["AvailableLibraries"][0]["LibraryPath"] = "../llama.framework"
        duplicated_arch = copy.deepcopy(valid)
        duplicated_arch["AvailableLibraries"][0]["SupportedArchitectures"] *= 2
        for changed in [metadata({"device", "simulator"}), wrong_path, duplicated_arch]:
            with self.assertRaises(ValueError):
                CHECK.validate_metadata(changed, set(CHECK.PLATFORMS))
        duplicate = copy.deepcopy(valid)
        duplicate["AvailableLibraries"].append(copy.deepcopy(duplicate["AvailableLibraries"][0]))
        with self.assertRaises(ValueError):
            CHECK.validate_metadata(duplicate, set(CHECK.PLATFORMS))
        wrong_arch = copy.deepcopy(valid)
        wrong_arch["AvailableLibraries"][0]["SupportedArchitectures"] = ["x86_64"]
        with self.assertRaises(ValueError):
            CHECK.validate_metadata(wrong_arch, set(CHECK.PLATFORMS))

    def test_macho_parser_distinguishes_macos_from_real_catalyst(self):
        self.assertEqual(CHECK.macho_slices(macho("arm64", 6)), {"arm64": 6})
        self.assertEqual(CHECK.macho_slices(universal({"arm64": macho("arm64", 7), "x86_64": macho("x86_64", 7)})),
                         {"arm64": 7, "x86_64": 7})
        root = self.framework()
        record = CHECK.validate_frameworks(root)["maccatalyst"]
        binary = root / record["LibraryIdentifier"] / "llama.framework/llama"
        binary.write_bytes(universal({"arm64": macho("arm64", 1), "x86_64": macho("x86_64", 1)}))
        with self.assertRaisesRegex(ValueError, "Mach-O platform"):
            CHECK.validate_frameworks(root)

    def test_macho_parser_rejects_missing_platform_truncated_and_non_dynamic_binaries(self):
        for content in [b"", b"not an executable" * 5, macho("arm64", 6)[:-1],
                        macho("arm64", 6)[:12] + struct.pack("<I", 2) + macho("arm64", 6)[16:],
                        universal({"arm64": macho("arm64", 6)})[:-1]]:
            with self.subTest(size=len(content)), self.assertRaises(ValueError):
                CHECK.macho_slices(content)

    def test_cache_rechecks_every_file_mode_digest_and_exact_toolchain(self):
        identity, original = self.cache()
        self.assertEqual(CHECK.validate_cache(self.root, identity), original)
        with self.assertRaisesRegex(ValueError, "identity/toolchain"):
            CHECK.validate_cache(self.root, {**identity, "toolchain": {"xcode": "different"}})
        binary = self.root / "llama.xcframework/ios-device/llama.framework/llama"
        binary.chmod(0o644)
        with self.assertRaisesRegex(ValueError, "SHA-256 or mode"):
            CHECK.validate_cache(self.root, identity)
        binary.chmod(0o755)
        binary.write_bytes(binary.read_bytes() + b"tampered payload")
        with self.assertRaisesRegex(ValueError, "SHA-256 or mode"):
            CHECK.validate_cache(self.root, identity)

    def test_cache_rejects_missing_link_checks_upstream_receipts_or_false_runtime_claims(self):
        identity, original = self.cache()
        for key, value in [("nativeLinkChecks", []), ("downloads", {}), ("runtimeVerified", True),
                           ("modelWeightsDownloaded", True), ("status", "running")]:
            changed = {**original, key: value}
            (self.root / "manifest.json").write_text(json.dumps(changed))
            with self.subTest(key=key), self.assertRaises(ValueError):
                CHECK.validate_cache(self.root, identity)

    def test_source_extractor_rejects_escape_or_symlink_before_creating_output(self):
        for name, kind in [("../outside", tarfile.REGTYPE), (CHECK.SOURCE_PREFIX + "/linked", tarfile.SYMTYPE)]:
            archive = self.root / f"source-{kind.decode()}.tar.gz"
            with tarfile.open(archive, "w:gz") as output:
                entry = tarfile.TarInfo(name)
                entry.type = kind
                entry.linkname = "../../../escape"
                output.addfile(entry, io.BytesIO())
            destination = self.root / f"extracted-{kind.decode()}"
            with self.assertRaises(ValueError):
                CHECK.extract_source(archive, destination)
            self.assertFalse(destination.exists())

    def test_source_extractor_copies_only_regular_files_under_exact_commit_prefix(self):
        archive = self.root / "source.tar.gz"
        content = b"fixture source, not compiled"
        with tarfile.open(archive, "w:gz") as output:
            entry = tarfile.TarInfo(CHECK.SOURCE_PREFIX + "/LICENSE")
            entry.size = len(content)
            output.addfile(entry, io.BytesIO(content))
        extracted = CHECK.extract_source(archive, self.root / "source")
        self.assertEqual((extracted / "LICENSE").read_bytes(), content)

    def test_zip_extractor_rejects_selected_slice_symlinks(self):
        archive = self.root / "prebuilt.zip"
        with zipfile.ZipFile(archive, "w") as output:
            output.writestr(CHECK.BINARY_PREFIX + "/Info.plist", plistlib.dumps(metadata({"device", "simulator"})))
            entry = zipfile.ZipInfo(CHECK.BINARY_PREFIX + "/ios-device/llama.framework/llama")
            entry.create_system = 3
            entry.external_attr = (stat.S_IFLNK | 0o777) << 16
            output.writestr(entry, "../../../../escape")
        with self.assertRaisesRegex(ValueError, "links or special"):
            CHECK.extract_ios_frameworks(archive, self.root / "official")

    def test_zip_extractor_never_materializes_unselected_macos_symlinks(self):
        archive = self.root / "prebuilt.zip"
        info = metadata({"device", "simulator"})
        info["AvailableLibraries"].append({"LibraryIdentifier": "macos-arm64_x86_64", "LibraryPath": "llama.framework",
                                           "SupportedArchitectures": ["arm64", "x86_64"], "SupportedPlatform": "macos"})
        with zipfile.ZipFile(archive, "w") as output:
            output.writestr(CHECK.BINARY_PREFIX + "/Info.plist", plistlib.dumps(info))
            output.writestr(CHECK.BINARY_PREFIX + "/ios-device/llama.framework/Headers/llama.h", "fixture iOS header")
            entry = zipfile.ZipInfo(CHECK.BINARY_PREFIX + "/macos-arm64_x86_64/llama.framework/Headers")
            entry.create_system = 3
            entry.external_attr = (stat.S_IFLNK | 0o777) << 16
            output.writestr(entry, "Versions/Current/Headers")
        root, records = CHECK.extract_ios_frameworks(archive, self.root / "official")
        self.assertEqual(set(records), {"device"})
        self.assertTrue((root / "ios-device/llama.framework/Headers/llama.h").is_file())
        self.assertFalse((root / "macos-arm64_x86_64").exists())

    def test_actual_upstream_device_macos_metadata_cannot_satisfy_final_simulator_gate(self):
        # Shape transcribed from the pinned b12032 asset's actual Info.plist.
        upstream = {"XCFrameworkFormatVersion": "1.0", "CFBundlePackageType": "XFWK", "AvailableLibraries": [
            {"BinaryPath": "llama.framework/llama", "DebugSymbolsPath": "dSYMs", "LibraryIdentifier": "ios-arm64",
             "LibraryPath": "llama.framework", "SupportedArchitectures": ["arm64"], "SupportedPlatform": "ios"},
            {"BinaryPath": "llama.framework/Versions/A/llama", "DebugSymbolsPath": "dSYMs",
             "LibraryIdentifier": "macos-arm64_x86_64", "LibraryPath": "llama.framework",
             "SupportedArchitectures": ["arm64", "x86_64"], "SupportedPlatform": "macos"},
        ]}
        self.assertEqual(set(CHECK.validate_metadata(upstream, {"device"})), {"device"})
        with self.assertRaisesRegex(ValueError, "variant is missing"):
            CHECK.validate_metadata(upstream, set(CHECK.PLATFORMS))
        archive = self.root / "actual-shape.zip"
        with zipfile.ZipFile(archive, "w") as output:
            output.writestr(CHECK.BINARY_PREFIX + "/Info.plist", plistlib.dumps(upstream))
            output.writestr(CHECK.BINARY_PREFIX + "/ios-arm64/llama.framework/Headers/llama.h", "fixture header")
        root, selected = CHECK.extract_ios_frameworks(archive, self.root / "official")
        self.assertEqual(selected["device"]["LibraryIdentifier"], "ios-arm64")
        self.assertTrue((root / "ios-arm64/llama.framework/Headers/llama.h").exists())
        self.assertEqual(sum(len(p[1]) for p in CHECK.PLATFORMS.values()), 5)

    def test_legal_notices_preserve_license_files_and_all_leading_embedded_notices(self):
        source = self.root / "source"
        source.mkdir()
        (source / "LICENSE").write_text("fixture upstream MIT license\n")
        for relative, content in [
            ("vendor/hash/sha1/sha1.c", "/* Public domain hash fixture */\n#include <stdint.h>\n"),
            ("vendor/sheredom/subprocess.h", "/* upstream URL */\n/* actual public domain license fixture */\n#ifndef TEST\n"),
            ("ggml/src/ggml-cpu/llamafile/sgemm.cpp", "// MIT license fixture\n"),
            ("vendor/stb/stb_image.h", "fixture source\n/* stb embedded MIT license fixture */\n"),
            ("vendor/miniaudio/miniaudio.h", "fixture source\n/* miniaudio embedded license fixture */\n"),
        ]:
            path = source / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        notices = CHECK.legal_notices(source)
        for text in ["upstream MIT license", "Public domain hash", "actual public domain license", "stb embedded MIT",
                     "miniaudio embedded license", "MIT license fixture", CHECK.COMMIT]:
            self.assertIn(text, notices)

    def test_catalyst_arguments_are_cpu_only_and_use_an_actual_macabi_target(self):
        arguments = list(map(str, CHECK.catalyst_cmake_arguments("source", "build", "arm64", "/sdk", "/clang", "/clang++")))
        self.assertIn("-DCMAKE_SYSTEM_NAME=Darwin", arguments)
        self.assertIn("-DCMAKE_C_FLAGS=-target arm64-apple-ios17.0-macabi -g -O2", arguments)
        for flag in ["-DGGML_METAL=OFF", "-DGGML_ACCELERATE=OFF", "-DGGML_BLAS=OFF", "-DGGML_OPENMP=OFF",
                     "-DLLAMA_OPENSSL=OFF", "-DLLAMA_SUBPROCESS=OFF", "-DLLAMA_BUILD_MTMD=OFF", "-DGGML_BACKEND_DL=OFF",
                     "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"]:
            self.assertIn(flag, arguments)
        with self.assertRaises(ValueError):
            CHECK.catalyst_cmake_arguments("source", "build", "arm64e", "/sdk", "/clang", "/clang++")

    def test_missing_official_simulator_is_built_for_both_real_simulator_targets(self):
        for architecture in ["arm64", "x86_64"]:
            arguments = list(map(str, CHECK.cpu_cmake_arguments("source", "build", architecture, "/simulator-sdk",
                                                               "/clang", "/clang++", "simulator")))
            self.assertIn("-DCMAKE_SYSTEM_NAME=iOS", arguments)
            self.assertIn("-DCMAKE_OSX_DEPLOYMENT_TARGET=17.0", arguments)
            self.assertIn(f"-DCMAKE_C_FLAGS=-target {architecture}-apple-ios17.0-simulator -g -O2", arguments)
            self.assertIn("-DCMAKE_OSX_SYSROOT=/simulator-sdk", arguments)
            for flag in ["-DGGML_METAL=OFF", "-DGGML_ACCELERATE=OFF", "-DGGML_BLAS=OFF", "-DLLAMA_BUILD_MTMD=OFF"]:
                self.assertIn(flag, arguments)
        with self.assertRaises(ValueError):
            CHECK.cpu_cmake_arguments("source", "build", "arm64", "/sdk", "/clang", "/clang++", "macos")

    def test_catalyst_staging_preserves_native_bytes_and_the_immutable_cache(self):
        source = self.framework()
        before = CHECK.tree_fingerprints(source)
        destination = self.root / "staged/llama.xcframework"
        records = STAGE.stage_framework(source, destination)
        self.assertEqual(CHECK.tree_fingerprints(source), before)
        framework = destination / "ios-maccatalyst/llama.framework"
        self.assertFalse((framework / "Info.plist").exists())
        self.assertTrue((framework / "Versions/Current/Resources/Info.plist").is_file())
        self.assertTrue((framework / "llama").is_symlink())
        self.assertEqual((framework / "llama").read_bytes(), (source / "ios-maccatalyst/llama.framework/llama").read_bytes())
        self.assertEqual(records, STAGE.app_framework_fingerprints(destination))
        packaged = self.root / "framework.zip"
        STAGE.package_framework(destination, packaged)
        with zipfile.ZipFile(packaged) as archive:
            link = archive.getinfo("llama.xcframework/ios-maccatalyst/llama.framework/Versions/Current")
            self.assertTrue(stat.S_ISLNK(link.external_attr >> 16))
            self.assertEqual(archive.read(link), b"A")

    def test_versioned_framework_rejects_escaping_or_unexpected_aliases(self):
        source = self.framework()
        destination = self.root / "staged/llama.xcframework"
        STAGE.stage_framework(source, destination)
        framework = destination / "ios-maccatalyst/llama.framework"
        alias = framework / "Headers"
        alias.unlink()
        alias.symlink_to(self.root, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "escaping"):
            STAGE.app_framework_fingerprints(destination)
        alias.unlink()
        alias.symlink_to(STAGE.CATALYST_LINKS["Headers"], target_is_directory=True)
        (framework / "extra-link").symlink_to("Versions/Current/Headers", target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "Unexpected"):
            STAGE.app_framework_fingerprints(destination)

    def test_staging_cannot_accept_a_linked_source_or_overwrite_existing_output(self):
        source = self.framework()
        target = self.root / "sentinel"
        target.write_text("preserve")
        with self.assertRaisesRegex(ValueError, "new path"):
            STAGE.stage_framework(source, target)
        (source / "extra").symlink_to(self.root, target_is_directory=True)
        with self.assertRaises(ValueError):
            STAGE.stage_framework(source, self.root / "staged")
        self.assertEqual(target.read_text(), "preserve")

    def test_app_framework_entry_point_rejects_local_commands_before_staging(self):
        with patch.object(STAGE.os, "environ", {}), patch.object(STAGE.subprocess, "check_output") as command, \
                patch.object(STAGE.shutil, "copytree") as copytree:
            with self.assertRaisesRegex(ValueError, "GitHub-hosted"):
                STAGE.main()
            command.assert_not_called()
            copytree.assert_not_called()


if __name__ == "__main__":
    unittest.main()
