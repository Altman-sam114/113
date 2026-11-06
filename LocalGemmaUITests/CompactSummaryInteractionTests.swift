import UIKit
import XCTest

@MainActor
final class CompactSummaryInteractionTests: XCTestCase {
    private var actions: [String] = []
    private let summaryID = "compact-model-summary"
    private let closeID = "compact-model-summary-close"
    private let detailsID = "compact-model-runtime-details"
    private let manageID = "header-action-open-model-library"
    private let composerID = "composer-input-field"

    func testLightSummaryLifecycle() throws {
        try summaryLifecycle(theme: "light", accessibility: false)
    }

    func testDarkSummaryLifecycle() throws {
        try summaryLifecycle(theme: "dark", accessibility: false)
    }

    func testDraftSurvivesSummaryAndModelNavigation() throws {
        try draftLifecycle(accessibility: false)
    }

    func testAccessibilityLightSummaryLifecycle() throws {
        try summaryLifecycle(theme: "light", accessibility: true)
    }

    func testAccessibilityDarkSummaryLifecycle() throws {
        try summaryLifecycle(theme: "dark", accessibility: true)
    }

    func testAccessibilityDraftSurvivesSummaryAndModelNavigation() throws {
        try draftLifecycle(accessibility: true)
    }

    func testHelpPreservesDraftAndWorkspace() throws {
        try helpLifecycle(accessibility: false)
    }

    func testAccessibilityHelpPreservesDraftAndWorkspace() throws {
        try helpLifecycle(accessibility: true)
    }

    func testNativeModelLicenseReviewCancelsWithoutImport() throws {
        try licenseLifecycle(accessibility: false)
    }

    func testAccessibilityNativeModelLicenseReviewCancelsWithoutImport() throws {
        try licenseLifecycle(accessibility: true)
    }

