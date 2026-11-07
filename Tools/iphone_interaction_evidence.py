"""Validate public UI-test evidence without running Apple tools on import."""
import math
import re


TESTS = {
    "large": {
        "testLightSummaryLifecycle", "testDarkSummaryLifecycle",
        "testDraftSurvivesSummaryAndModelNavigation",
        "testHelpPreservesDraftAndWorkspace",
        "testNativeModelLicenseReviewCancelsWithoutImport",
        "testDraftsAndSelectionSurviveBackgroundTermination",
    },
    "accessibility5": {
        "testAccessibilityLightSummaryLifecycle", "testAccessibilityDarkSummaryLifecycle",
        "testAccessibilityDraftSurvivesSummaryAndModelNavigation",
        "testAccessibilityHelpPreservesDraftAndWorkspace",
        "testAccessibilityNativeModelLicenseReviewCancelsWithoutImport",
        "testAccessibilityDraftsAndSelectionSurviveBackgroundTermination",
    },
}
LIFECYCLE_STAGES = ("open", "expanded", "managed-models", "returned-chat")
DRAFT_STAGES = ("draft-keyboard", "draft-sheet", "draft-returned")
HELP_STAGES = ("help-open", "help-bottom")
LICENSE_STAGES = ("license-open", "license-cancelled")
PERSISTENCE_STAGES = ("persistence-before-background", "persistence-first-restored", "persistence-second-restored")
HELP_SECTIONS = (
    ("capabilities", "当前能力", "当前版本是本地 AI 工作台原型", ("模拟回复", "发送消息会执行本机文本推理", "不保证设备内存足够或生成成功")),
    ("privacy", "App 不主动上传", "App 不发起对话", ("不收集使用分析", "不自动下载模型权重")),
    ("storage", "本机保存与系统备份", "对话和逐会话草稿保存在",
     ("不参与系统备份", "卸载 App 会失去未导出的对话", "壁纸", "仍可能进入系统备份")),
    ("sharing", "分享由你决定", "导出生成本机 Markdown 文件", ("只有你操作分享或复制后",)),
    ("deletion", "删除、恢复与修复", "在会话记录中删除并确认",
     ("不删除 Files 中的原始文件", "原件备份仍保留在不参与系统备份的会话目录")),
    ("models", "模型与授权", "App 不附带可运行的真实模型权重", ("相应模型许可",)),
    ("support", "帮助与反馈", "遇到问题时，可记录 App 版本", ("App 不自动附带会话", "仅在你点按后")),
)


def selected_tests(category, scope="full"):
    if scope == "full":
        return TESTS[category]
    if scope == "license":
        return {name for name in TESTS[category] if "NativeModelLicenseReview" in name}
    raise ValueError("Unknown interaction validation scope")


def expected_captures(category, scope="full"):
    selected_tests(category, scope)
    if scope == "license":
        return {f"interaction-dark-{category}-{stage}" for stage in LICENSE_STAGES}
    return {f"interaction-{theme}-{category}-{stage}"
            for theme in ("light", "dark") for stage in LIFECYCLE_STAGES} | {
                f"interaction-dark-{category}-{stage}" for stage in DRAFT_STAGES + HELP_STAGES + LICENSE_STAGES + PERSISTENCE_STAGES}


def validate_results(summary, tree, category, device_id, scope="full"):
    required = selected_tests(category, scope)
    count = len(required)
    if (summary.get("result") != "Passed" or summary.get("totalTestCount") != count
            or summary.get("passedTests") != count or summary.get("failedTests") != 0
            or summary.get("skippedTests") != 0 or summary.get("expectedFailures") != 0
            or summary.get("testFailures")):
        raise ValueError(f"Exactly {count} successful UI tests with no failure or skip are required")
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
    if len(cases) != count or set(names) != required or any(c.get("result") != "Passed" for c in cases):
        raise ValueError("UI test names, unique executions, and results must match the selected system category")
    devices = tree.get("devices", [])
    if len(devices) != 1 or devices[0].get("deviceId") != device_id:
        raise ValueError("UI tests must run on the recorded exact simulator UDID")


