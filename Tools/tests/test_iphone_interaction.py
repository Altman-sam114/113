import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from iphone_interaction_evidence import HELP_SECTIONS, TESTS, expected_captures, validate_capture, validate_results


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
            self.assertEqual(len(expected_captures(category)), 15)
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
        summary = {"result": "Passed", "totalTestCount": 5, "passedTests": 5,
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

    def help_capture(self, category="large", stage="help-bottom"):
        document = self.capture(category, stage)
        document["actions"] = ["tap:session-bar-action-createSession", "tap:composer-input-field",
                               "type:local-draft-without-send", "tap:composer-keyboard-done",
                               "tap:workspace-tab-settings", "tap:settings-help-open"]
        document["frames"] = {
            "settings-help-close": {"x": 309, "y": 55, "width": 48, "height": 48},
            "settings-help-repository": {"x": 18, "y": 550, "width": 339, "height": 48},
        }
        document["helpFlow"] = {"originalWorkspace": "chat", "initialDraft": "Keep this draft", "sections": []}
        if stage == "help-open":
            return document
        for identifier, title, prefix, required in HELP_SECTIONS:
            document["actions"] += ["scroll:help-content-up", f"read:help-{identifier}"]
            document["helpFlow"]["sections"].append({
                "id": identifier, "title": title, "text": prefix + " " + " ".join(required),
                "frame": {"x": 18, "y": 200, "width": 339, "height": 160},
                "viewport": {"x": 0, "y": 140, "width": 375, "height": 500},
            })
        document["completion"] = {
            "source": "post-dismiss-live-XCUI-snapshot", "settingsRestoredAfterClose": True,
            "actions": document["actions"] + ["tap:settings-help-close", "tap:workspace-tab-chat"],
            "workspace": "chat", "workspaceSelected": True, "draft": "Keep this draft",
            "keyboardVisible": True, "helpVisible": False,
            "composerFrame": {"x": 18, "y": 350, "width": 270, "height": 48},
            "keyboardFrame": {"x": 0, "y": 420, "width": 375, "height": 247},
        }
        return document

    def test_help_adds_evidence_without_replacing_original_tests_or_screens(self):
        for category in TESTS:
            for stage in ("help-open", "help-bottom"):
                validate_capture(self.help_capture(category, stage), category, (750, 1334))
            expected = expected_captures(category)
            self.assertEqual(len(TESTS[category]), 5)
            self.assertEqual(len(expected), 15)
            for theme in ("light", "dark"):
                for stage in ("open", "expanded", "managed-models", "returned-chat"):
                    self.assertIn(f"interaction-{theme}-{category}-{stage}", expected)
            for stage in ("draft-keyboard", "draft-sheet", "draft-returned", "help-open", "help-bottom"):
                self.assertIn(f"interaction-dark-{category}-{stage}", expected)

    def test_native_license_review_requires_real_controls_and_cancel_without_acceptance(self):
        document = self.capture(stage="license-open")
        document.update(selectedModel="Gemma 3 1B artifact missing", licenseReviewVisible=True,
                        actions=["tap:workspace-tab-models", "tap:model-selector-picker", "tap:native-model-choice",
                                 "tap:model-artifact-action-importFiles"], frames={
                            "model-license-cancel": {"x": 290, "y": 50, "width": 60, "height": 48},
                            "model-license-confirm-import": {"x": 18, "y": 550, "width": 339, "height": 64}})
        validate_capture(document, "large", (750, 1334))
        for field, value in [("selectedModel", "Gemma 3 1B artifact verified"), ("licenseReviewVisible", False)]:
            with self.assertRaises(ValueError):
                validate_capture(dict(document, **{field: value}), "large", (750, 1334))
        with self.assertRaises(ValueError):
            validate_capture(dict(document, actions=document["actions"] + ["tap:model-license-confirm-import"]), "large", (750, 1334))
        document.update(stage="license-cancelled", name="interaction-dark-large-license-cancelled",
                        licenseReviewVisible=False, frames={
                            "model-selector-picker": {"x": 18, "y": 160, "width": 339, "height": 60}})
        with self.assertRaises(ValueError):
            validate_capture(document, "large", (750, 1334))
        document["actions"].append("tap:model-license-cancel")
        validate_capture(document, "large", (750, 1334))

    def test_help_requires_real_ordered_production_navigation_and_all_complete_sections(self):
        original = self.help_capture()
        for action in ("tap:composer-keyboard-done", "tap:workspace-tab-settings", "tap:settings-help-open",
                       "read:help-storage", "read:help-support"):
            bad = copy.deepcopy(original)
            bad["actions"].remove(action)
            with self.assertRaises(ValueError):
                validate_capture(bad, "large", (750, 1334))
        bad = copy.deepcopy(original)
        bad["actions"][4:6] = reversed(bad["actions"][4:6])
        with self.assertRaises(ValueError):
            validate_capture(bad, "large", (750, 1334))
        for key, value in (("id", "placeholder"), ("title", "截断标题"), ("text", "摘要代替完整正文")):
            bad = copy.deepcopy(original)
            bad["helpFlow"]["sections"][2][key] = value
            with self.assertRaises(ValueError):
                validate_capture(bad, "large", (750, 1334))
        bad = copy.deepcopy(original)
        bad["helpFlow"]["sections"].pop()
        with self.assertRaises(ValueError):
            validate_capture(bad, "large", (750, 1334))

    def test_help_keyboard_dismissal_must_follow_typing_even_when_an_earlier_dismissal_exists(self):
        document = self.help_capture(stage="help-open")
        document["actions"].insert(1, "tap:composer-keyboard-done")
        validate_capture(document, "large", (750, 1334))
        document["actions"].remove("type:local-draft-without-send")
        document["actions"].append("type:local-draft-without-send")
        with self.assertRaises(ValueError):
            validate_capture(document, "large", (750, 1334))
        document = self.help_capture(stage="help-open")
        document["actions"].remove("tap:composer-keyboard-done")
        document["actions"].insert(1, "tap:composer-keyboard-done")
        with self.assertRaises(ValueError):
            validate_capture(document, "large", (750, 1334))

    def test_help_readonly_text_and_actions_need_actual_visible_geometry(self):
        for identifier in ("settings-help-close", "settings-help-repository"):
            for key, value in (("width", 43), ("height", 43), ("y", 650), ("x", float("nan"))):
                bad = self.help_capture()
                bad["frames"][identifier][key] = value
                with self.assertRaises(ValueError):
                    validate_capture(bad, "large", (750, 1334))
        for key, value in (("y", 650), ("height", 0), ("x", float("inf")), ("width", True)):
            bad = self.help_capture()
            bad["helpFlow"]["sections"][3]["frame"][key] = value
            with self.assertRaises(ValueError):
                validate_capture(bad, "large", (750, 1334))
        bad = self.help_capture()
        bad["helpFlow"]["sections"][3]["frame"]["height"] = 2_000
        bad["helpFlow"]["sections"][3]["frame"]["y"] = -500
        validate_capture(bad, "large", (750, 1334))

    def test_help_completion_must_be_later_real_close_and_original_chat_restore(self):
        for key, value in (("source", "host-fixture"), ("settingsRestoredAfterClose", False),
                           ("workspace", "models"), ("workspaceSelected", False), ("draft", "Keep this"),
                           ("keyboardVisible", False), ("helpVisible", True), ("actions", [])):
            bad = self.help_capture()
            bad["completion"][key] = value
            with self.assertRaises(ValueError):
                validate_capture(bad, "large", (750, 1334))
        bad = self.help_capture()
        bad["completion"]["actions"][-2:] = reversed(bad["completion"]["actions"][-2:])
        with self.assertRaises(ValueError):
            validate_capture(bad, "large", (750, 1334))
        bad = self.help_capture()
        bad["completion"]["composerFrame"]["y"] = 410
        with self.assertRaises(ValueError):
            validate_capture(bad, "large", (750, 1334))
        bad = self.help_capture()
        bad["actions"].append("tap:settings-help-repository")
        with self.assertRaises(ValueError):
            validate_capture(bad, "large", (750, 1334))


if __name__ == "__main__":
    unittest.main()
