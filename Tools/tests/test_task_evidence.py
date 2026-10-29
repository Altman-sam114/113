import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from export_workbench_evidence import validate_task_capture


class TaskEvidenceTests(unittest.TestCase):
    def fixture(self, context="everyday-accessibility3", theme="dark"):
        workspace, collection, size, marker = {
            "welcome-accessibility3": ("chat", "everyday", "accessibility3", "想聊点什么"),
            "welcome-accessibility5": ("chat", "everyday", "accessibility5", "想聊点什么"),
            "everyday-accessibility3": ("prompts", "everyday", "accessibility3", "润色文字"),
            "technical-large": ("prompts", "technical", "large", "部署方案"),
        }[context]
        return {
            "context": context, "theme": theme, "workspace": workspace,
            "templateCollection": collection, "dynamicTypeSize": size,
            "requiredTextMarker": marker, "recognizedText": marker + " 润色文字 保留原意",
            "requiredBodyMarker": "保留原意" if context == "everyday-accessibility3"
                else ("润色文字" if workspace == "chat" else "部署方案"),
            "viewportWidth": 390 if size == "accessibility5" else 320,
            "viewportHeight": 844 if size == "accessibility5" else 640,
        }

    def validate(self, capture, width=None, height=None, name=None):
        name = name or f"workbench-tasks-{capture['theme']}-{capture['context']}"
        width = capture["viewportWidth"] if width is None else width
        height = capture["viewportHeight"] if height is None else height
        validate_task_capture(capture, width, height, name)

    def test_all_six_task_contexts_are_required_shapes(self):
        for theme in ["light", "dark"]:
            for context in ["welcome-accessibility3", "welcome-accessibility5", "everyday-accessibility3", "technical-large"]:
                self.validate(self.fixture(context, theme))

    def test_navigation_alone_is_not_task_content(self):
        for context in ["welcome-accessibility3", "welcome-accessibility5", "everyday-accessibility3", "technical-large"]:
            capture = self.fixture(context)
            capture["recognizedText"] = "Gemma 对话 模型 模板 设置 日常 进阶"
            with self.assertRaises(RuntimeError):
                self.validate(capture)
        capture = self.fixture("welcome-accessibility3")
        capture["recognizedText"] = "想聊点什么"
        with self.assertRaises(RuntimeError):
            self.validate(capture)
        capture = self.fixture()
        capture["recognizedText"] = "润色文字 表达自然，保..."
        with self.assertRaises(RuntimeError):
            self.validate(capture)

    def test_wrong_context_size_or_collection_cannot_pass(self):
        for key, value in [
            ("context", "unknown"), ("theme", "unknown"), ("workspace", "models"),
            ("templateCollection", "technical"), ("dynamicTypeSize", "large"),
            ("requiredTextMarker", "模板"), ("viewportWidth", 390), ("viewportHeight", 844),
            ("requiredBodyMarker", "任意文字"),
        ]:
            capture = self.fixture()
            capture[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.validate(capture)
        for width, height in [(319, 640), (320, 639)]:
            with self.assertRaises(RuntimeError):
                self.validate(self.fixture(), width, height)
        with self.assertRaises(RuntimeError):
            self.validate(self.fixture("welcome-accessibility5"), 320, 640)
        with self.assertRaises(RuntimeError):
            self.validate(self.fixture(), name="other-task-image")

    def test_traditional_glyphs_do_not_replace_body_requirement(self):
        capture = self.fixture("welcome-accessibility3")
        capture["recognizedText"] = "想聊點什麼？ 潤色 文字"
        self.validate(capture)
        capture["recognizedText"] = "想聊點什麼？"
        with self.assertRaises(RuntimeError):
            self.validate(capture)


if __name__ == "__main__":
    unittest.main()
