//
//  iitjeeUITests.swift
//  iitjeeUITests
//
//  Created by Apoorv Darshan on 20/07/26.
//

import XCTest

/// The main journeys on iPhone: tabs, subject indexes, search, the offline reader
/// and its saved progress, appearance, support with the tip jar, and About.
/// Each test starts from a fresh launch (see `XCUIApplication.pcmNotes`).
final class iitjeeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Navigation

    @MainActor
    func testFivePrimaryTabsAreReachable() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: launchTimeout))

        for tabName in ["Physics", "Chemistry", "Maths", "Support", "About"] {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.exists, "Missing \(tabName) tab")
            tab.tap()
        }

        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: stepTimeout))
    }

    @MainActor
    func testTabBarStaysExpandedWhileScrolling() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: launchTimeout))
        XCTAssertTrue(app.chapter("physics", 1).waitForExistence(timeout: launchTimeout))

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
    func testEachSubjectTabListsItsChapterIndex() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        let subjects: [(tab: String, slug: String, title: String, chapters: Int, firstChapter: String, pages: String)] = [
            ("Physics", "physics", "Physics", 23, "Chapter 1, Vectors", "9 pages · offline PDF"),
            ("Chemistry", "chemistry", "Chemistry", 37, "Chapter 1, Some Basic Concepts of Chemistry", "81 pages · offline PDF"),
            ("Maths", "mathematics", "Mathematics", 31, "Chapter 1, Set, Relation & Function", "58 pages · offline PDF"),
        ]
        for subject in subjects {
            app.openTab(subject.tab)
            let firstRow = app.chapter(subject.slug, 1)
            XCTAssertTrue(firstRow.waitForExistence(timeout: launchTimeout), "\(subject.tab) has no chapter list")
            XCTAssertEqual(firstRow.label, subject.firstChapter)
            XCTAssertEqual(firstRow.value as? String, subject.pages)
            XCTAssertTrue(app.staticTexts[subject.title].exists, "Missing \(subject.title) heading")
            XCTAssertTrue(
                app.element(labeled: "Chapter index, \(subject.chapters) total").exists,
                "\(subject.tab) should list \(subject.chapters) chapters"
            )
        }
    }

    @MainActor
    func testChapterSearchFiltersByTitleAndNumber() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()
        XCTAssertTrue(app.chapter("physics", 1).waitForExistence(timeout: launchTimeout))

        let search = app.searchFields.firstMatch
        if !search.waitForExistence(timeout: stepTimeout) {
            app.swipeDown()  // the search bar can sit collapsed under the navigation bar
        }
        XCTAssertTrue(search.waitForExistence(timeout: stepTimeout))
        search.tap()

        search.typeText("kinematics")
        XCTAssertTrue(app.element(labeled: "Chapter index, 1 shown").waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(app.chapter("physics", 3).exists)
        XCTAssertFalse(app.chapter("physics", 1).exists)

        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "kinematics".count))
        search.typeText("19")
        XCTAssertTrue(app.element(labeled: "Chapter index, 1 shown").waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(app.chapter("physics", 19).waitForExistence(timeout: stepTimeout))
        XCTAssertEqual(app.chapter("physics", 19).label, "Chapter 19, Optics")

        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2))
        search.typeText("biology")
        XCTAssertTrue(app.element(labeled: "Chapter index, 0 shown").waitForExistence(timeout: stepTimeout))
        XCTAssertFalse(app.chapter("physics", 19).exists)

        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "biology".count))
        XCTAssertTrue(app.element(labeled: "Chapter index, 23 total").waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(app.chapter("physics", 1).exists)
    }

    // MARK: - Reader

    @MainActor
    func testOfflinePDFReaderClosesDirectlyToChapterList() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        let firstChapter = app.chapter("physics", 1)
        let closeReader = app.buttons["Close focus reader"]
        let pageSlider = app.sliders["reader.pageSlider"]

        XCTAssertTrue(firstChapter.waitForExistence(timeout: launchTimeout))
        firstChapter.tap()

        XCTAssertTrue(closeReader.waitForExistence(timeout: launchTimeout))
        XCTAssertTrue(pageSlider.waitForExistence(timeout: stepTimeout))

        closeReader.tap()

        XCTAssertTrue(closeReader.waitForNonExistence(timeout: stepTimeout))
        XCTAssertTrue(pageSlider.waitForNonExistence(timeout: stepTimeout))
        XCTAssertTrue(firstChapter.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(firstChapter.isHittable)
        XCTAssertFalse(app.buttons["Open focus reader"].exists)

        firstChapter.tap()
        XCTAssertTrue(closeReader.waitForExistence(timeout: launchTimeout))
    }

    @MainActor
    func testReaderPagesJumpsAndResumesAfterRelaunch() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        let row = app.chapter("physics", 1)
        XCTAssertTrue(row.waitForExistence(timeout: launchTimeout))
        XCTAssertEqual(row.value as? String, "9 pages · offline PDF")

        app.openChapter("physics", 1, expecting: "Page 1 of 9")
        let slider = app.sliders["reader.pageSlider"]
        let previous = app.buttons["Previous page"]
        let next = app.buttons["Next page"]
        XCTAssertFalse(previous.isEnabled, "page 1 has nothing before it")

        next.tap()
        XCTAssertTrue(slider.waitForValue("Page 2 of 9"))
        next.tap()
        XCTAssertTrue(slider.waitForValue("Page 3 of 9"))
        XCTAssertTrue(app.staticTexts["3 / 9"].exists)
        previous.tap()
        XCTAssertTrue(slider.waitForValue("Page 2 of 9"))

        slider.adjust(toNormalizedSliderPosition: 1)
        XCTAssertTrue(slider.waitForValue("Page 9 of 9"))
        XCTAssertFalse(next.isEnabled, "the last page has nothing after it")
        previous.tap()
        XCTAssertTrue(slider.waitForValue("Page 8 of 9"))

        app.buttons["Close focus reader"].tap()
        XCTAssertTrue(row.waitForValue("Resume page 8 of 9"))

        app.relaunchKeepingData()
        XCTAssertTrue(row.waitForExistence(timeout: launchTimeout))
        XCTAssertTrue(row.waitForValue("Resume page 8 of 9"), "progress must survive a relaunch")
        app.openChapter("physics", 1, expecting: "Page 8 of 9")
    }

    // MARK: - Appearance

    @MainActor
    func testAppearanceSelectorOffersSystemLightAndDark() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        app.openTab("About")

        let systemChoice = app.buttons["appearance.system"]
        let lightChoice = app.buttons["appearance.light"]
        let darkChoice = app.buttons["appearance.dark"]

        XCTAssertTrue(darkChoice.waitForExistence(timeout: stepTimeout))
        app.reveal(darkChoice)

        XCTAssertTrue(systemChoice.isHittable)
        XCTAssertTrue(lightChoice.isHittable)
        XCTAssertTrue(darkChoice.isHittable)
        XCTAssertEqual(systemChoice.value as? String, "Selected", "System is the default")

        darkChoice.tap()
        XCTAssertEqual(darkChoice.value as? String, "Selected")

        lightChoice.tap()
        XCTAssertEqual(lightChoice.value as? String, "Selected")

        systemChoice.tap()
        XCTAssertEqual(systemChoice.value as? String, "Selected")
    }

    @MainActor
    func testAppearanceChoiceSurvivesRelaunch() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        app.openTab("About")
        let darkChoice = app.buttons["appearance.dark"]
        XCTAssertTrue(darkChoice.waitForExistence(timeout: stepTimeout))
        app.reveal(darkChoice)
        darkChoice.tap()
        XCTAssertEqual(darkChoice.value as? String, "Selected")

        app.relaunchKeepingData()
        app.openTab("About")
        XCTAssertTrue(darkChoice.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(darkChoice.waitForValue("Selected"), "Dark must still be chosen after a relaunch")
        XCTAssertEqual(app.buttons["appearance.system"].value as? String, "Not selected")
    }

    // MARK: - Support and tips (local tip store: nothing is charged)

    @MainActor
    func testSupportShowsContactsAndOptionalTips() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        app.openTab("Support")

        let studyEmail = app.descendants(matching: .any)["support.email.study"]
        let creatorEmail = app.descendants(matching: .any)["support.email.creator"]
        let xProfile = app.descendants(matching: .any)["support.x"]

        XCTAssertTrue(studyEmail.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(creatorEmail.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(xProfile.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(app.staticTexts["ad13dtu@gmail.com"].exists)
        XCTAssertTrue(app.staticTexts["apoorvdarshan@gmail.com"].exists)
        XCTAssertTrue(app.staticTexts["@apoorvdarshan"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["tip.disclosure"].waitForExistence(timeout: stepTimeout))

        let prices = ["small": "Small Tip, ₹49", "medium": "Chai Tip, ₹99",
                      "large": "Study Fuel, ₹199", "generous": "Notebook Hero, ₹499"]
        for tier in ["small", "medium", "large", "generous"] {
            let tipButton = app.buttons["tip.product.\(tier)"]
            XCTAssertTrue(
                tipButton.waitForExistence(timeout: stepTimeout),
                "Missing repeatable \(tier) tip"
            )
            XCTAssertTrue(tipButton.waitForLabel(prices[tier]!), "\(tier) shows \(tipButton.label)")
            XCTAssertTrue(tipButton.isEnabled)
        }
    }

    @MainActor
    func testTipPurchaseThanksTheReaderAndCanBeDismissed() throws {
        let app = XCUIApplication.pcmNotes(tipOutcome: .purchased)
        app.launch()

        app.openTab("Support")
        let chaiTip = app.buttons["tip.product.medium"]
        XCTAssertTrue(chaiTip.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(chaiTip.waitForLabel("Chai Tip, ₹99"))
        app.reveal(chaiTip)
        chaiTip.tap()

        let thanks = app.staticTexts["Thank you—your tip helps keep PCM Notes free, ad-free, and improving."]
        XCTAssertTrue(thanks.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(chaiTip.isEnabled, "tips are repeatable")

        app.buttons["Dismiss tip status"].tap()
        XCTAssertTrue(thanks.waitForNonExistence(timeout: stepTimeout))
    }

    @MainActor
    func testTipJarRecoversWhenPricesAreUnavailable() throws {
        let app = XCUIApplication.pcmNotes(tips: .unavailableThenReady)
        app.launch()

        app.openTab("Support")
        let smallTip = app.buttons["tip.product.small"]
        XCTAssertTrue(smallTip.waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(smallTip.waitForLabel("Small Tip, unavailable"))
        XCTAssertFalse(smallTip.isEnabled, "a tip without a price cannot be bought")
        XCTAssertTrue(app.staticTexts["Tip prices are unavailable right now."].exists)

        let retry = app.buttons["tip.retry"]
        app.reveal(retry)
        retry.tap()

        XCTAssertTrue(smallTip.waitForLabel("Small Tip, ₹49"))
        XCTAssertTrue(smallTip.isEnabled)
        XCTAssertTrue(app.staticTexts["Tip prices are unavailable right now."].waitForNonExistence(timeout: stepTimeout))
    }

    // MARK: - About

    @MainActor
    func testAboutShowsInAppLegalPages() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        app.openTab("About")

        let privacyLink = app.descendants(matching: .any)["legal.privacy"]
        XCTAssertTrue(privacyLink.waitForExistence(timeout: stepTimeout))
        app.reveal(privacyLink)
        privacyLink.tap()

        XCTAssertTrue(app.navigationBars["Privacy Policy"].waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(app.staticTexts["NO TRACKING"].exists)
        XCTAssertTrue(app.staticTexts["What the app stores"].exists)

        app.navigationBars.buttons["About"].tap()

        let termsLink = app.descendants(matching: .any)["legal.terms"]
        XCTAssertTrue(termsLink.waitForExistence(timeout: stepTimeout))
        app.reveal(termsLink)
        termsLink.tap()

        XCTAssertTrue(app.navigationBars["Terms of Use"].waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(app.staticTexts["PERSONAL STUDY"].exists)
        XCTAssertTrue(app.staticTexts["Personal study use"].exists)
    }

    @MainActor
    func testAboutSummarisesTheArchiveAndVersion() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        app.openTab("About")
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: stepTimeout))

        for summary in ["23 chapters · 539 pages", "37 chapters · 993 pages", "31 chapters · 641 pages"] {
            let row = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", summary)).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: stepTimeout), "About is missing \(summary)")
        }

        let version = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Version '")).firstMatch
        app.reveal(version)
        XCTAssertNotNil(
            version.label.range(of: #"^Version \d+(\.\d+)* \(\d+\)$"#, options: .regularExpression),
            "unexpected version text \(version.label)"
        )
    }
}
