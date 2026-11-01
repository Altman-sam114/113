"""Pure fake-archive fixtures; never compile or run Apple tools or set cloud environment flags."""
import copy
import json
from pathlib import Path
import plistlib
import shutil
import stat
import struct
import sys
import tempfile
import unittest
from native_bundle_fixture import add_fixture_native_runtime
from unittest.mock import patch
import zipfile
import zlib


sys.path.insert(0, str(Path(__file__).parents[1]))
import cloud_release_archive as CHECK
from verify_release_bundle import EXPECTED_PRIVACY


SHA = "a" * 40
UUID = "12345678-1234-1234-1234-123456789ABC"


def png():
    def chunk(kind, payload):
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xffffffff)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\0\0\0\0")) + chunk(b"IEND", b""))


class ReleaseArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temporary = Path(tempfile.mkdtemp(prefix="localgemma-archive-fixture-"))
        self.archive = self.temporary / CHECK.ARCHIVE_NAME
        self.app = self.archive / "Products/Applications/LocalGemma.app"
        self.app.mkdir(parents=True)
        self.app_info = {
            "CFBundleIdentifier": "com.localgemma.prototype", "CFBundleExecutable": "LocalGemma",
            "CFBundleSupportedPlatforms": ["iPhoneOS"], "DTPlatformName": "iphoneos",
            "MinimumOSVersion": "17.0", "UIDeviceFamily": [1, 2],
            "CFBundleShortVersionString": "1.0", "CFBundleVersion": "2",
            "NSPhotoLibraryUsageDescription": "Choose a local wallpaper.",
        }
        for key in ["CFBundleIcons", "CFBundleIcons~ipad"]:
            self.app_info[key] = {"CFBundlePrimaryIcon": {"CFBundleIconName": "AppIcon", "CFBundleIconFiles": ["AppIcon60x60"]}}
        self.write_app_info()
        (self.app / "LocalGemma").write_bytes(struct.pack("<IIIIIIII", 0xfeedfacf, 0x0100000c, 0, 2, 0, 0, 0, 0))
        add_fixture_native_runtime(self.app, "LocalGemma")
        (self.app / "LocalGemma").chmod(0o755)
        (self.app / "Assets.car").write_bytes(b"fake compiled catalog for validator fixtures only")
        (self.app / "PrivacyInfo.xcprivacy").write_bytes(plistlib.dumps(EXPECTED_PRIVACY))
        (self.app / "AppIcon60x60@2x.png").write_bytes(png())
        self.archive_info = {
            "ArchiveVersion": 2, "Name": "LocalGemma", "SchemeName": "LocalGemma",
            "ApplicationProperties": {
                "ApplicationPath": "Applications/LocalGemma.app", "CFBundleIdentifier": "com.localgemma.prototype",
                "CFBundleShortVersionString": "1.0", "CFBundleVersion": "2", "Architectures": ["arm64"],
            },
        }
        self.write_archive_info()
        dsym = self.archive / "dSYMs/LocalGemma.app.dSYM/Contents"
        (dsym / "Resources/DWARF").mkdir(parents=True)
        (dsym / "Info.plist").write_bytes(plistlib.dumps({"CFBundlePackageType": "dSYM"}))
        (dsym / "Resources/DWARF/LocalGemma").write_bytes(b"fake symbol bytes; UUID logs are fixture inputs only")

    def tearDown(self):
        shutil.rmtree(self.temporary)

    def write_app_info(self):
        (self.app / "Info.plist").write_bytes(plistlib.dumps(self.app_info))

    def write_archive_info(self):
        (self.archive / "Info.plist").write_bytes(plistlib.dumps(self.archive_info))

    def delivery(self):
        logs = {}
        for name in ["executable", "dSYM"]:
            path = self.temporary / f"{name}-uuid.log"
            path.write_text(f"UUID: {UUID} (arm64) /fake/{name}\n", encoding="utf-8")
            logs[name] = {"path": path.name, "fingerprint": CHECK.fingerprint(path)}
        name = f"LocalGemma-unsigned-1.0-2-{SHA[:7]}.xcarchive.zip"
        return {
            "schemaVersion": 1, "kind": "unsigned-ios-xcarchive", "status": "success", **CHECK.CLAIMS,
            "commitSha": SHA, "branch": "main", "runId": "42", "runAttempt": "1",
            "inputs": CHECK.validate_inputs(SHA, "1.0", "2"),
            "outcomes": {"source": "success", "archive": "success", "validation": "success"},
            "archive": CHECK.validate_archive(self.archive, "1.0", "2"),
            "uuidEvidence": logs,
            "symbols": CHECK.validate_uuid_pair(f"UUID: {UUID} (arm64) /fake/app\n", f"UUID: {UUID} (arm64) /fake/symbols\n"),
            "package": {"path": name, "fingerprint": CHECK.package_archive(self.archive, self.temporary / name)},
        }

    def test_accepts_current_identity_version_and_increased_build(self):
        inputs = CHECK.validate_inputs(SHA, "1.0", "2", "1.0", "1")
        self.assertEqual(inputs["marketingVersion"], "1.0")
        self.assertEqual(inputs["buildNumber"], "2")
        self.assertEqual(CHECK.validate_inputs(SHA, "1.0.1", "3", "1.0", "2")["buildNumber"], "3")

    def test_rejects_invalid_sha_version_and_build_inputs(self):
        for sha in ["", "a" * 39, "A" * 40, "g" * 40, "$(touch injected)"]:
            with self.subTest(sha=sha), self.assertRaises(ValueError):
                CHECK.validate_inputs(sha, "1.0", "2")
        for version in ["1", "01.0", "1.0-beta", "1.0.0.0", "../1.0", "1.0;echo x", "1." + "0" * 20]:
            with self.subTest(version=version), self.assertRaises(ValueError):
                CHECK.validate_inputs(SHA, version, "2")
        for build in ["", "0", "01", "-1", "1.1", "2147483648", "2\n", "2;echo x"]:
            with self.subTest(build=build), self.assertRaises(ValueError):
                CHECK.validate_inputs(SHA, "1.0", build)

    def test_rejects_downgraded_version_or_nonincrementing_build(self):
        for version, build in [("0.9", "2"), ("1.0", "1"), ("1.0", "2")]:
            with self.subTest(version=version, build=build), self.assertRaises(ValueError):
                CHECK.validate_inputs(SHA, version, build, "1.0", "2")

    def test_rejects_unsafe_relative_paths_and_internal_links(self):
        for path in ["../escape", "/absolute", "a/../b", "a//b", "a/./b", "a\\b", "a\0b", ""]:
            with self.subTest(path=path), self.assertRaises(ValueError):
                CHECK.safe_path(self.temporary, path)
        link = self.temporary / "linked"
        link.symlink_to(self.app, target_is_directory=True)
        with self.assertRaises(ValueError):
            CHECK.safe_path(self.temporary, "linked/Info.plist")
        self.assertEqual(CHECK.safe_path(self.temporary, "LocalGemma.xcarchive/Info.plist"), self.archive / "Info.plist")

    def test_requires_real_archive_properties_app_and_dsym_structure(self):
        with self.assertRaises(ValueError):
            CHECK.validate_archive(self.app, "1.0", "2")
        self.archive_info.pop("ApplicationProperties")
        self.write_archive_info()
        with self.assertRaisesRegex(ValueError, "ApplicationProperties"):
            CHECK.validate_archive(self.archive, "1.0", "2")
        self.archive_info["ApplicationProperties"] = {
            "ApplicationPath": "Applications/LocalGemma.app", "CFBundleIdentifier": "com.localgemma.prototype",
            "CFBundleShortVersionString": "1.0", "CFBundleVersion": "2", "Architectures": ["arm64"],
        }
        self.write_archive_info()
        missing = self.app.with_name("Missing.app")
        self.app.rename(missing)
        with self.assertRaisesRegex(ValueError, "existing .app"):
            CHECK.validate_archive(self.archive, "1.0", "2")
        missing.rename(self.app)
        dwarf = self.archive / "dSYMs/LocalGemma.app.dSYM/Contents/Resources/DWARF/LocalGemma"
        dwarf.write_bytes(b"")
        with self.assertRaisesRegex(ValueError, "Empty evidence"):
            CHECK.validate_archive(self.archive, "1.0", "2")

    def test_rejects_archive_path_injection_wrong_version_and_simulator(self):
        self.archive_info["ApplicationProperties"]["ApplicationPath"] = "../LocalGemma.app"
        self.write_archive_info()
        with self.assertRaises(ValueError):
            CHECK.validate_archive(self.archive, "1.0", "2")
        self.archive_info["ApplicationProperties"]["ApplicationPath"] = "Applications/LocalGemma.app"
        self.write_archive_info()
        with self.assertRaisesRegex(ValueError, "version/build"):
            CHECK.validate_archive(self.archive, "1.0", "3")
        self.app_info["CFBundleSupportedPlatforms"] = ["iPhoneSimulator"]
        self.write_app_info()
        with self.assertRaisesRegex(ValueError, "device build"):
            CHECK.validate_archive(self.archive, "1.0", "2")

    def test_delivery_fixture_verifies_all_files_symbols_and_unsigned_claims(self):
        manifest = self.delivery()
        CHECK.validate_delivery(self.temporary, manifest)
        self.assertTrue(all(manifest[key] is False for key in CHECK.CLAIMS))
        with zipfile.ZipFile(self.temporary / manifest["package"]["path"]) as bundle:
            executable = bundle.getinfo("LocalGemma.xcarchive/Products/Applications/LocalGemma.app/LocalGemma")
            self.assertEqual(stat.S_IMODE(executable.external_attr >> 16), 0o755)
        for claim in CHECK.CLAIMS:
            changed = copy.deepcopy(manifest)
            changed[claim] = True
            with self.subTest(claim=claim), self.assertRaisesRegex(ValueError, "cannot claim"):
                CHECK.validate_delivery(self.temporary, changed)

    def test_rejects_modified_archive_file_evidence(self):
        manifest = self.delivery()
        (self.app / "Assets.car").write_bytes(b"tampered compiled fixture resources")
        with self.assertRaisesRegex(ValueError, "evidence changed"):
            CHECK.validate_delivery(self.temporary, manifest)

    def test_rejects_modified_zip_and_original_symbol_logs(self):
        manifest = self.delivery()
        package = self.temporary / manifest["package"]["path"]
        original = package.read_bytes()
        package.write_bytes(original + b"tampered ZIP")
        with self.assertRaisesRegex(ValueError, "ZIP digest"):
            CHECK.validate_delivery(self.temporary, manifest)
        package.write_bytes(original)
        log = self.temporary / manifest["uuidEvidence"]["dSYM"]["path"]
        log.write_text("tampered evidence\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "UUID log evidence changed"):
            CHECK.validate_delivery(self.temporary, manifest)

    def test_rejects_zip_symlink_or_lost_executable_mode_even_with_updated_digest(self):
        for mode in [stat.S_IFLNK | 0o755, stat.S_IFREG | 0o644]:
            manifest = self.delivery()
            path = self.temporary / manifest["package"]["path"]
            with zipfile.ZipFile(path) as bundle:
                entries = [(entry, bundle.read(entry)) for entry in bundle.infolist()]
            with zipfile.ZipFile(path, "w") as bundle:
                for entry, data in entries:
                    if entry.filename.endswith(".app/LocalGemma"):
                        entry.external_attr = mode << 16
                    bundle.writestr(entry, data)
            manifest["package"]["fingerprint"] = CHECK.fingerprint(path)
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                CHECK.validate_delivery(self.temporary, manifest)

    def test_rejects_missing_mismatched_or_duplicated_arm64_symbol_uuid(self):
        app = f"UUID: {UUID} (arm64) /fake/app\n"
        for dsym in ["", app.replace("arm64", "x86_64"), app + app, app.replace(UUID, "F" * 8 + "-1234-1234-1234-123456789ABC")]:
            with self.subTest(dsym=dsym), self.assertRaises(ValueError):
                CHECK.validate_uuid_pair(app, dsym)

    def test_failure_report_preserves_failure_and_cannot_claim_delivery(self):
        original = {"status": "success", "commitSha": SHA, "outcomes": {"source": "success"},
                    "signingVerified": True, "appStoreReady": True, "runtimeVerified": True}
        report = CHECK.write_failure_report(self.temporary, original, "archive", RuntimeError("archive command failed"))
        self.assertEqual(report["status"], "failure")
        self.assertEqual(report["failureStage"], "archive")
        self.assertEqual(report["outcomes"], {"source": "success", "archive": "failure"})
        self.assertTrue(all(report[key] is False for key in CHECK.CLAIMS))
        self.assertEqual(json.loads((self.temporary / "manifest.json").read_text()), report)
        self.assertEqual(json.loads((self.temporary / "failure.json").read_text()), report)
        with self.assertRaises(ValueError):
            CHECK.validate_delivery(self.temporary, report)

    def test_local_cloud_guard_rejects_before_commands_or_output(self):
        with patch.object(CHECK.os, "environ", {}), patch.object(CHECK, "command") as command:
            with self.assertRaisesRegex(ValueError, "local execution is forbidden"):
                CHECK.main()
            command.assert_not_called()

    def test_workflow_is_manual_only_and_does_not_interpolate_inputs_into_shell(self):
        workflow = (CHECK.ROOT / ".github/workflows/release-archive.yml").read_text()
        self.assertIn("workflow_dispatch:", workflow)
        self.assertNotIn("\n  push:", workflow)
        self.assertNotIn("\n  pull_request:", workflow)
        self.assertIn("runs-on: macos-latest", workflow)
        self.assertIn("if-no-files-found: error", workflow)
        self.assertIn("EXPECTED_SHA: ${{ inputs.expected_sha }}", workflow)
        self.assertIn("run: python3 Tools/cloud_release_archive.py", workflow)
        self.assertNotIn("run: python3 Tools/cloud_release_archive.py ${{", workflow)


if __name__ == "__main__":
    unittest.main()
