"""Synthetic schema fixtures; these answers never establish actual model quality."""
import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_sampling_diagnostic import (
    CASES_SHA256, EXPERIMENTAL_CREATION, FIXTURE_BYTES, FIXTURE_SHA256, PROFILE_IDS,
    PROFILES_SHA256, ROOT, SAMPLER_CREATION, diagnostic_source, load_definitions, validate_reports,
)

CASES = (ROOT / "Tools/fixtures/task_quality_270m.json").read_bytes()
PROFILES = (ROOT / "Tools/fixtures/sampling_profiles_270m.json").read_bytes()


class NativeSamplingDiagnosticTests(unittest.TestCase):
    def sample(self):
        reports = []
        for identifier in PROFILE_IDS:
            records = []
            for task in json.loads(CASES)["cases"]:
                text = task.get("acceptedExact", [" ".join(g[0] for g in task["requiredConcepts"])])[0]
                records.append({"id": task["id"], "templateID": task["templateID"] or "",
                    "prompt": task["expectedTemplatePrompt"] + task["input"], "text": text, "error": "",
                    "runtimeSucceeded": True, "backend": "llamaCpp", "simulated": False,
                    "promptTokens": 60, "outputTokens": 20, "tokensPerSecond": 10.0,
                    "loadSeconds": 1.0, "prefillSeconds": 1.0, "generationSeconds": 1.0,
                    "elapsedSeconds": 3.0, "finishReason": "endOfGeneration"})
            reports.append({"schemaVersion": 1, "status": "collected",
                "source": "cloud-Catalyst-isolated-sampling-diagnostic", "profileID": identifier,
                "commitSha": "a" * 40, "runId": "123", "runAttempt": "1",
                "modelSHA256": FIXTURE_SHA256, "modelBytes": FIXTURE_BYTES,
                "casesSHA256": CASES_SHA256, "profilesSHA256": PROFILES_SHA256,
                "contextLength": 4096, "maximumOutputTokens": 512,
                "productionDefaultChanged": False, "productionStateFlowVerified": False,
                "deviceMemoryOrMetalVerified": False, "generalTaskQualityVerified": False,
                "manualReviewRequired": True, "cases": records})
        return reports

    def validate(self, reports):
        return validate_reports(reports, CASES, PROFILES, "a" * 40, "123", "1")

    def test_complete_fact_fixtures_never_claim_production_or_semantic_acceptance(self):
        result = self.validate(self.sample())
        self.assertEqual(result["caseCount"], 40)
        self.assertTrue(result["allSampledAutomaticChecksPassed"])
        self.assertTrue(result["manualReviewRequired"])
        for key in ["productionDefaultChanged", "productionQualityGateReplaced", "generalTaskQualityVerified"]:
            self.assertFalse(result[key])

    def test_missing_duplicate_reordered_profile_or_case_is_rejected(self):
        for mutate in [lambda rows: rows.pop(), lambda rows: rows.reverse(),
                       lambda rows: rows.__setitem__(1, rows[0])]:
            reports = self.sample()
            mutate(reports)
            with self.assertRaises(ValueError): self.validate(reports)
            reports = self.sample()
            mutate(reports[2]["cases"])
            with self.assertRaises(ValueError): self.validate(reports)

    def test_frozen_prompt_seed_criteria_and_source_cannot_drift(self):
        for data, is_profile in [(CASES, False), (PROFILES, True)]:
            changed = json.loads(data)
            if is_profile:
                changed["profiles"][1]["seed"] = 43
            else:
                changed["cases"][0]["requiredConcepts"] = []
            with self.assertRaises(ValueError):
                load_definitions(CASES if is_profile else json.dumps(changed).encode(),
                                 json.dumps(changed).encode() if is_profile else PROFILES)
        reports = self.sample()
        reports[1]["cases"][0]["prompt"] = "An easier prompt"
        with self.assertRaises(ValueError): self.validate(reports)
        original = (ROOT / "LocalGemma/LlamaTextRuntime.swift").read_bytes()
        modified = diagnostic_source(original)
        self.assertEqual(modified.replace(EXPERIMENTAL_CREATION.encode(), SAMPLER_CREATION.encode()), original)
        self.assertEqual(modified.count(EXPERIMENTAL_CREATION.encode()), 1)
        with self.assertRaises(ValueError): diagnostic_source(original + b"\n")

    def test_wrong_identity_or_claimed_production_quality_is_rejected(self):
        for field, value in [("schemaVersion", True), ("source", "production"), ("runId", "other"),
                ("runAttempt", "2"), ("commitSha", "b" * 40), ("modelSHA256", "0" * 64),
                ("modelBytes", 1), ("casesSHA256", "0" * 64), ("profilesSHA256", "0" * 64),
                ("maximumOutputTokens", 32), ("manualReviewRequired", False),
                ("productionDefaultChanged", True), ("productionStateFlowVerified", True),
                ("generalTaskQualityVerified", True), ("deviceMemoryOrMetalVerified", True)]:
            reports = self.sample()
            reports[3][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.validate(reports)

    def test_simulation_invalid_metrics_and_hidden_errors_are_rejected(self):
        for field, value in [("simulated", True), ("backend", "simulated"), ("runtimeSucceeded", "true"),
                ("promptTokens", True), ("promptTokens", 3585), ("outputTokens", 513), ("outputTokens", 0),
                ("tokensPerSecond", float("nan")), ("generationSeconds", float("inf")),
                ("prefillSeconds", -1), ("elapsedSeconds", False), ("error", "hidden failure"),
                ("finishReason", "outputLimit")]:
            reports = self.sample()
            reports[1]["cases"][0][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.validate(reports)

    def test_no_seed_cherry_picking_and_original_failed_text_is_retained(self):
        reports = self.sample()
        reports[2]["cases"][-1]["text"] = "1"
        before = copy.deepcopy(reports)
        result = self.validate(reports)
        self.assertEqual(reports, before)
        self.assertFalse(result["allSampledAutomaticChecksPassed"])
        self.assertEqual([r["automaticFailureCount"] for r in result["profiles"]], [0, 0, 1, 0])
        self.assertEqual(result["status"], "candidate-automatic-checks-failed")

    def test_runtime_failure_and_truncation_remain_visible(self):
        reports = self.sample()
        record = reports[1]["cases"][0]
        record.update(runtimeSucceeded=False, text="partial", error="actual decode failure",
                      finishReason="error", outputTokens=0, promptTokens=0, tokensPerSecond=0)
        reports[3]["cases"][0].update(finishReason="outputLimit", outputTokens=512)
        result = self.validate(reports)
        self.assertFalse(result["allSampledAutomaticChecksPassed"])
        self.assertEqual(result["profiles"][1]["automaticFailureCount"], 1)
        self.assertEqual(result["profiles"][3]["outputLimitedCount"], 1)
        self.assertFalse(result["generalTaskQualityVerified"])


if __name__ == "__main__":
    unittest.main()
