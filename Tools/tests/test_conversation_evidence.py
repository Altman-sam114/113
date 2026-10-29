import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from export_workbench_evidence import validate_conversation_capture


class ConversationEvidenceTests(unittest.TestCase):
    def fixture(self, context="completed-large", theme="dark"):
        size, marker, generating, copyable, source = {
            "completed-large": ("large", "对话和草稿", False, True, "default-simulation"),
            "completed-accessibility3": ("accessibility3", "对话和草稿", False, True, "default-simulation"),
            "generating-large": ("large", "正在生成", True, False, "whitespace-fixture"),
            "stopped-large": ("large", "已停止", False, False, "default-simulation"),
        }[context]
        return {
            "context": context, "theme": theme, "workspace": "chat", "dynamicTypeSize": size,
            "requiredTextMarker": marker, "recognizedText": marker,
            "usesInferenceEngineSend": True, "runtimeIsSimulated": True,
            "responseSource": source, "isGenerating": generating, "canCopyAssistant": copyable,
            "messageCount": 2, "viewportWidth": 320, "viewportHeight": 640,
        }

    def validate(self, capture, width=320, height=640, name=None):
        name = name or f"workbench-conversation-{capture['theme']}-{capture['context']}"
        validate_conversation_capture(capture, width, height, name)

    def test_all_eight_production_state_shapes(self):
        for context in ["completed-large", "completed-accessibility3", "generating-large", "stopped-large"]:
            for theme in ["light", "dark"]:
                self.validate(self.fixture(context, theme))

    def test_navigation_and_wrong_state_do_not_prove_conversation(self):
        for context in ["completed-large", "completed-accessibility3", "generating-large", "stopped-large"]:
            capture = self.fixture(context)
            capture["recognizedText"] = "Gemma 模拟预览 对话 模型 模板 设置"
            with self.assertRaises(RuntimeError):
                self.validate(capture)
        for key, value in [
            ("usesInferenceEngineSend", False), ("runtimeIsSimulated", False), ("messageCount", 4),
            ("isGenerating", True), ("canCopyAssistant", False), ("responseSource", "real-runtime"),
            ("dynamicTypeSize", "large-font-guess"), ("requiredTextMarker", "Gemma"), ("workspace", "models"),
            ("viewportWidth", 390), ("viewportHeight", 844), ("theme", "unknown"), ("context", "unknown"),
            ("isGenerating", 0), ("canCopyAssistant", 1),
        ]:
            capture = self.fixture()
            capture[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.validate(capture)

    def test_fixture_provenance_and_copy_boundaries_are_not_promoted(self):
        capture = self.fixture("generating-large")
        capture["responseSource"] = "default-simulation"
        with self.assertRaises(RuntimeError):
            self.validate(capture)
        capture = self.fixture("stopped-large")
        capture["canCopyAssistant"] = True
        with self.assertRaises(RuntimeError):
            self.validate(capture)
        for width, height in [(319, 640), (320, 639)]:
            with self.assertRaises(RuntimeError):
                self.validate(self.fixture(), width, height)
        with self.assertRaises(RuntimeError):
            self.validate(self.fixture(), name="old-screenshot")

    def test_traditional_glyphs_still_require_actual_reply_text(self):
        capture = self.fixture()
        capture["recognizedText"] = "對話 和 草稿"
        self.validate(capture)
        capture["recognizedText"] = "對話"
        with self.assertRaises(RuntimeError):
            self.validate(capture)


if __name__ == "__main__":
    unittest.main()
