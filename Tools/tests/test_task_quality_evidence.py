import copy
import hashlib
import json
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from task_quality_evidence import validate_task_quality_report
import test_native_text_smoke as native_fixture_tests

CASES = Path(__file__).resolve().parents[1] / "fixtures/task_quality_270m.json"


class TaskQualityEvidenceTests(unittest.TestCase):
    def sample(self):
        probe = native_fixture_tests.NativeTextFixtureTests().production_report()
        definition = json.loads(CASES.read_text())
        results = []
        for task in definition["cases"]:
            text = task.get("acceptedExact", [" ".join(group[0] for group in task["requiredConcepts"])])[0]
            results.append({"id": task["id"], "templateID": task["templateID"] or "",
                            "prompt": task["expectedTemplatePrompt"] + task["input"], "text": text,
                            "outputTokens": 20, "tokensPerSecond": 15.0, "elapsedSeconds": 2.0,
                            "simulated": False, "backend": "llamaCpp", "runtimeSucceeded": True,
                            "error": "", "runtimeStatusMessages": []})
        probe["taskQuality"] = {"schemaVersion": 1, "status": "collected",
            "source": "headless-production-everyday-task-quality", "modelID": probe["productionFlow"]["modelID"],
            "modelSHA256": probe["modelSHA256"], "casesSHA256": hashlib.sha256(CASES.read_bytes()).hexdigest(),
            "caseCount": 10, "contextLength": 4096, "maximumOutputTokens": 512,
            "sourceModelUnmodified": True, "manualReviewRequired": True, "generalTaskQualityVerified": False,
            "UIFilePickerExercised": False, "deviceMemoryOrMetalVerified": False, "cases": results}
        return probe

    def validate(self, report):
        return validate_task_quality_report(report, CASES, "a" * 40, "123", "1")

    def test_complete_fact_matches_still_require_human_semantic_review(self):
        result = self.validate(self.sample())
        self.assertEqual(result["automaticFailureCount"], 0)
        self.assertTrue(result["manualReviewRequired"])
        self.assertFalse(result["generalTaskQualityVerified"])
        self.assertTrue(all(c["humanSemanticReview"] == "required" for c in result["checks"]))

    def test_missing_duplicate_or_reordered_cases_cannot_pass(self):
        for mutation in [lambda rows: rows.pop(), lambda rows: rows.append(rows[0]),
                         lambda rows: rows.reverse(), lambda rows: rows.__setitem__(1, rows[0])]:
            report = self.sample();mutation(report["taskQuality"]["cases"])
            with self.assertRaises(ValueError):self.validate(report)
        report = self.sample();del report["taskQuality"]
        with self.assertRaises(ValueError):self.validate(report)

    def test_wrong_source_model_fixture_or_claimed_quality_is_rejected(self):
        for field, value in [("source", "simulated"), ("modelID", "other"), ("casesSHA256", "0" * 64),
                             ("manualReviewRequired", False), ("generalTaskQualityVerified", True),
                             ("UIFilePickerExercised", True), ("deviceMemoryOrMetalVerified", True),
                             ("caseCount", True), ("maximumOutputTokens", 64)]:
            report = self.sample();report["taskQuality"][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):self.validate(report)
        report = self.sample();report["runId"] = "other"
        with self.assertRaises(ValueError):self.validate(report)

    def test_template_and_input_cannot_be_replaced_by_an_easier_prompt(self):
        for field, value in [("templateID", ""), ("prompt", "Reply with ORCHID only")]:
            report = self.sample();report["taskQuality"]["cases"][0][field] = value
            with self.assertRaises(ValueError):self.validate(report)

    def test_simulation_and_invalid_metrics_cannot_look_like_real_answers(self):
        for field, value in [("simulated", True), ("backend", "coreMLANE"), ("outputTokens", True),
                             ("outputTokens", 513), ("outputTokens", 0), ("tokensPerSecond", float("nan")),
                             ("tokensPerSecond", 0), ("elapsedSeconds", float("inf")), ("error", "hidden failure")]:
            report = self.sample();report["taskQuality"]["cases"][0][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):self.validate(report)

    def test_real_missing_facts_fail_checks_without_rewriting_original_answers(self):
        report = self.sample();report["taskQuality"]["cases"][0]["text"] = "Hello"
        before = copy.deepcopy(report)
        result = self.validate(report)
        self.assertEqual(report, before)
        self.assertEqual(result["automaticFailureCount"], 1)
        self.assertTrue(result["checks"][0]["missingConcepts"])
        self.assertFalse(result["generalTaskQualityVerified"])

    def test_actual_runtime_failure_is_preserved_and_fails_quality(self):
        report = self.sample();record = report["taskQuality"]["cases"][0]
        record.update(runtimeSucceeded=False, error="actual allocation failure", text="",
                      outputTokens=0, tokensPerSecond=0, simulated=True)
        result = self.validate(report)
        self.assertFalse(result["checks"][0]["runtimeSucceeded"])
        self.assertEqual(result["automaticFailureCount"], 1)

    def test_exact_instructions_and_fact_words_do_not_prove_semantics(self):
        report = self.sample();report["taskQuality"]["cases"][-1]["text"] = "The answer is 5."
        result = self.validate(report)
        self.assertEqual(result["automaticFailureCount"], 1)
        self.assertFalse(result["checks"][-1]["exactInstructionPassed"])
        # The mock answers are only fact words, not valid summaries or translations.
        # A green phrase check must therefore never publish semantic acceptance.
        self.assertFalse(self.validate(self.sample())["generalTaskQualityVerified"])

if __name__ == "__main__":unittest.main()
