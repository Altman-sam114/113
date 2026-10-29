"""Validate public UI-test evidence without running Apple tools on import."""
import math


TESTS = {
    "large": {
        "testLightSummaryLifecycle", "testDarkSummaryLifecycle",
        "testDraftSurvivesSummaryAndModelNavigation",
    },
    "accessibility5": {
        "testAccessibilityLightSummaryLifecycle", "testAccessibilityDarkSummaryLifecycle",
        "testAccessibilityDraftSurvivesSummaryAndModelNavigation",
    },
}
LIFECYCLE_STAGES = ("open", "expanded", "managed-models", "returned-chat")
DRAFT_STAGES = ("draft-keyboard", "draft-sheet", "draft-returned")


def expected_captures(category):
    return {f"interaction-{theme}-{category}-{stage}"
            for theme in ("light", "dark") for stage in LIFECYCLE_STAGES} | {
                f"interaction-dark-{category}-{stage}" for stage in DRAFT_STAGES}


def validate_results(summary, tree, category, device_id):
    if (summary.get("result") != "Passed" or summary.get("totalTestCount") != 3
            or summary.get("passedTests") != 3 or summary.get("failedTests") != 0
            or summary.get("skippedTests") != 0 or summary.get("expectedFailures") != 0
            or summary.get("testFailures")):
        raise ValueError("Exactly three successful UI tests with no failure or skip are required")
    cases = []

    def walk(node):
        if isinstance(node, dict):
            if node.get("nodeType") == "Test Case":
                cases.append(node)
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(tree.get("testNodes", []))
    names = [case.get("name", "").removesuffix("()") for case in cases]
    if len(cases) != 3 or set(names) != TESTS[category] or any(c.get("result") != "Passed" for c in cases):
        raise ValueError("UI test names, unique executions, and results must match the selected system category")
    devices = tree.get("devices", [])
    if len(devices) != 1 or devices[0].get("deviceId") != device_id:
        raise ValueError("UI tests must run on the recorded exact simulator UDID")


def validate_capture(document, category, png_size):
    name = document.get("name", "")
    stage = document.get("stage")
    theme = document.get("theme")
    expected_category = ("UICTContentSizeCategoryAccessibilityXXXL"
                         if category == "accessibility5" else "UICTContentSizeCategoryL")
    if (document.get("schemaVersion") != 1 or document.get("source") != "public-XCUITest-production-app"
            or name not in expected_captures(category)
            or name != f"interaction-{theme}-{category}-{stage}"
            or document.get("dynamicTypeSize") != category
            or document.get("systemContentSizeCategory") != expected_category
            or document.get("screenWidth") != 375 or document.get("screenHeight") != 667
            or png_size != (750, 1334)
            or document.get("realInferenceVerified") is not False
            or document.get("signedDistributionVerified") is not False):
        raise ValueError("Capture must be the exact small-phone production UI and real system text category")
    actions = document.get("actions", [])
    if stage == "draft-keyboard":
        if not {"tap:session-bar-action-createSession", "tap:composer-input-field",
                "type:local-draft-without-send"} <= set(actions):
            raise ValueError("The initial keyboard capture must follow real session creation and input events")
    elif "tap:compact-model-summary" not in actions:
        raise ValueError("The production summary button must be tapped")
    if stage == "expanded" and "tap:compact-model-runtime-details" not in actions:
        raise ValueError("Details must be opened through the production disclosure control")
    if stage in ("managed-models", "returned-chat", "draft-returned"):
        if "tap:header-action-open-model-library" not in actions:
            raise ValueError("Model navigation must use the original management action")
    if stage in ("returned-chat", "draft-returned") and "tap:workspace-tab-chat" not in actions:
        raise ValueError("Return must use the production workspace button")
    if stage in ("draft-keyboard", "draft-returned"):
        if document.get("draft") != "Keep this draft" or document.get("keyboardVisible") is not True:
            raise ValueError("The original typed draft and actual keyboard must survive")
    frames = document.get("frames", {})
    for frame in frames.values():
        if set(frame) != {"x", "y", "width", "height"} or not all(
                isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v) for v in frame.values()):
            raise ValueError("Control geometry must be finite")
    if stage in ("open", "expanded", "draft-sheet"):
        for identifier in ("compact-model-summary-close", "header-action-open-model-library"):
            frame = frames.get(identifier, {})
            if (frame.get("width", 0) < 44 or frame.get("height", 0) < 44
                    or frame.get("x", -1) < 0 or frame.get("y", -1) < 0
                    or frame.get("x", 0) + frame.get("width", 0) > 375
                    or frame.get("y", 0) + frame.get("height", 0) > 667):
                raise ValueError("Summary actions must keep 44pt visible screen bounds")
