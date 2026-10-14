import XCTest

/// How the app's local tip store behaves for a UI test launch (TestEnvironment in the app).
enum TipCatalog: String {
    case ready
    case unavailable
    /// The first price load fails, as when offline; Retry succeeds.
    case unavailableThenReady = "unavailable-then-ready"
}

enum TipOutcome: String {
    case purchased
    case cancelled
    case pending
    case failed
}

/// Generous enough for a cold launch on a CI simulator; passing tests never wait it out.
let launchTimeout: TimeInterval = 30
let stepTimeout: TimeInterval = 10

@MainActor
extension XCUIApplication {
    /// A Debug simulator launch with no saved reading progress or preferences and a
    /// local tip store, so nothing touches the network, RevenueCat or the App Store.
    static func pcmNotes(
        tips: TipCatalog = .ready,
        tipOutcome: TipOutcome = .purchased
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-testing-reset",
            "--ui-testing-tips=\(tips.rawValue)",
            "--ui-testing-tip-outcome=\(tipOutcome.rawValue)",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        return app
    }

    /// Quits and relaunches the app, keeping everything the previous launch saved.
    func relaunchKeepingData() {
        terminate()
        launchArguments.removeAll { $0 == "--ui-testing-reset" }
        launch()
    }

    func chapter(_ subject: String, _ number: Int) -> XCUIElement {
        buttons["chapter.\(subject).\(number)"]
    }

    func openTab(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let tab = tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: launchTimeout), "Missing \(name) tab", file: file, line: line)
        tab.tap()
    }

    /// The element of any type whose accessibility label is exactly `label`.
    func element(labeled label: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Scrolls the current screen until `element` can be tapped. Each `isHittable`
    /// check takes an accessibility snapshot, so it stops as soon as it can.
    func reveal(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        if element.isHittable { return }
        for upward in [true, false] {
            for _ in 0..<12 {
                if upward { swipeUp() } else { swipeDown() }
                if element.isHittable { return }
            }
        }
        XCTFail("Cannot reach \(element.identifier)", file: file, line: line)
    }

    /// Opens a chapter and waits until its PDF has reported its pages.
    func openChapter(
        _ subject: String,
        _ number: Int,
        expecting position: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = chapter(subject, number)
        XCTAssertTrue(row.waitForExistence(timeout: launchTimeout), file: file, line: line)
        reveal(row, file: file, line: line)
        row.tap()
        XCTAssertTrue(
            sliders["reader.pageSlider"].waitForValue(position, timeout: launchTimeout),
            "Reader did not open at \(position): \(String(describing: sliders["reader.pageSlider"].value))",
            file: file,
            line: line
        )
    }
}

@MainActor
extension XCUIElement {
    /// Waits until the accessibility value is exactly `value`.
    func waitForValue(_ value: String, timeout: TimeInterval = stepTimeout) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", value),
            object: self
        )
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits until the accessibility label is exactly `label`.
    func waitForLabel(_ label: String, timeout: TimeInterval = stepTimeout) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: self
        )
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
