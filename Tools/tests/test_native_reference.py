import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_reference_diagnostic import (ROOT, parse_reference_output, rendered_gemma_user, validate_reference_source)


class NativeReferenceDiagnosticTests(unittest.TestCase):
    def test_only_the_unmodified_pinned_source_and_license_are_accepted(self):
        source, metadata = validate_reference_source(ROOT / "Tools/reference")
        self.assertTrue(source.is_file())
        self.assertTrue(metadata["unmodifiedUpstreamSource"])
        # Temporary test fixtures are retained; no user files are deleted.
        directory = Path(tempfile.mkdtemp(prefix="native-reference-fixture-"))
        for name in ["llama-simple.cpp", "llama-LICENSE", "source.json"]:
            shutil.copy2(ROOT / "Tools/reference" / name, directory / name)
        (directory / "llama-simple.cpp").write_text("int main() { return 0; }")
        with self.assertRaises(ValueError):validate_reference_source(directory)
        shutil.copy2(ROOT / "Tools/reference/llama-simple.cpp", directory / "llama-simple.cpp")
        metadata["unmodifiedUpstreamSource"] = False
        (directory / "source.json").write_text(json.dumps(metadata))
        with self.assertRaises(ValueError):validate_reference_source(directory)

    def test_reference_prompt_has_one_user_turn_and_no_injected_bos(self):
        rendered = rendered_gemma_user("  What is 2 + 3?\n")
        self.assertEqual(rendered, "<start_of_turn>user\nWhat is 2 + 3?<end_of_turn>\n<start_of_turn>model\n")
        self.assertNotIn("<bos>", rendered)
        for value in ["", " \n", "bad\0prompt"]:
            with self.assertRaises(ValueError):rendered_gemma_user(value)

    def test_output_parser_preserves_the_actual_answer_and_only_removes_the_program_echo(self):
        rendered = rendered_gemma_user("Question")
        self.assertEqual(parse_reference_output("<bos>" + rendered + "1\n\n", rendered), "1\n")
        self.assertEqual(parse_reference_output("<bos>" + rendered + "  Answer\ntext  \n", rendered), "  Answer\ntext  ")

    def test_missing_prompt_wrong_bos_or_truncated_stdout_cannot_be_reinterpreted_as_an_answer(self):
        rendered = rendered_gemma_user("Question")
        for stdout in ["1\n", rendered + "1\n", "<bos><bos>" + rendered + "1\n",
                       "<bos>" + rendered + "1", "<bos>" + rendered.replace("Question", "Other") + "1\n"]:
            with self.assertRaises(ValueError):parse_reference_output(stdout, rendered)

if __name__ == "__main__":unittest.main()
