"""Small file fixtures only; no UI, Swift, or simulator execution."""
import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest


SPEC = importlib.util.spec_from_file_location(
    "capture_preflight", Path(__file__).parents[1] / "workbench_capture_preflight.py"
)
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class CapturePreflightTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="localgemma-capture-fixture-")
        self.addCleanup(self.temporary.cleanup)
        self.app = Path(self.temporary.name) / "Fixture.app"
        self.app.mkdir()
        self.write_info("Fixture")
        (self.app / "Fixture").write_bytes(b"fixture binary presence, not a real app")

    def write_info(self, name):
        (self.app / "Info.plist").write_bytes(plistlib.dumps({"CFBundleExecutable": name}))

    def test_accepts_complete_successful_build_input(self):
        CHECK.validate_capture_input(self.app, "success")

    def test_rejects_failed_build_even_if_partial_bundle_exists(self):
        with self.assertRaisesRegex(RuntimeError, "successful build"):
            CHECK.validate_capture_input(self.app, "failure")

    def test_rejects_missing_or_empty_executable(self):
        (self.app / "Fixture").write_bytes(b"")
        with self.assertRaisesRegex(RuntimeError, "Missing or empty"):
            CHECK.validate_capture_input(self.app, "success")
        with self.assertRaisesRegex(RuntimeError, "Missing or empty"):
            self.write_info("Absent")
            CHECK.validate_capture_input(self.app, "success")

    def test_rejects_missing_info_and_non_leaf_executable(self):
        self.write_info("../Fixture")
        with self.assertRaisesRegex(RuntimeError, "invalid executable"):
            CHECK.validate_capture_input(self.app, "success")
        with self.assertRaisesRegex(RuntimeError, "Missing built app Info"):
            CHECK.validate_capture_input(self.app / "Absent.app", "success")


if __name__ == "__main__":
    unittest.main()
