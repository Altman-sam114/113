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
