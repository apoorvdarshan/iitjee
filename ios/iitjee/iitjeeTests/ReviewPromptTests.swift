import Foundation
import Testing
@testable import iitjee

/// When Support's Rate button shows Apple's in-app prompt instead of the App Store page.
@MainActor
struct ReviewPromptTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func firstTapRequestsTheInAppPrompt() {
        #expect(ReviewPrompt.shouldRequestInAppPrompt(lastRequest: 0, now: now))
    }

    @Test func tapsSoonAfterARequestOpenTheReviewPage() {
        let anHourAgo = now.timeIntervalSince1970 - 3600
        let justInside = now.timeIntervalSince1970 - ReviewPrompt.interval + 1
        #expect(!ReviewPrompt.shouldRequestInAppPrompt(lastRequest: anHourAgo, now: now))
        #expect(!ReviewPrompt.shouldRequestInAppPrompt(lastRequest: justInside, now: now))
    }

    @Test func thePromptCanBeRequestedAgainAfterTheInterval() {
        let intervalAgo = now.timeIntervalSince1970 - ReviewPrompt.interval
        #expect(ReviewPrompt.shouldRequestInAppPrompt(lastRequest: intervalAgo, now: now))
    }

    @Test func intervalAllowsAtMostThreeRequestsAYear() {
        #expect(365 * 24 * 60 * 60 / ReviewPrompt.interval < 3.0)
    }
}