def validate_capture(document, category, png_size, scope="full"):
    name = document.get("name", "")
    stage = document.get("stage")
    theme = document.get("theme")
    expected_category = ("UICTContentSizeCategoryAccessibilityXXXL"
                         if category == "accessibility5" else "UICTContentSizeCategoryL")
    if (document.get("schemaVersion") != 1 or document.get("source") != "public-XCUITest-production-app"
            or name not in expected_captures(category, scope)
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
    elif stage not in HELP_STAGES + LICENSE_STAGES + PERSISTENCE_STAGES and "tap:compact-model-summary" not in actions:
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
    if stage in HELP_STAGES:
        validate_help_capture(document)
    if stage in LICENSE_STAGES:
        validate_license_capture(document)
    if stage in PERSISTENCE_STAGES:
        validate_persistence_capture(document)


def validate_persistence_capture(document):
    actions = document.get("actions", [])
    first, second = document.get("firstSessionID"), document.get("secondSessionID")
    if (not isinstance(first, str) or not isinstance(second, str) or first == second
            or not all(re.fullmatch(r"session-chip-select-[0-9a-f]{8}", value) for value in (first, second))):
        raise ValueError("Two distinct actual production session identities are required")
    initial = ["tap:session-bar-action-createSession", f"tap:{first}", "tap:composer-input-field",
               "type:persist-first-draft", "tap:session-bar-action-createSession", f"tap:{second}",
               "tap:composer-input-field", "type:persist-second-draft", f"tap:{first}",
               "type:persist-first-final-edit"]
    require_action_sequence(actions, initial)
    stage = document["stage"]
    restored = stage != "persistence-before-background"
    lifecycle = ["observed:background", "observed:not-running", "observed:foreground"] if restored else []
    if (document.get("lifecycle") != lifecycle or document.get("appState") != "runningForeground"
            or document.get("composerEnabled") is not True or document.get("keyboardVisible") is not False
            or document.get("terminationMethod") != "XCUIApplication.terminate-after-observed-background"
            or document.get("containerModifiedByTest") is not False or document.get("promptSent") is not False
            or document.get("physicalDeviceDurabilityVerified") is not False):
        raise ValueError("Real background, terminated and relaunched states must remain explicit and limited")
    second_active = stage == "persistence-second-restored"
    expected_draft = " Draft B: independent " if second_active else " Draft A: keep spaces final edit"
    if (document.get("draft") != expected_draft
            or document.get("activeSessionID") != (second if second_active else first)):
        raise ValueError("The original active selection and untrimmed per-session drafts must survive")
    if restored:
        require_action_sequence(actions, initial + ["device:home", "terminate:production-app",
                                                    "relaunch:production-app", f"tap:{first}"]
                                + ([f"tap:{second}"] if second_active else []))
    elif any(event in actions for event in ("device:home", "terminate:production-app", "relaunch:production-app")):
        raise ValueError("The pre-background screenshot cannot contain future lifecycle actions")
    validate_screen_frame(document.get("frames", {}).get("composer-input-field"))


def validate_persistence_sequence(documents):
    if [d.get("stage") for d in documents] != list(PERSISTENCE_STAGES):
        raise ValueError("All three ordered original lifecycle screenshots are required")
    first = documents[0]
    for previous, current in zip(documents, documents[1:]):
        if (current.get("firstSessionID") != first.get("firstSessionID")
                or current.get("secondSessionID") != first.get("secondSessionID")
                or current.get("actions", [])[:len(previous["actions"])] != previous["actions"]):
            raise ValueError("Original session identities and actual action history must remain continuous across restart")


def validate_license_capture(document):
    actions = document.get("actions", [])
    require_action_sequence(actions, ["tap:workspace-tab-models", "tap:model-selector-picker",
                                     "tap:native-model-choice", "tap:model-artifact-action-import"])
    if (document.get("keyboardVisible") is not False or "Gemma 3 270M" not in document.get("selectedModel", "")
            or "缺少本地 artifact" not in document.get("selectedModel", "")
            or "tap:model-license-confirm-import" in actions):
        raise ValueError("License verification must not import, verify or run a model")
    if document["stage"] == "license-open":
        if document.get("licenseReviewVisible") is not True:
            raise ValueError("The real production license review must be visible")
        for identifier in ["model-license-cancel", "model-license-confirm-import"]:
            validate_screen_frame(document.get("frames", {}).get(identifier), 44)
    else:
        require_action_sequence(actions, ["tap:model-artifact-action-import", "tap:model-license-cancel"])
        if document.get("licenseReviewVisible") is not False:
            raise ValueError("Cancellation must dismiss the actual license review")
        validate_screen_frame(document.get("frames", {}).get("model-selector-picker"), 44)


def require_action_sequence(actions, sequence):
    if not isinstance(actions, list) or any(not isinstance(action, str) for action in actions):
        raise ValueError("Actual help actions must be an ordered event list")
    offset = 0
    for action in sequence:
        try:
            offset = actions.index(action, offset) + 1
        except ValueError as error:
            raise ValueError("Help must follow the original ordered production actions") from error


def validate_frame(frame):
    if (not isinstance(frame, dict) or set(frame) != {"x", "y", "width", "height"}
            or not all(isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)
                       for v in frame.values()) or frame["width"] <= 0 or frame["height"] <= 0):
        raise ValueError("Help observation geometry must be finite and positive")