    private func launch(theme: String, accessibility: Bool) -> XCUIApplication {
        continueAfterFailure = false
        actions = []
        XCTAssertEqual(UIApplication.shared.preferredContentSizeCategory,
                       accessibility ? .accessibilityExtraExtraExtraLarge : .large)
        let app = XCUIApplication()
        app.launchArguments = ["--ui-workspace", "chat", "-appThemeMode", theme,
                               "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        actions.append("launch:production-app")
        XCTAssertTrue(app.buttons[summaryID].waitForExistence(timeout: 15))
        return app
    }

    private func summaryLifecycle(theme: String, accessibility: Bool) throws {
        let app = launch(theme: theme, accessibility: accessibility)
        tap(app.buttons[summaryID], id: summaryID)
        assertSheet(app, startsLarge: accessibility)
        try capture(app, theme: theme, accessibility: accessibility, stage: "open")

        let scroll = app.scrollViews["compact-model-summary-scroll"]
        reveal(element(app, detailsID), in: scroll, app: app)
        if !accessibility {
            XCTAssertGreaterThan(element(app, "compact-model-summary-heading").frame.minY, app.frame.height * 0.3)
        }
        tap(element(app, detailsID), id: detailsID)
        reveal(element(app, detailsID), in: scroll, app: app, direction: .down)
        XCTAssertTrue(waitUntil {
            let details = self.element(app, self.detailsID)
            return details.exists && details.value as? String == "已展开"
        })
        reveal(element(app, "header-model-capsule"), in: scroll, app: app, requiresHitTarget: false)
        XCTAssertTrue(element(app, "header-model-capsule").waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil { self.element(app, "compact-model-summary-heading").frame.minY < app.frame.height * 0.25 })
        XCTAssertTrue((element(app, "header-model-capsule").value as? String ?? "").contains("36.0 tok/s"))
        reveal(app.staticTexts["36.0 tok/s"].firstMatch, in: scroll, app: app, requiresHitTarget: false)
        assertReachableAction(app.buttons[manageID], inside: app.frame)
        try capture(app, theme: theme, accessibility: accessibility, stage: "expanded")

        reveal(element(app, detailsID), in: scroll, app: app, direction: .down)
        tap(element(app, detailsID), id: detailsID)
        reveal(element(app, detailsID), in: scroll, app: app)
        XCTAssertTrue(waitUntil {
            let details = self.element(app, self.detailsID)
            return details.exists && details.value as? String == "已折叠"
        })
        XCTAssertTrue(waitUntil { !self.element(app, "header-model-capsule").exists })
        XCTAssertLessThan(element(app, "compact-model-summary-heading").frame.minY, app.frame.height * 0.25)
        tap(app.buttons[closeID], id: closeID)
        XCTAssertTrue(waitUntil { !app.buttons[self.closeID].exists })
        XCTAssertTrue(app.buttons[summaryID].isHittable)

        tap(app.buttons[summaryID], id: summaryID)
        assertSheet(app, startsLarge: accessibility)
        XCTAssertFalse(element(app, "header-model-capsule").exists)
        tap(app.buttons[manageID], id: manageID)
        assertModels(app)
        try capture(app, theme: theme, accessibility: accessibility, stage: "managed-models")

        tap(app.buttons["workspace-tab-chat"], id: "workspace-tab-chat")
        XCTAssertTrue(app.buttons[summaryID].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons[closeID].exists)
        try capture(app, theme: theme, accessibility: accessibility, stage: "returned-chat")
        app.terminate()
    }

    private func draftLifecycle(accessibility: Bool) throws {
        let app = launch(theme: "dark", accessibility: accessibility)
        tap(app.buttons["session-bar-action-createSession"], id: "session-bar-action-createSession")
        let keyboardIntroduction = app.buttons["Continue"]
        if keyboardIntroduction.waitForExistence(timeout: 3) && keyboardIntroduction.isHittable {
            tap(keyboardIntroduction, id: "system-keyboard-introduction-continue")
        }
        let keyboardDone = app.buttons["收起键盘"]
        if keyboardDone.exists && keyboardDone.isHittable {
            tap(keyboardDone, id: "composer-keyboard-done")
            XCTAssertTrue(waitUntil { !app.keyboards.firstMatch.exists })
        }
        let composer = app.textFields[composerID]
        XCTAssertTrue(waitUntil { composer.exists && composer.isEnabled })
        print("Composer before direct tap: enabled=\(composer.isEnabled), hittable=\(composer.isHittable), frame=\(composer.frame)")
        composer.tap()
        actions.append("tap:\(composerID)")
        composer.typeText("Keep this draft")
        actions.append("type:local-draft-without-send")
        XCTAssertEqual(composer.value as? String, "Keep this draft")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        assertComposerVisible(composer, in: app)
        try capture(app, theme: "dark", accessibility: accessibility, stage: "draft-keyboard")

        tap(app.buttons[summaryID], id: summaryID)
        XCTAssertTrue(app.buttons[closeID].waitForExistence(timeout: 5))
        assertReachableAction(app.buttons[manageID], inside: app.frame)
        try capture(app, theme: "dark", accessibility: accessibility, stage: "draft-sheet")
        tap(app.buttons[closeID], id: closeID)
        XCTAssertTrue(waitUntil { !app.buttons[self.closeID].exists })
        XCTAssertEqual(composer.value as? String, "Keep this draft")

        tap(app.buttons[summaryID], id: summaryID)
        tap(app.buttons[manageID], id: manageID)
        assertModels(app)
        let keyboardDismissed = waitUntil { !app.keyboards.firstMatch.exists }
        if !keyboardDismissed { attachDiagnostic("keyboard-survived-model-navigation") }
        XCTAssertTrue(keyboardDismissed)
        tap(app.buttons["workspace-tab-chat"], id: "workspace-tab-chat")
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertEqual(composer.value as? String, "Keep this draft")
        XCTAssertTrue(waitUntil { composer.isEnabled && app.keyboards.firstMatch.exists })
        assertComposerVisible(composer, in: app)
        try capture(app, theme: "dark", accessibility: accessibility, stage: "draft-returned")
        app.terminate()
    }

    private func licenseLifecycle(accessibility: Bool) throws {
        let app = launch(theme: "dark", accessibility: accessibility)
        tap(app.buttons["workspace-tab-models"], id: "workspace-tab-models")
        let picker = app.buttons["model-selector-picker"]
        tap(picker, id: "model-selector-picker")
        let choice = app.buttons["Gemma 3 1B"]
        if !choice.isHittable {
            attachDiagnostic("native-model-menu-before-scroll")
            // The system menu exposes a CollectionView on current iOS. Its
            // content frame can extend below the clipped popup, so let UIKit
            // scroll the actual menu rather than deriving a viewport from it.
            let choices = app.collectionViews.containing(.button, identifier: "Gemma 3 1B").firstMatch
            XCTAssertTrue(choices.waitForExistence(timeout: 5))
            for _ in 0..<8 {
                if choice.exists && choice.isHittable && app.frame.contains(choice.frame) { break }
                choices.swipeUp(velocity: .slow)
                actions.append("scroll:model-picker-up")
            }
        }
        tap(choice, id: "native-model-choice")
        XCTAssertTrue(waitUntil { (picker.value as? String)?.contains("Gemma 3 1B") == true })
        let selectedBefore = try XCTUnwrap(picker.value as? String)
        XCTAssertTrue(selectedBefore.contains("缺少本地 artifact"))
        let importAction = app.buttons["model-artifact-action-import"]
        let scroll = app.scrollViews.containing(.button, identifier: "model-artifact-action-import").firstMatch
        revealHelpContent(importAction, in: scroll, app: app, isAction: true)
        tap(importAction, id: "model-artifact-action-import")
        let cancel = app.buttons["model-license-cancel"]
        let confirm = app.buttons["model-license-confirm-import"]
        assertReachableAction(cancel, inside: app.frame)
        assertReachableAction(confirm, inside: app.frame)
        XCTAssertTrue(element(app, "model-license-model-name").label.contains("Gemma 3 1B"))
        try captureLicense(app, accessibility: accessibility, stage: "license-open", selectedModel: selectedBefore)
        // No automated test accepts a model license on the user's behalf or
        // opens Files. Cancellation must leave the selected model unverified.
        tap(cancel, id: "model-license-cancel")
        XCTAssertTrue(waitUntil { !cancel.exists && picker.exists })
        revealHelpContent(picker, in: scroll, app: app, isAction: true, preferPrevious: true)
        assertReachableAction(picker, inside: app.frame)
        XCTAssertEqual(picker.value as? String, selectedBefore)
        XCTAssertFalse(confirm.exists)
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        try captureLicense(app, accessibility: accessibility, stage: "license-cancelled", selectedModel: selectedBefore)

        // Cancel must reset the review without granting permission to import.
        revealHelpContent(importAction, in: scroll, app: app, isAction: true)
        tap(importAction, id: "model-artifact-action-import")
        assertReachableAction(cancel, inside: app.frame)
        assertReachableAction(confirm, inside: app.frame)
        XCTAssertTrue(element(app, "model-license-model-name").label.contains("Gemma 3 1B"))
        tap(cancel, id: "model-license-cancel")
        XCTAssertTrue(waitUntil { !cancel.exists && picker.exists })
        XCTAssertEqual(picker.value as? String, selectedBefore)
        app.terminate()
    }

    private func captureLicense(
        _ app: XCUIApplication, accessibility: Bool, stage: String, selectedModel: String
    ) throws {
        let category = accessibility ? "accessibility5" : "large"
        var frames: [String: [String: Double]] = [:]
        for identifier in ["model-license-cancel", "model-license-confirm-import", "model-selector-picker"] {
            let control = element(app, identifier)
            if control.exists { frames[identifier] = helpFrame(control.frame) }
        }
        let document: [String: Any] = [
            "schemaVersion": 1, "source": "public-XCUITest-production-app",
            "name": "interaction-dark-\(category)-\(stage)", "theme": "dark",
            "dynamicTypeSize": category, "stage": stage,
            "systemContentSizeCategory": UIApplication.shared.preferredContentSizeCategory.rawValue,
            "screenWidth": app.frame.width, "screenHeight": app.frame.height,
            "keyboardVisible": app.keyboards.firstMatch.exists, "actions": actions, "frames": frames,
            "selectedModel": selectedModel, "licenseReviewVisible": app.buttons["model-license-cancel"].exists,
            "realInferenceVerified": false, "signedDistributionVerified": false
        ]
        try attachHelpSnapshot(XCUIScreen.main.screenshot(), document: document)
    }

    private func helpLifecycle(accessibility: Bool) throws {
        let app = launch(theme: "dark", accessibility: accessibility)
        XCTAssertTrue(app.buttons["workspace-tab-chat"].isSelected)
        tap(app.buttons["session-bar-action-createSession"], id: "session-bar-action-createSession")
        let introduction = app.buttons["Continue"]
        if introduction.waitForExistence(timeout: 3) && introduction.isHittable {
            tap(introduction, id: "system-keyboard-introduction-continue")
        }
        let keyboardDone = app.buttons["收起键盘"]
        if keyboardDone.exists && keyboardDone.isHittable {
            tap(keyboardDone, id: "composer-keyboard-done")
            XCTAssertTrue(waitUntil { !app.keyboards.firstMatch.exists })
        }
        let composer = app.textFields[composerID]
        XCTAssertTrue(waitUntil { composer.exists && composer.isEnabled })
        composer.tap()
        actions.append("tap:\(composerID)")
        composer.typeText("Keep this draft")
        actions.append("type:local-draft-without-send")
        assertComposerVisible(composer, in: app)
        let initialDraft = try XCTUnwrap(composer.value as? String)

        tap(keyboardDone, id: "composer-keyboard-done")
        XCTAssertTrue(waitUntil { !app.keyboards.firstMatch.exists && app.buttons["workspace-tab-settings"].isHittable })
        XCTAssertEqual(composer.value as? String, initialDraft)

        tap(app.buttons["workspace-tab-settings"], id: "workspace-tab-settings")
        XCTAssertTrue(waitUntil { app.buttons["workspace-tab-settings"].isSelected && !app.keyboards.firstMatch.exists })
        let help = app.buttons["settings-help-open"]
        let settingsScroll = app.scrollViews.containing(.button, identifier: "settings-help-open").firstMatch
        revealHelpContent(help, in: settingsScroll, app: app, isAction: true)
        assertReachableAction(help, inside: app.frame)
        tap(help, id: "settings-help-open")
        let close = app.buttons["settings-help-close"]
        assertReachableAction(close, inside: app.frame)
        let scroll = app.scrollViews.containing(.staticText, identifier: "当前能力").firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let opened = helpSnapshot(app, accessibility: accessibility, stage: "help-open", initialDraft: initialDraft, sections: [])
        try attachHelpSnapshot(opened.image, document: opened.document)

        let sectionQueries = [
            ("capabilities", "当前能力", "当前版本是本地 AI 工作台原型"),
            ("privacy", "App 不主动上传", "App 不发起对话"),
            ("storage", "本机保存与系统备份", "对话和逐会话草稿保存在"),
            ("sharing", "分享由你决定", "导出生成本机 Markdown 文件"),
            ("deletion", "删除、恢复与修复", "在会话记录中删除并确认"),
            ("models", "模型与授权", "App 不附带可运行的真实模型权重"),
            ("support", "帮助与反馈", "遇到问题时，可记录 App 版本")
        ]
        var observations: [[String: Any]] = []
        for (id, title, prefix) in sectionQueries {
            let heading = app.staticTexts[title].firstMatch
            revealHelpContent(heading, in: scroll, app: app)
            let body = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
            revealHelpContent(body, in: scroll, app: app)
            XCTAssertTrue(body.label.hasPrefix(prefix))
            observations.append(["id": id, "title": heading.label, "text": body.label,
                                 "frame": helpFrame(body.frame), "viewport": helpFrame(helpViewport(scroll, app: app))])
            actions.append("read:help-\(id)")
        }
        let repository = element(app, "settings-help-repository")
        revealHelpContent(repository, in: scroll, app: app, isAction: true)
        assertReachableAction(repository, inside: app.frame)
        XCTAssertTrue(waitUntil { !app.keyboards.firstMatch.exists })
        var bottom = helpSnapshot(app, accessibility: accessibility, stage: "help-bottom", initialDraft: initialDraft,
                                  sections: observations)

        tap(close, id: "settings-help-close")
        XCTAssertTrue(waitUntil { !close.exists && app.buttons["workspace-tab-settings"].isSelected })
        let settingsRestored = app.buttons["workspace-tab-settings"].isSelected
        tap(app.buttons["workspace-tab-chat"], id: "workspace-tab-chat")
        XCTAssertTrue(waitUntil { composer.exists && composer.isEnabled && app.keyboards.firstMatch.exists })
        XCTAssertFalse(close.exists)
        XCTAssertEqual(composer.value as? String, "Keep this draft")
        assertComposerVisible(composer, in: app)
        // Chat intentionally hides workspace chrome while editing. Observe the
        // actual selection with the keyboard dismissed, then restore editing.
        tap(keyboardDone, id: "composer-keyboard-done")
        let chatNavigation = app.buttons["workspace-tab-chat"]
        XCTAssertTrue(waitUntil { !app.keyboards.firstMatch.exists && chatNavigation.exists && chatNavigation.isSelected })
        let chatRestored = chatNavigation.isSelected
        composer.tap()
        actions.append("tap:\(composerID)")
        XCTAssertTrue(waitUntil { composer.exists && composer.isEnabled && app.keyboards.firstMatch.exists })
        XCTAssertEqual(composer.value as? String, "Keep this draft")
        assertComposerVisible(composer, in: app)
        // The image remains the original bottom-of-help screen; completion is
        // explicitly a later live observation, not a different screenshot state.
        bottom.document["completion"] = [
            "source": "post-dismiss-live-XCUI-snapshot", "actions": actions,
            "settingsRestoredAfterClose": settingsRestored,
            "workspace": "chat", "workspaceSelected": chatRestored,
            "workspaceSelectionSource": "post-return-keyboard-dismissed-navigation",
            "draft": composer.value as? String ?? "", "keyboardVisible": app.keyboards.firstMatch.exists,
            "helpVisible": close.exists, "composerFrame": helpFrame(composer.frame),
            "keyboardFrame": helpFrame(app.keyboards.firstMatch.frame)
        ]
        try attachHelpSnapshot(bottom.image, document: bottom.document)
        app.terminate()
    }

    private func helpViewport(_ scroll: XCUIElement, app: XCUIApplication) -> CGRect {
        scroll.frame.intersection(app.frame).insetBy(dx: 0, dy: 8)
    }

    private func revealHelpContent(
        _ target: XCUIElement, in scroll: XCUIElement, app: XCUIApplication, isAction: Bool = false,
        preferPrevious: Bool = false
    ) {
        for _ in 0..<32 {
            XCTAssertTrue(scroll.exists)
            let viewport = helpViewport(scroll, app: app)
            XCTAssertGreaterThan(viewport.height, 44)
            var offset = preferPrevious ? -viewport.height : viewport.height
            if target.exists {
                let frame = target.frame
                let visible = frame.intersection(viewport)
                if isAction {
                    if viewport.contains(frame) && target.isHittable { return }
                } else if frame.width > 0 && frame.height > 0
                    && visible.width >= min(44, frame.width) && visible.height >= min(44, frame.height) {
                    return
                }
                if frame.width > 0 && frame.height > 0 { offset = frame.midY - viewport.midY }
            }
            let distance = min(max(abs(offset), 20), viewport.height * 0.45)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let upper = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - distance / 2))
            let lower = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + distance / 2))
            if offset >= 0 {
                lower.press(forDuration: 0.05, thenDragTo: upper, withVelocity: .slow, thenHoldForDuration: 0.2)
            } else {
                upper.press(forDuration: 0.05, thenDragTo: lower, withVelocity: .slow, thenHoldForDuration: 0.2)
            }
            actions.append(offset >= 0 ? "scroll:help-content-up" : "scroll:help-content-down")
        }
        attachDiagnostic("unreachable-help-content")
        XCTFail("Help content must enter its real scroll viewport; static paragraphs are not tap targets")
    }

    private func helpFrame(_ frame: CGRect) -> [String: Double] {
        ["x": frame.minX, "y": frame.minY, "width": frame.width, "height": frame.height]
    }

    private func helpSnapshot(
        _ app: XCUIApplication, accessibility: Bool, stage: String, initialDraft: String, sections: [[String: Any]]
    ) -> (image: XCUIScreenshot, document: [String: Any]) {
        let category = accessibility ? "accessibility5" : "large"
        var frames = ["settings-help-close": helpFrame(app.buttons["settings-help-close"].frame)]
        let repository = element(app, "settings-help-repository")
        if repository.exists { frames["settings-help-repository"] = helpFrame(repository.frame) }
        let document: [String: Any] = [
            "schemaVersion": 1, "source": "public-XCUITest-production-app",
            "name": "interaction-dark-\(category)-\(stage)", "theme": "dark",
            "dynamicTypeSize": category, "stage": stage,
            "systemContentSizeCategory": UIApplication.shared.preferredContentSizeCategory.rawValue,
            "screenWidth": app.frame.width, "screenHeight": app.frame.height,
            "keyboardVisible": app.keyboards.firstMatch.exists, "actions": actions, "draft": "",
            "frames": frames,
            "helpFlow": ["originalWorkspace": "chat", "initialDraft": initialDraft, "sections": sections],
            "realInferenceVerified": false, "signedDistributionVerified": false
        ]
        return (XCUIScreen.main.screenshot(), document)
    }

    private func attachHelpSnapshot(_ screenshot: XCUIScreenshot, document: [String: Any]) throws {
        let name = try XCTUnwrap(document["name"] as? String)
        let image = XCTAttachment(screenshot: screenshot)
        image.name = name
        image.lifetime = .keepAlways
        add(image)
        let provenance = XCTAttachment(data: try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys]),
                                       uniformTypeIdentifier: "public.json")
        provenance.name = name + "-provenance"
        provenance.lifetime = .keepAlways
        add(provenance)
    }

    private func assertSheet(_ app: XCUIApplication, startsLarge: Bool) {
        let close = app.buttons[closeID]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        assertReachableAction(close, inside: app.frame)
        assertReachableAction(app.buttons[manageID], inside: app.frame)
        let navigation = element(app, "compact-model-summary-heading")
        XCTAssertTrue(navigation.waitForExistence(timeout: 5))
        if startsLarge {
            XCTAssertTrue(waitUntil { navigation.frame.minY < app.frame.height * 0.25 })
        } else {
            XCTAssertGreaterThan(navigation.frame.minY, app.frame.height * 0.3)
        }
        XCTAssertTrue(element(app, "compact-model-overview").exists)
        XCTAssertFalse(element(app, "header-model-capsule").exists)
    }

    private func assertModels(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["model-selector-picker"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil { !app.buttons[self.closeID].exists })
        XCTAssertTrue(app.buttons["workspace-tab-models"].isSelected)
    }

    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        if id == detailsID { return app.buttons[id] }
        return app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func tap(_ control: XCUIElement, id: String) {
        XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing control: \(id)")
        if !control.isEnabled { attachDiagnostic("disabled-control-" + id) }
        XCTAssertTrue(control.isEnabled, "Disabled control: \(id)")
        if !control.isHittable { attachDiagnostic("unreachable-control-" + id) }
        XCTAssertTrue(control.isHittable, "Unreachable control: \(id)")
        control.tap()
        actions.append("tap:\(id)")
    }

    private enum ScrollDirection { case up, down }

    private func reveal(
        _ target: XCUIElement, in scroll: XCUIElement, app: XCUIApplication,
        direction: ScrollDirection = .up, requiresHitTarget: Bool = true
    ) {
        for _ in 0..<12 {
            XCTAssertTrue(scroll.exists)
            let top = app.buttons[closeID].frame.maxY + 8
            let bottom = app.buttons[manageID].frame.minY - 8
            let viewport = CGRect(x: scroll.frame.minX, y: top, width: scroll.frame.width, height: bottom - top)
            XCTAssertGreaterThan(viewport.height, 44)
            var actualDirection = direction
            var distance = viewport.height * 0.45
            if target.exists {
                let frame = target.frame
                if requiresHitTarget {
                    if frame.minY >= viewport.minY && frame.maxY <= viewport.maxY && target.isHittable { return }
                } else if frame.width > 0 && frame.height > 0 &&
                            (viewport.contains(frame) || frame.intersection(viewport).height >= min(44, frame.height)) {
                    return
                }
                let offset = frame.midY - viewport.midY
                actualDirection = offset < 0 ? .down : .up
                distance = min(max(abs(offset), 16), distance)
            }
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let upper = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - distance / 2))
            let lower = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + distance / 2))
            if actualDirection == .up {
                lower.press(forDuration: 0.05, thenDragTo: upper, withVelocity: .slow, thenHoldForDuration: 0.2)
            } else {
                upper.press(forDuration: 0.05, thenDragTo: lower, withVelocity: .slow, thenHoldForDuration: 0.2)
            }
            actions.append(actualDirection == .up ? "scroll:content-up" : "scroll:content-down")
        }
        attachDiagnostic("unreachable-scroll-content")
        XCTFail("Content must enter the real scroll viewport without tapping through the fixed header or footer")
    }

    private func assertReachableAction(_ action: XCUIElement, inside bounds: CGRect) {
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        let ready = waitUntil { action.isHittable && action.frame.width >= 44 && action.frame.height >= 44 }
        if !ready {
            attachDiagnostic("unreachable-or-small-action")
        }
        XCTAssertTrue(ready, "Wait for the real sheet transition to finish without reducing 44pt targets")
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThanOrEqual(action.frame.width, 44)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        XCTAssertGreaterThanOrEqual(action.frame.minX, bounds.minX)
        XCTAssertLessThanOrEqual(action.frame.maxX, bounds.maxX)
        XCTAssertLessThanOrEqual(action.frame.maxY, bounds.maxY)
    }

    private func assertComposerVisible(_ composer: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(composer.isEnabled)
        XCTAssertEqual(composer.value as? String, "Keep this draft")
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        XCTAssertGreaterThan(composer.frame.width, 0)
        XCTAssertGreaterThan(composer.frame.height, 0)
        XCTAssertTrue(app.frame.contains(composer.frame))
        XCTAssertLessThanOrEqual(composer.frame.maxY, app.keyboards.firstMatch.frame.minY)
    }

    private func attachDiagnostic(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "diagnostic-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
        let tree = XCTAttachment(string: XCUIApplication().debugDescription)
        tree.name = "diagnostic-public-accessibility-" + name
        tree.lifetime = .keepAlways
        add(tree)
    }

    private func waitUntil(_ predicate: @escaping () -> Bool) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in predicate() }, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }

    private func capture(_ app: XCUIApplication, theme: String, accessibility: Bool, stage: String) throws {
        let size = accessibility ? "accessibility5" : "large"
        let name = "interaction-\(theme)-\(size)-\(stage)"
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
        var frames: [String: [String: Double]] = [:]
        for id in [summaryID, closeID, detailsID, manageID, composerID, "compact-model-overview"] {
            let control = element(app, id)
            if control.exists {
                let frame = control.frame
                frames[id] = ["x": frame.minX, "y": frame.minY, "width": frame.width, "height": frame.height]
            }
        }
        let composer = element(app, composerID)
        let document: [String: Any] = [
            "schemaVersion": 1, "source": "public-XCUITest-production-app",
            "name": name, "theme": theme, "dynamicTypeSize": size, "stage": stage,
            "systemContentSizeCategory": UIApplication.shared.preferredContentSizeCategory.rawValue,
            "screenWidth": app.frame.width, "screenHeight": app.frame.height,
            "keyboardVisible": app.keyboards.firstMatch.exists,
            "actions": actions, "frames": frames,
            "draft": composer.exists ? (composer.value as? String ?? "") : "",
            "realInferenceVerified": false, "signedDistributionVerified": false
        ]
        let provenance = XCTAttachment(data: try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys]),
                                       uniformTypeIdentifier: "public.json")
        provenance.name = name + "-provenance"
        provenance.lifetime = .keepAlways
        add(provenance)
    }
}
