import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from export_workbench_evidence import validate_summary_capture


class SummaryEvidenceTests(unittest.TestCase):
    def fixture(self, context="missing-large", theme="dark"):
        size, availability, deployment, generating, expanded, marker, state, detail, width, height = {
            "missing-large": ("large", "missing", "stopped", False, False, "尚未导入", "尚未导入", "", 320, 640),
            "staged-generating": ("large", "staged", "stopped", True, False, "正在生成", "待校验", "", 320, 640),
            "verified-accessibility3": ("accessibility3", "verified", "running", False, False, "模拟预览", "已校验", "", 320, 640),
            "details-large": ("large", "missing", "stopped", False, True, "参考指标", "尚未导入", "36.0", 390, 844),
        }[context]
        return {
            "context": context, "theme": theme, "workspace": "model-summary", "dynamicTypeSize": size,
            "availability": availability, "deploymentState": deployment, "isGenerating": generating,
            "isSimulated": True, "detailsExpanded": expanded, "usesProductionSummaryPage": True,
            "stateSource": "explicit-presentation-fixture", "requiredTextMarker": marker,
            "requiredStateMarker": state, "requiredDetailMarker": detail, "requiredBodyMarker": "管理模型",
            "recognizedText": f"{marker} {state} 管理模型 {detail}", "viewportWidth": width, "viewportHeight": height,
        }

    def validate(self, capture, width=None, height=None, name=None):
        validate_summary_capture(
            capture, capture["viewportWidth"] if width is None else width,
            capture["viewportHeight"] if height is None else height,
            name or f"workbench-summary-{capture['theme']}-{capture['context']}",
        )

    def test_all_eight_production_page_states(self):
        for context in ["missing-large", "staged-generating", "verified-accessibility3", "details-large"]:
            for theme in ["light", "dark"]:
                self.validate(self.fixture(context, theme))

    def test_state_and_fixture_source_cannot_be_promoted(self):
        for key, value in [
            ("context", "unknown"), ("theme", "unknown"), ("workspace", "models"),
            ("availability", "verified"), ("deploymentState", "running"), ("isGenerating", True),
            ("detailsExpanded", True), ("isGenerating", 0), ("detailsExpanded", 0),
            ("isSimulated", False), ("usesProductionSummaryPage", False),
            ("stateSource", "real-runtime"), ("stateSource", "verified-local-files"),
            ("dynamicTypeSize", "accessibility5"), ("requiredTextMarker", "运行摘要"),
        ]:
            capture = self.fixture()
            capture[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.validate(capture)

    def test_body_management_and_expanded_metrics_must_be_visible(self):
        for context in ["missing-large", "staged-generating", "verified-accessibility3", "details-large"]:
            capture = self.fixture(context)
            capture["recognizedText"] = "运行摘要 Gemma 1.5B 管理模型"
            with self.assertRaises(RuntimeError):
                self.validate(capture)
            capture = self.fixture(context)
            capture["recognizedText"] = capture["recognizedText"].replace("管理模型", "")
            with self.assertRaises(RuntimeError):
                self.validate(capture)
        capture = self.fixture("details-large")
        capture["recognizedText"] = "参考指标 尚未导入 管理模型"
        with self.assertRaises(RuntimeError):
            self.validate(capture)

    def test_viewports_names_and_exact_traditional_glyphs(self):
        with self.assertRaises(RuntimeError):
            self.validate(self.fixture(), 390, 844)
        with self.assertRaises(RuntimeError):
            self.validate(self.fixture("details-large"), 320, 640)
        with self.assertRaises(RuntimeError):
            self.validate(self.fixture(), name="other-screenshot")
        capture = self.fixture("verified-accessibility3")
        capture["recognizedText"] = "模擬預覽 已校驗 管理模型"
        self.validate(capture)
        capture["recognizedText"] = "模擬預覽 待校驗 管理模型"
        with self.assertRaises(RuntimeError):
            self.validate(capture)


if __name__ == "__main__":
    unittest.main()
