import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_native_text_smoke import FIXTURE_BYTES, find_draft_fixture, validate_draft_fixture


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

    def test_authenticated_listing_cannot_substitute_an_unrelated_or_published_release(self):
        tag = "agentx-native-fixture-20261101"
        draft = {"draft": True, "tag_name": tag, "assets": [
            {"name": "native-fixture.gguf.enc", "id": 456, "size": FIXTURE_BYTES + 32}]}
        self.assertEqual(find_draft_fixture([dict(draft, tag_name="other"), draft], tag), 456)
        for releases in [[], [draft, draft], [dict(draft, draft=False)], {"release": draft}]:
            with self.assertRaises(ValueError):
                find_draft_fixture(releases, tag)


if __name__ == "__main__":
    unittest.main()
