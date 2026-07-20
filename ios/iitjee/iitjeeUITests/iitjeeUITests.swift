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
    func testTabBarStaysExpandedWhileScrolling() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["chapter.physics.1"].waitForExistence(timeout: 8))

        app.swipeUp()
        app.swipeUp()
        app.swipeUp()

        for tabName in ["Physics", "Chemistry", "Maths", "Support", "About"] {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.exists, "Missing \(tabName) tab after scrolling")
            XCTAssertTrue(tab.isHittable, "Collapsed \(tabName) tab after scrolling")
        }
    }

    @MainActor
    func testOfflinePDFReaderClosesDirectlyToChapterList() throws {
        let app = XCUIApplication()
        app.launch()

        let firstChapter = app.buttons["chapter.physics.1"]
        let closeReader = app.buttons["Close focus reader"]
        let pageSlider = app.sliders["reader.pageSlider"]

        XCTAssertTrue(firstChapter.waitForExistence(timeout: 8))
        firstChapter.tap()

        XCTAssertTrue(closeReader.waitForExistence(timeout: 12))
        XCTAssertTrue(pageSlider.waitForExistence(timeout: 5))

        closeReader.tap()

        XCTAssertTrue(closeReader.waitForNonExistence(timeout: 5))
        XCTAssertTrue(pageSlider.waitForNonExistence(timeout: 5))
        XCTAssertTrue(firstChapter.waitForExistence(timeout: 5))
        XCTAssertTrue(firstChapter.isHittable)
        XCTAssertFalse(app.buttons["Open focus reader"].exists)

        firstChapter.tap()
        XCTAssertTrue(closeReader.waitForExistence(timeout: 12))
    }

    @MainActor
    func testIPadTwoPageLayoutIsAvailable() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Two-page reading is intentionally limited to iPad.")
        }

        let app = XCUIApplication()
        app.launch()

        let firstChapter = app.buttons["chapter.physics.1"]
        let closeReader = app.buttons["Close focus reader"]

        XCTAssertTrue(firstChapter.waitForExistence(timeout: 8))
        firstChapter.tap()

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
    func testAppearanceSelectorOffersSystemLightAndDark() throws {
        let app = XCUIApplication()
        app.launch()

        let aboutTab = app.tabBars.buttons["About"]
        XCTAssertTrue(aboutTab.waitForExistence(timeout: 5))
        aboutTab.tap()

        let systemChoice = app.buttons["appearance.system"]
        let lightChoice = app.buttons["appearance.light"]
        let darkChoice = app.buttons["appearance.dark"]

        for _ in 0..<8 where !darkChoice.isHittable {
            app.swipeUp()
        }

        XCTAssertTrue(systemChoice.isHittable)
        XCTAssertTrue(lightChoice.isHittable)
        XCTAssertTrue(darkChoice.isHittable)

        darkChoice.tap()
        XCTAssertEqual(darkChoice.value as? String, "Selected")

        lightChoice.tap()
        XCTAssertEqual(lightChoice.value as? String, "Selected")

        systemChoice.tap()
        XCTAssertEqual(systemChoice.value as? String, "Selected")
    }

    @MainActor
    func testSupportShowsContactsAndOptionalTips() throws {
        let app = XCUIApplication()
        app.launch()

        let supportTab = app.tabBars.buttons["Support"]
        XCTAssertTrue(supportTab.waitForExistence(timeout: 5))
        supportTab.tap()

        let studyEmail = app.descendants(matching: .any)["support.email.study"]
        let creatorEmail = app.descendants(matching: .any)["support.email.creator"]
        let xProfile = app.descendants(matching: .any)["support.x"]

        XCTAssertTrue(studyEmail.waitForExistence(timeout: 5))
        XCTAssertTrue(creatorEmail.waitForExistence(timeout: 5))
        XCTAssertTrue(xProfile.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ad13dtu@gmail.com"].exists)
        XCTAssertTrue(app.staticTexts["apoorvdarshan@gmail.com"].exists)
        XCTAssertTrue(app.staticTexts["@apoorvdarshan"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["tip.disclosure"].waitForExistence(timeout: 5))

        for tier in ["small", "medium", "large", "generous"] {
            let tipButton = app.buttons["tip.product.\(tier)"]
            XCTAssertTrue(
                tipButton.waitForExistence(timeout: 8),
                "Missing repeatable \(tier) tip"
            )
        }
    }

    @MainActor
    func testAboutShowsInAppLegalPages() throws {
        let app = XCUIApplication()
        app.launch()

        let aboutTab = app.tabBars.buttons["About"]
        XCTAssertTrue(aboutTab.waitForExistence(timeout: 5))
        aboutTab.tap()

        let privacyLink = app.descendants(matching: .any)["legal.privacy"]
        for _ in 0..<10 where !privacyLink.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(privacyLink.isHittable)
        privacyLink.tap()

        XCTAssertTrue(app.navigationBars["Privacy Policy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NO TRACKING"].exists)
        XCTAssertTrue(app.staticTexts["What the app stores"].exists)

        app.navigationBars.buttons["About"].tap()

        let termsLink = app.descendants(matching: .any)["legal.terms"]
        for _ in 0..<10 where !termsLink.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(termsLink.isHittable)
        termsLink.tap()

        XCTAssertTrue(app.navigationBars["Terms of Use"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["PERSONAL STUDY"].exists)
        XCTAssertTrue(app.staticTexts["Personal study use"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
