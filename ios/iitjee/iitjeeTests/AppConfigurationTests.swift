import Foundation
import SwiftUI
import Testing
@testable import iitjee

/// App Store identity, privacy declarations, appearance and legal pages.
@MainActor
struct AppConfigurationTests {
    @Test func appIdentityMatchesTheAppStoreListing() {
        let info = Bundle.main.infoDictionary ?? [:]
        #expect(Bundle.main.bundleIdentifier == "com.apoorvdarshan.iitjee")
        #expect(info["CFBundleDisplayName"] as? String == "PCM Notes")
        #expect(info["LSApplicationCategoryType"] as? String == "public.app-category.education")
        #expect((info["CFBundleShortVersionString"] as? String)?.isEmpty == false)
    }

    @Test func privacyManifestDeclaresUserDefaultsAndNoTracking() throws {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try #require(
            try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any]
        )
        #expect(plist["NSPrivacyTracking"] as? Bool == false)
        let apis = plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]] ?? []
        let userDefaults = apis.first {
            $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
        }
        #expect(userDefaults?["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])
    }

    @Test func appearanceChoicesMapToColorSchemes() {
        #expect(AppAppearance.allCases.map(\.rawValue) == ["system", "light", "dark"])
        #expect(AppAppearance.system.colorScheme == nil, "System follows the device")
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
        #expect(AppAppearance.allCases.map(\.title) == ["System", "Light", "Dark"])
        // ContentView falls back to System for anything else found in storage.
        #expect(AppAppearance(rawValue: "sepia") == nil)
        #expect(AppAppearance.storageKey == "app.appearance")
    }

    @Test func legalPagesHaveDistinctNonEmptySections() {
        for document in [LegalDocument.privacy, .terms] {
            let titles = document.sections.map(\.title)
            #expect(!titles.isEmpty)
            // The page lists sections by title, so titles must be unique.
            #expect(Set(titles).count == titles.count, "\(document.title) repeats a section title")
            #expect(document.sections.allSatisfy { !$0.body.isEmpty })
        }
        #expect(LegalDocument.privacy.sections.first?.title == "What the app stores")
        #expect(LegalDocument.terms.sections.first?.title == "Personal study use")
    }

    @Test func testControlsOnlyActForTestLaunches() {
        #expect(TestEnvironment.tipPurchaser(arguments: ["iitjee"], environment: [:]) == nil)
        #expect(TestEnvironment.isHostingTests(["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]))
        #expect(!TestEnvironment.isHostingTests(["HOME": "/Users/test"]))
        #expect(TestEnvironment.tipPurchaser(arguments: ["iitjee"], environment: ["XCTestBundlePath": "/x"]) is LocalTipPurchasing)
    }

    @Test func uiTestLaunchArgumentsChooseTheTipCatalogAndOutcome() async throws {
        let scripted = try #require(TestEnvironment.tipPurchaser(
            arguments: ["iitjee", "--ui-testing", "--ui-testing-tips=unavailable", "--ui-testing-tip-outcome=failed"],
            environment: [:]
        ))
        #expect(await scripted.loadOffers(for: TipProductID.allCases).isEmpty)
        #expect(await scripted.purchase(.small) == .failed)

        let standard = try #require(TestEnvironment.tipPurchaser(arguments: ["iitjee", "--ui-testing"], environment: [:]))
        #expect(await standard.loadOffers(for: TipProductID.allCases).count == 4)
        #expect(await standard.purchase(.small) == .purchased)
    }
}
