//
//  iitjeeUITestsLaunchTests.swift
//  iitjeeUITests
//
//  Created by Apoorv Darshan on 20/07/26.
//

import XCTest

final class iitjeeUITestsLaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A fresh launch opens Physics straight into its chapter index.
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication.pcmNotes()
        app.launch()

        let physicsTab = app.tabBars.buttons["Physics"]
        XCTAssertTrue(physicsTab.waitForExistence(timeout: launchTimeout))
        XCTAssertTrue(physicsTab.isSelected, "Physics is the first tab")
        XCTAssertTrue(app.navigationBars["PCM Notes"].exists)
        XCTAssertTrue(app.element(labeled: "Chapter index, 23 total").waitForExistence(timeout: stepTimeout))
        XCTAssertTrue(app.chapter("physics", 1).isHittable)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
