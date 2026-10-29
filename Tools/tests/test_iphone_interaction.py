import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from iphone_interaction_evidence import TESTS, expected_captures, validate_capture, validate_results


class IPhoneInteractionEvidenceTests(unittest.TestCase):
    def capture(self, category="large", stage="open"):
        return {
            "schemaVersion": 1, "source": "public-XCUITest-production-app",
            "name": f"interaction-dark-{category}-{stage}", "theme": "dark",
            "dynamicTypeSize": category, "stage": stage,
            "systemContentSizeCategory": ("UICTContentSizeCategoryAccessibilityXXXL"
                                          if category == "accessibility5" else "UICTContentSizeCategoryL"),
            "screenWidth": 375, "screenHeight": 667,
            "realInferenceVerified": False, "signedDistributionVerified": False,
            "actions": ["tap:compact-model-summary"], "keyboardVisible": False, "draft": "",
            "frames": {
                "compact-model-summary-close": {"x": 310, "y": 340, "width": 44, "height": 44},
                "header-action-open-model-library": {"x": 18, "y": 580, "width": 339, "height": 48},
            },
        }

    def test_exact_original_small_phone_and_real_system_category_required(self):
        for category in TESTS:
            document = self.capture(category)
            validate_capture(document, category, (750, 1334))
            self.assertEqual(len(expected_captures(category)), 11)
            for key, value in (("source", "host-render"), ("screenWidth", 390),
                               ("realInferenceVerified", True), ("signedDistributionVerified", 0),
                               ("systemContentSizeCategory", "injected-font-size"), ("stage", "fixture")):
                bad = copy.deepcopy(document)
                bad[key] = value
                with self.assertRaises(ValueError):
                    validate_capture(bad, category, (750, 1334))
            with self.assertRaises(ValueError):
                validate_capture(document, category, (375, 667))

    def test_actual_action_history_and_unmodified_draft_required(self):
        initial = self.capture(stage="draft-keyboard")
        initial.update({"keyboardVisible": True, "draft": "Keep this draft", "actions": [
            "tap:session-bar-action-createSession", "tap:composer-input-field", "type:local-draft-without-send"]})
        validate_capture(initial, "large", (750, 1334))
        for action in initial["actions"]:
            bad = copy.deepcopy(initial)
            bad["actions"].remove(action)
            with self.assertRaises(ValueError):
                validate_capture(bad, "large", (750, 1334))
        document = self.capture(stage="draft-returned")
        document.update({"keyboardVisible": True, "draft": "Keep this draft"})
        document["actions"] += ["tap:header-action-open-model-library", "tap:workspace-tab-chat"]
        validate_capture(document, "large", (750, 1334))
        for key, value in (("actions", []), ("draft", "Keep this"), ("keyboardVisible", False)):
            bad = copy.deepcopy(document)
            bad[key] = value
            with self.assertRaises(ValueError):
                validate_capture(bad, "large", (750, 1334))
        expanded = self.capture(stage="expanded")
        with self.assertRaises(ValueError):
            validate_capture(expanded, "large", (750, 1334))
        expanded["actions"].append("tap:compact-model-runtime-details")
        validate_capture(expanded, "large", (750, 1334))

    def test_action_targets_must_remain_visible_and_finite(self):
        for field, value in (("width", 43), ("height", 43), ("y", 650),
                             ("x", -1), ("x", float("nan")), ("width", True)):
            bad = self.capture()
            bad["frames"]["compact-model-summary-close"][field] = value
            with self.assertRaises(ValueError):
                validate_capture(bad, "large", (750, 1334))

    def test_all_selected_tests_must_succeed_once_on_the_recorded_device(self):
        summary = {"result": "Passed", "totalTestCount": 3, "passedTests": 3,
                   "failedTests": 0, "skippedTests": 0, "expectedFailures": 0, "testFailures": []}
        for category, names in TESTS.items():
            tree = {"devices": [{"deviceId": "exact-udid"}], "testNodes": [
                {"name": name + "()", "nodeType": "Test Case", "result": "Passed"} for name in sorted(names)]}
            validate_results(summary, tree, category, "exact-udid")
            for key, value in (("failedTests", 1), ("skippedTests", 1), ("passedTests", 2)):
                bad = dict(summary, **{key: value})
                with self.assertRaises(ValueError):
                    validate_results(bad, tree, category, "exact-udid")
            with self.assertRaises(ValueError):
                validate_results(summary, tree, category, "another-udid")
            duplicate = copy.deepcopy(tree)
            duplicate["testNodes"][1] = duplicate["testNodes"][0]
            with self.assertRaises(ValueError):
                validate_results(summary, duplicate, category, "exact-udid")


if __name__ == "__main__":
    unittest.main()
