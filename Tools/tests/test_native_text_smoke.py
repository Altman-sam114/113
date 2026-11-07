import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_native_text_smoke import (FIXTURE_BYTES, FIXTURE_SHA256, PRODUCTION_MODEL_FILENAME,
                                   PRODUCTION_MODEL_ID, find_draft_fixture, validate_draft_fixture,
                                   validate_production_report)


class NativeTextFixtureTests(unittest.TestCase):
    def production_report(self):
        turn = {"text": "ORCHID\n", "outputTokens": 4, "tokensPerSecond": 12.0,
                "simulated": False, "backend": "llamaCpp"}
        flow = {
            "source": "headless-production-ModelCatalog-VerifiedLlamaRuntime-InferenceEngine",
            "modelID": PRODUCTION_MODEL_ID, "modelName": "Gemma 3 270M",
            "fileName": PRODUCTION_MODEL_FILENAME, "sha256": FIXTURE_SHA256,
            "turns": [dict(turn), dict(turn)], "reloadAfterStop": dict(turn), "reimportRecovery": dict(turn),
            "UIFilePickerExercised": False, "deviceMemoryOrMetalVerified": False,
        }
        for key in ["importedAndVerified", "backupExcluded", "unverifiedDraftPreserved", "exportPreservesFullHistory",
                    "stoppedAfterActualText", "lateEventsIsolated", "changedManagedFileRejected", "sourceUnmodified",
                    "fullContextRejectedWithoutTruncation"]:
            flow[key] = True
        return {"schemaVersion": 2, "status": "success",
                "source": "cloud-Catalyst-production-state-and-LlamaTextRuntime",
                "commitSha": "a" * 40, "runId": "123", "runAttempt": "1",
                "modelSHA256": FIXTURE_SHA256, "modelBytes": FIXTURE_BYTES,
                "fixtureOnly": False, "productionModelVerified": True,
                "deviceMemoryOrMetalVerified": False, "signedDistributionVerified": False,
                "productionFlow": flow}

    def test_only_full_pinned_production_state_evidence_can_verify_the_model(self):
        report = self.production_report()
        validate_production_report(report, "a" * 40, "123", "1")
        for field, value in [("source", "cloud-Catalyst-production-LlamaTextRuntime"),
                             ("productionFlow", {}), ("commitSha", "b" * 40), ("runAttempt", "2"),
                             ("fixtureOnly", True), ("productionModelVerified", 1),
                             ("deviceMemoryOrMetalVerified", True), ("signedDistributionVerified", True)]:
            bad = copy.deepcopy(report)
            bad[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                validate_production_report(bad, "a" * 40, "123", "1")

    def test_missing_import_stop_recovery_or_context_evidence_cannot_pass(self):
        report = self.production_report()
        for field in report["productionFlow"]:
            bad = copy.deepcopy(report)
            del bad["productionFlow"][field]
            with self.subTest(field=field), self.assertRaises(ValueError):
                validate_production_report(bad, "a" * 40, "123", "1")

    def test_simulation_or_invalid_metrics_cannot_replace_native_responses(self):
        for field, value in [("text", "simulated answer"), ("simulated", True), ("outputTokens", True),
                             ("outputTokens", 0), ("tokensPerSecond", float("nan")),
                             ("tokensPerSecond", -1), ("backend", "coreMLANE")]:
            for response in ["turns", "reloadAfterStop", "reimportRecovery"]:
                bad = self.production_report()
                turn = bad["productionFlow"][response]
                if response == "turns": turn = turn[1]
                turn[field] = value
                with self.subTest(field=field, response=response), self.assertRaises(ValueError):
                    validate_production_report(bad, "a" * 40, "123", "1")

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
