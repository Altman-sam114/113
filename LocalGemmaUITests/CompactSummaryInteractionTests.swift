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
        reveal(element(app, detailsID), in: scroll)
        tap(element(app, detailsID), id: detailsID)
        XCTAssertTrue(element(app, "header-model-capsule").waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntil { app.navigationBars["运行摘要"].frame.minY < app.frame.height * 0.25 })
        reveal(element(app, "header-model-capsule"), in: scroll)
        assertReachableAction(app.buttons[manageID], inside: app.frame)
        try capture(app, theme: theme, accessibility: accessibility, stage: "expanded")

        reveal(element(app, detailsID), in: scroll, direction: .down)
        tap(element(app, detailsID), id: detailsID)
        XCTAssertTrue(waitUntil { !self.element(app, "header-model-capsule").exists })
        XCTAssertLessThan(app.navigationBars["运行摘要"].frame.minY, app.frame.height * 0.25)
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
        let composer = element(app, composerID)
        XCTAssertTrue(waitUntil { composer.isEnabled && composer.isHittable })
        tap(composer, id: composerID)
        composer.typeText("Keep this draft")
        actions.append("type:local-draft-without-send")
        XCTAssertEqual(composer.value as? String, "Keep this draft")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
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
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        tap(app.buttons["workspace-tab-chat"], id: "workspace-tab-chat")
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertEqual(composer.value as? String, "Keep this draft")
        XCTAssertTrue(waitUntil { composer.isHittable && app.keyboards.firstMatch.exists })
        try capture(app, theme: "dark", accessibility: accessibility, stage: "draft-returned")
        app.terminate()
    }

    private func assertSheet(_ app: XCUIApplication, startsLarge: Bool) {
        let close = app.buttons[closeID]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        assertReachableAction(close, inside: app.frame)
        assertReachableAction(app.buttons[manageID], inside: app.frame)
        let navigation = app.navigationBars["运行摘要"]
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
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func tap(_ control: XCUIElement, id: String) {
        XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing control: \(id)")
        XCTAssertTrue(control.isHittable, "Unreachable control: \(id)")
        control.tap()
        actions.append("tap:\(id)")
    }

    private enum ScrollDirection { case up, down }

    private func reveal(_ target: XCUIElement, in scroll: XCUIElement, direction: ScrollDirection = .up) {
        for _ in 0..<8 {
            if target.exists && target.isHittable { return }
            XCTAssertTrue(scroll.exists)
            if direction == .up { scroll.swipeUp() } else { scroll.swipeDown() }
            actions.append(direction == .up ? "scroll:up" : "scroll:down")
        }
        XCTAssertTrue(target.isHittable, "Scroll content must remain reachable")
    }

    private func assertReachableAction(_ action: XCUIElement, inside bounds: CGRect) {
        XCTAssertTrue(action.waitForExistence(timeout: 5))
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThanOrEqual(action.frame.width, 44)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        XCTAssertGreaterThanOrEqual(action.frame.minX, bounds.minX)
        XCTAssertLessThanOrEqual(action.frame.maxX, bounds.maxX)
        XCTAssertLessThanOrEqual(action.frame.maxY, bounds.maxY)
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
