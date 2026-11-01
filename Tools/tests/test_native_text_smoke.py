import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_native_text_smoke import FIXTURE_BYTES, validate_draft_fixture


class NativeTextFixtureTests(unittest.TestCase):
    def test_only_explicit_encrypted_unpublished_fixture_is_accepted(self):
        tag = "agentx-native-fixture-20261101"
        asset = {"name": "native-fixture.gguf.enc", "id": 123, "size": FIXTURE_BYTES + 32}
        valid = {"draft": True, "tag_name": tag, "assets": [asset]}
        self.assertEqual(validate_draft_fixture(valid, tag), 123)
        for invalid in [dict(valid, draft=False), dict(valid, tag_name="unrelated"),
                        dict(valid, assets=[]), dict(valid, assets=[asset, asset]),
                        dict(valid, assets=[dict(asset, name="model.gguf")]),
                        dict(valid, assets=[dict(asset, size=FIXTURE_BYTES)]),
                        dict(valid, assets=[dict(asset, id="123")])]:
            with self.assertRaises(ValueError):
                validate_draft_fixture(invalid, tag)
        for invalid in ["../../releases", "published-release", "agentx-native-fixture-;echo key"]:
            with self.assertRaises(ValueError):
                validate_draft_fixture(valid, invalid)


if __name__ == "__main__":
    unittest.main()
