import UIKit
import XCTest

/// The iPad-only reading layout. scripts/test-ios.sh runs this class on an iPad
/// simulator and every other UI test on an iPhone, so each runs exactly once.
final class iPadReaderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Two-page reading is intentionally limited to iPad.")
        }
    }

    @MainActor
    func testIPadTwoPageLayoutIsAvailable() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        let firstChapter = app.chapter("physics", 1)
        let closeReader = app.buttons["Close focus reader"]

        XCTAssertTrue(firstChapter.waitForExistence(timeout: launchTimeout))
        firstChapter.tap()

        XCTAssertTrue(closeReader.waitForExistence(timeout: launchTimeout))

        let layoutMenu = app.buttons["reader.layoutMenu"]
        XCTAssertTrue(layoutMenu.waitForExistence(timeout: stepTimeout))
        XCTAssertEqual(layoutMenu.value as? String, "Continuous")

        layoutMenu.tap()

        let twoPageOption = app.descendants(matching: .any)["Two-page spread"]
        XCTAssertTrue(twoPageOption.waitForExistence(timeout: stepTimeout))
        twoPageOption.tap()

        let layoutChanged = NSPredicate(
            format: "value == %@",
            "Two-page spread"
        )
        expectation(for: layoutChanged, evaluatedWith: layoutMenu)
        waitForExpectations(timeout: stepTimeout)
    }

    @MainActor
    func testTwoPageSpreadPagesByPairsAndIsRemembered() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        app.openChapter("physics", 1, expecting: "Page 1 of 9")
        let layoutMenu = app.buttons["reader.layoutMenu"]
        XCTAssertTrue(layoutMenu.waitForExistence(timeout: stepTimeout))
        layoutMenu.tap()
        let twoPageOption = app.descendants(matching: .any)["Two-page spread"]
        XCTAssertTrue(twoPageOption.waitForExistence(timeout: stepTimeout))
        twoPageOption.tap()
        XCTAssertTrue(layoutMenu.waitForValue("Two-page spread"))

        let slider = app.sliders["reader.pageSlider"]
        let next = app.buttons["Next page"]
        // Page 1 stands alone like a cover, then pages pair up.
        XCTAssertTrue(slider.waitForValue("Page 1 of 9"))
        next.tap()
        XCTAssertTrue(slider.waitForValue("Pages 2 through 3 of 9"))
        XCTAssertTrue(app.staticTexts["2–3 / 9"].exists)
        next.tap()
        XCTAssertTrue(slider.waitForValue("Pages 4 through 5 of 9"))

        app.buttons["Close focus reader"].tap()
        let row = app.chapter("physics", 1)
        XCTAssertTrue(row.waitForExistence(timeout: stepTimeout))

        // Reopening keeps both the layout and the reading position.
        app.openChapter("physics", 1, expecting: "Pages 4 through 5 of 9")
        XCTAssertTrue(layoutMenu.waitForValue("Two-page spread"))
    }
}
