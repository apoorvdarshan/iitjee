//
//  iitjeeUITests.swift
//  iitjeeUITests
//
//  Created by Apoorv Darshan on 20/07/26.
//

import XCTest
import UIKit

final class iitjeeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testFivePrimaryTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        for tabName in ["Physics", "Chemistry", "Maths", "Support", "About"] {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.exists, "Missing \(tabName) tab")
            tab.tap()
        }

        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testOfflinePDFReaderOpens() throws {
        let app = XCUIApplication()
        app.launch()

        let closeReader = app.buttons["Close focus reader"]
        if !closeReader.waitForExistence(timeout: 2) {
            let firstChapter = app.buttons["chapter.physics.1"]
            XCTAssertTrue(firstChapter.waitForExistence(timeout: 8))
            firstChapter.tap()
        }

        XCTAssertTrue(closeReader.waitForExistence(timeout: 12))
        XCTAssertTrue(app.sliders["reader.pageSlider"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testIPadTwoPageLayoutIsAvailable() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Two-page reading is intentionally limited to iPad.")
        }

        let app = XCUIApplication()
        app.launch()

        let closeReader = app.buttons["Close focus reader"]
        if !closeReader.waitForExistence(timeout: 2) {
            let firstChapter = app.buttons["chapter.physics.1"]
            XCTAssertTrue(firstChapter.waitForExistence(timeout: 8))
            firstChapter.tap()
        }

        XCTAssertTrue(closeReader.waitForExistence(timeout: 12))

        let layoutMenu = app.buttons["reader.layoutMenu"]
        XCTAssertTrue(layoutMenu.waitForExistence(timeout: 5))

        layoutMenu.tap()

        let twoPageOption = app.descendants(matching: .any)["Two-page spread"]
        XCTAssertTrue(twoPageOption.waitForExistence(timeout: 5))
        twoPageOption.tap()

        let layoutChanged = NSPredicate(
            format: "value == %@",
            "Two-page spread"
        )
        expectation(for: layoutChanged, evaluatedWith: layoutMenu)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
