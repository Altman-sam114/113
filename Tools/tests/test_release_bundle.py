"""Pure fixture/static checks; no app, compiler, or simulator is executed."""
import importlib.util
from pathlib import Path
import plistlib
import shutil
import struct
import tempfile
import unittest


SPEC = importlib.util.spec_from_file_location("release_bundle", Path(__file__).parents[1] / "verify_release_bundle.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class ReleaseBundleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = Path(tempfile.mkdtemp(prefix="localgemma-release-fixture-"))
        self.app = self.temporary / "Fixture.app"
        self.app.mkdir()
        self.info = dict(CFBundleIdentifier="com.localgemma.prototype", CFBundleExecutable="Fixture",
                         CFBundleSupportedPlatforms=["iPhoneOS"], DTPlatformName="iphoneos",
                         MinimumOSVersion="17.0", UIDeviceFamily=[1, 2],
                         CFBundleShortVersionString="1.0", CFBundleVersion="1",
                         NSPhotoLibraryUsageDescription="Choose a local wallpaper.")
        for key in ["CFBundleIcons", "CFBundleIcons~ipad"]:
            self.info[key] = {"CFBundlePrimaryIcon": {"CFBundleIconName": "AppIcon", "CFBundleIconFiles": ["AppIcon60x60"]}}
        self.write_info()
        (self.app / "Fixture").write_bytes(struct.pack("<IIIIIIII", 0xfeedfacf, 0x0100000c, 0, 2, 0, 0, 0, 0))
        (self.app / "Assets.car").write_bytes(b"fixture compiled resources")
        (self.app / "PrivacyInfo.xcprivacy").write_bytes(plistlib.dumps(CHECK.EXPECTED_PRIVACY))
        shutil.copyfile(CHECK.ROOT / "LocalGemma/Assets.xcassets/AppIcon.appiconset/AppIcon-120.png",
                        self.app / "AppIcon60x60@2x.png")

    def write_info(self):
        (self.app / "Info.plist").write_bytes(plistlib.dumps(self.info))

    def test_source_resources_have_all_opaque_slots(self):
        self.assertEqual(CHECK.validate_source(CHECK.ROOT)["iconSlotCount"], 28)

    def test_device_bundle_passes_without_claiming_signing(self):
        report = CHECK.validate_bundle(self.app)
        self.assertFalse(report["signingVerified"])
        self.assertEqual(report["architecture"], "arm64")

    def test_rejects_simulator_bundle(self):
        self.info["CFBundleSupportedPlatforms"] = ["iPhoneSimulator"]
        self.write_info()
        with self.assertRaisesRegex(ValueError, "device build"):
            CHECK.validate_bundle(self.app)

    def test_rejects_missing_ipad_icon_declaration(self):
        self.info.pop("CFBundleIcons~ipad")
        self.write_info()
        with self.assertRaisesRegex(ValueError, "compiled icon"):
            CHECK.validate_bundle(self.app)

    def test_rejects_changed_privacy_contract(self):
        (self.app / "PrivacyInfo.xcprivacy").write_bytes(plistlib.dumps({"NSPrivacyTracking": True}))
        with self.assertRaisesRegex(ValueError, "Privacy manifest"):
            CHECK.validate_bundle(self.app)

    def test_rejects_non_arm_executable(self):
        (self.app / "Fixture").write_bytes(struct.pack("<IIIIIIII", 0xfeedfacf, 0x01000007, 0, 2, 0, 0, 0, 0))
        with self.assertRaisesRegex(ValueError, "arm64"):
            CHECK.validate_bundle(self.app)

    def test_rejects_empty_compiled_assets(self):
        (self.app / "Assets.car").write_bytes(b"")
        with self.assertRaisesRegex(ValueError, "Empty resource"):
            CHECK.validate_bundle(self.app)

    def test_rejects_corrupt_icon(self):
        (self.app / "AppIcon60x60@2x.png").write_bytes(b"not a png")
        with self.assertRaisesRegex(ValueError, "Not a PNG"):
            CHECK.validate_bundle(self.app)


if __name__ == "__main__":
    unittest.main()
