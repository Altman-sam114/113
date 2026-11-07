"""Validate raw task evidence; phrase checks never stand in for semantic review."""
import hashlib
import json
import math
import unicodedata
from pathlib import Path

from prepare_llama_dependency import require


def normalized(text):
    return unicodedata.normalize("NFKC", text).casefold()


def validate_task_quality_report(probe, cases_path, expected_sha, run_id, attempt):
    from run_native_text_smoke import (PRODUCTION_MODEL_ID, FIXTURE_SHA256, validate_production_report)
    validate_production_report(probe, expected_sha, run_id, attempt)
    data = Path(cases_path).read_bytes()
    definition = json.loads(data)
    cases = definition.get("cases")
    require(type(definition.get("schemaVersion")) is int and definition["schemaVersion"] == 1 and type(definition.get("caseCount")) is int
            and definition["caseCount"] == 10 and isinstance(cases, list) and len(cases) == 10
            and len({c["id"] for c in cases}) == 10, "Exactly ten frozen task cases are required")
    evidence = probe.get("taskQuality", {})
    require(type(evidence.get("schemaVersion")) is int and evidence["schemaVersion"] == 1 and evidence.get("status") == "collected"
            and evidence.get("source") == "headless-production-everyday-task-quality"
            and evidence.get("modelID") == PRODUCTION_MODEL_ID and evidence.get("modelSHA256") == FIXTURE_SHA256
            and evidence.get("casesSHA256") == hashlib.sha256(data).hexdigest(),
            "The actual production model and frozen task inputs must match")
    require(type(evidence.get("caseCount")) is int and evidence["caseCount"] == 10
            and evidence.get("contextLength") == 4096 and evidence.get("maximumOutputTokens") == 512,
            "Task evidence must retain the production generation budgets")
    require(evidence.get("sourceModelUnmodified") is True and evidence.get("manualReviewRequired") is True
            and evidence.get("generalTaskQualityVerified") is False
            and evidence.get("UIFilePickerExercised") is False and evidence.get("deviceMemoryOrMetalVerified") is False,
            "Automatic evidence cannot claim human quality, Files UI or physical-device verification")
    results = evidence.get("cases")
    require(isinstance(results, list) and [r.get("id") for r in results] == [c["id"] for c in cases],
            "Every frozen task must have one original result in order")
    checks = []
    for task, result in zip(cases, results):
        require(result.get("templateID") == (task["templateID"] or "")
                and result.get("prompt") == task["expectedTemplatePrompt"] + task["input"],
                "A result changed the actual production template or supplied input")
        text = result.get("text")
        require(isinstance(text, str) and isinstance(result.get("error"), str)
                and isinstance(result.get("runtimeStatusMessages"), list)
                and all(isinstance(s, str) for s in result["runtimeStatusMessages"])
                and type(result.get("runtimeSucceeded")) is bool and type(result.get("simulated")) is bool,
                "Raw text, local errors and runtime identity must be preserved")
        tokens, rate, elapsed = (result.get(k) for k in ["outputTokens", "tokensPerSecond", "elapsedSeconds"])
        require(type(tokens) is int and 0 <= tokens <= 512
                and type(rate) in {float, int} and math.isfinite(rate) and rate >= 0
                and type(elapsed) in {float, int} and math.isfinite(elapsed) and elapsed >= 0,
                "Task metrics must be finite and bounded, never invented")
        succeeded = result["runtimeSucceeded"]
        if succeeded:
            require(result["simulated"] is False and result.get("backend") == "llamaCpp"
                    and not result["error"] and bool(text.strip()) and tokens > 0 and rate > 0,
                    "A successful task requires actual native text and metrics")
        else:
            require(bool(result["error"]), "A failed runtime must preserve its actual local error")
        value = normalized(text)
        missing = [group for group in task["requiredConcepts"] if not any(normalized(term) in value for term in group)]
        exact = task.get("acceptedExact")
        exact_passed = exact is None or text.strip() in exact
        checks.append({"id": task["id"], "runtimeSucceeded": succeeded,
                       "missingConcepts": missing, "exactInstructionPassed": exact_passed,
                       "automaticChecksPassed": succeeded and not missing and exact_passed,
                       "rubric": task["rubric"], "humanSemanticReview": "required"})
    failures = sum(not c["automaticChecksPassed"] for c in checks)
    return {"schemaVersion": 1, "commitSha": expected_sha, "runId": run_id, "runAttempt": attempt,
            "status": "automatic-checks-failed" if failures else "automatic-checks-passed-awaiting-human-review",
            "caseCount": 10, "automaticFailureCount": failures, "checks": checks,
            "manualReviewRequired": True, "generalTaskQualityVerified": False,
            "limitation": "Phrase and exact-format checks do not establish meaning, negation, completeness or general quality."}