def validate_screen_frame(frame, minimum=0):
    validate_frame(frame)
    if (frame["width"] < minimum or frame["height"] < minimum or frame["x"] < 0 or frame["y"] < 0
            or frame["x"] + frame["width"] > 375 or frame["y"] + frame["height"] > 667):
        raise ValueError("Help actions and live completion geometry must fit the actual screen")


def validate_help_capture(document):
    stage, actions = document["stage"], document["actions"]
    initial_actions = ["tap:session-bar-action-createSession", "tap:composer-input-field",
                       "type:local-draft-without-send", "tap:composer-keyboard-done",
                       "tap:workspace-tab-settings", "tap:settings-help-open"]
    require_action_sequence(actions, initial_actions)
    if "tap:settings-help-repository" in actions or document.get("keyboardVisible") is not False:
        raise ValueError("Help must be local and must not retain the hidden composer's keyboard")
    flow = document.get("helpFlow", {})
    if (not isinstance(flow, dict) or flow.get("originalWorkspace") != "chat"
            or flow.get("initialDraft") != "Keep this draft"):
        raise ValueError("Help must begin with the actual original chat and unmodified typed draft")
    validate_screen_frame(document.get("frames", {}).get("settings-help-close"), 44)
    observations = flow.get("sections")
    if stage == "help-open":
        if observations != []:
            raise ValueError("The opening screen must precede scrolling through help")
        return
    if not isinstance(observations, list) or len(observations) != len(HELP_SECTIONS):
        raise ValueError("Every complete production help section must be observed")
    for observation, (identifier, title, prefix, required) in zip(observations, HELP_SECTIONS):
        if (not isinstance(observation, dict) or observation.get("id") != identifier or observation.get("title") != title
                or not isinstance(observation.get("text"), str) or not observation["text"].startswith(prefix)
                or not all(text in observation["text"] for text in required)):
            raise ValueError("Help section identity and full privacy/runtime copy must remain intact")
        frame, viewport = observation.get("frame"), observation.get("viewport")
        validate_frame(frame)
        validate_screen_frame(viewport)
        visible_width = min(frame["x"] + frame["width"], viewport["x"] + viewport["width"]) - max(frame["x"], viewport["x"])
        visible_height = min(frame["y"] + frame["height"], viewport["y"] + viewport["height"]) - max(frame["y"], viewport["y"])
        if (viewport["height"] <= 44 or visible_width < min(44, frame["width"])
                or visible_height < min(44, frame["height"])):
            raise ValueError("Read-only help text must actually intersect the real scroll viewport")
    require_action_sequence(actions, initial_actions + [f"read:help-{section[0]}" for section in HELP_SECTIONS])
    if "scroll:help-content-up" not in actions:
        raise ValueError("The complete help content must be reached by actual scrolling")
    validate_screen_frame(document.get("frames", {}).get("settings-help-repository"), 44)
    completion = document.get("completion", {})
    if not isinstance(completion, dict):
        raise ValueError("The bottom screenshot must retain its later live completion observation")
    completion_actions = completion.get("actions", [])
    if (completion.get("source") != "post-dismiss-live-XCUI-snapshot"
            or completion.get("settingsRestoredAfterClose") is not True
            or completion.get("workspace") != "chat" or completion.get("workspaceSelected") is not True
            or completion.get("draft") != "Keep this draft" or completion.get("keyboardVisible") is not True
            or completion.get("helpVisible") is not False or not isinstance(completion_actions, list)
            or completion_actions[:len(actions)] != actions):
        raise ValueError("Post-dismiss observations must restore settings, then the original chat draft and keyboard")
    require_action_sequence(completion_actions[len(actions):], ["tap:settings-help-close", "tap:workspace-tab-chat"])
    if "tap:settings-help-repository" in completion_actions:
        raise ValueError("Automated help verification must not open an external service")
    composer, keyboard = completion.get("composerFrame"), completion.get("keyboardFrame")
    validate_screen_frame(composer)
    validate_screen_frame(keyboard)
    if composer["y"] + composer["height"] > keyboard["y"]:
        raise ValueError("The restored original composer must remain above the real keyboard")
