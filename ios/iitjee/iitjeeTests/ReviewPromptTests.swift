import Foundation
import Testing
@testable import iitjee

/// When PCM Notes asks for an App Store rating: Support's Rate button, and the
/// automatic prompt after a good reading session.
@MainActor
struct ReviewPromptTests {
    private let day: TimeInterval = 24 * 60 * 60
    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return calendar
    }()

    /// A private defaults domain for one test.
    private func makeDefaults() -> UserDefaults {
        let suite = "ReviewPromptTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    /// Opens the app once on each of `days` consecutive days, starting at `start`.
    private func openApp(onDays days: Int, defaults: UserDefaults) {
        for offset in 0..<days {
            ReviewPrompt.recordAppOpen(now: start.addingTimeInterval(Double(offset) * day), calendar: calendar, defaults: defaults)
        }
    }

    // MARK: - Rate button

    @Test func rateButtonRequestsThePromptFirstAndThenOpensTheReviewPage() {
        #expect(ReviewPrompt.shouldRequestInAppPrompt(lastRequest: 0, now: start))
        let anHourAgo = start.timeIntervalSince1970 - 3600
        let justInside = start.timeIntervalSince1970 - ReviewPrompt.interval + 1
        let intervalAgo = start.timeIntervalSince1970 - ReviewPrompt.interval
        #expect(!ReviewPrompt.shouldRequestInAppPrompt(lastRequest: anHourAgo, now: start))
        #expect(!ReviewPrompt.shouldRequestInAppPrompt(lastRequest: justInside, now: start))
        #expect(ReviewPrompt.shouldRequestInAppPrompt(lastRequest: intervalAgo, now: start))
    }

    @Test func intervalAllowsAtMostThreeRequestsAYear() {
        #expect(365 * day / ReviewPrompt.interval < 3)
    }

    // MARK: - Usage

    @Test func appOpensCountDifferentDaysAndKeepTheFirstLaunch() {
        let defaults = makeDefaults()
        ReviewPrompt.recordAppOpen(now: start, calendar: calendar, defaults: defaults)
        ReviewPrompt.recordAppOpen(now: start.addingTimeInterval(3600), calendar: calendar, defaults: defaults)
        #expect(defaults.integer(forKey: ReviewPrompt.Key.usageDayCount) == 1)
        ReviewPrompt.recordAppOpen(now: start.addingTimeInterval(day), calendar: calendar, defaults: defaults)
        #expect(defaults.integer(forKey: ReviewPrompt.Key.usageDayCount) == 2)
        #expect(defaults.double(forKey: ReviewPrompt.Key.firstLaunch) == start.timeIntervalSince1970)
    }

    @Test func goodSessionsAreTenPagesOrAFinishedChapter() {
        #expect(ReviewPrompt.isGoodSession(pagesViewed: 10, reachedEnd: false))
        #expect(!ReviewPrompt.isGoodSession(pagesViewed: 9, reachedEnd: false))
        #expect(ReviewPrompt.isGoodSession(pagesViewed: 3, reachedEnd: true))
        #expect(!ReviewPrompt.isGoodSession(pagesViewed: 2, reachedEnd: true))
    }

    // MARK: - Automatic prompt

    @Test func autoPromptWaitsForThreeDaysOfUseAndTwoDaysSinceFirstLaunch() {
        let defaults = makeDefaults()
        openApp(onDays: 2, defaults: defaults)
        // Two days of use is not enough, however long ago the first launch was.
        #expect(!ReviewPrompt.shouldAutoRequest(now: start.addingTimeInterval(5 * day), version: "1.1", defaults: defaults))
        ReviewPrompt.recordAppOpen(now: start.addingTimeInterval(2 * day), calendar: calendar, defaults: defaults)
        #expect(defaults.integer(forKey: ReviewPrompt.Key.usageDayCount) == 3)
        #expect(ReviewPrompt.shouldAutoRequest(now: start.addingTimeInterval(2 * day), version: "1.1", defaults: defaults))
        // Three days of use, but less than two days since the first launch.
        #expect(!ReviewPrompt.shouldAutoRequest(now: start.addingTimeInterval(day), version: "1.1", defaults: defaults))
    }

    @Test func autoPromptHappensOncePerVersionAndRespectsTheInterval() {
        let defaults = makeDefaults()
        openApp(onDays: 3, defaults: defaults)
        let asked = start.addingTimeInterval(3 * day)
        ReviewPrompt.recordRequest(now: asked, version: "1.1", defaults: defaults)
        // Same version: never again, even after the interval.
        #expect(!ReviewPrompt.shouldAutoRequest(now: asked.addingTimeInterval(ReviewPrompt.interval), version: "1.1", defaults: defaults))
        // A new version: only once the interval has passed.
        #expect(!ReviewPrompt.shouldAutoRequest(now: asked.addingTimeInterval(day), version: "1.2", defaults: defaults))
        #expect(ReviewPrompt.shouldAutoRequest(now: asked.addingTimeInterval(ReviewPrompt.interval), version: "1.2", defaults: defaults))
    }

    @Test func rateButtonRequestBlocksTheAutoPromptToo() {
        let defaults = makeDefaults()
        openApp(onDays: 3, defaults: defaults)
        let tapped = start.addingTimeInterval(3 * day)
        ReviewPrompt.recordRequest(now: tapped, version: "1.0", defaults: defaults)
        #expect(!ReviewPrompt.shouldAutoRequest(now: tapped.addingTimeInterval(day), version: "1.1", defaults: defaults))
    }

    @Test func noAutoPromptWithoutARecordedFirstLaunch() {
        #expect(!ReviewPrompt.shouldAutoRequest(now: start, version: "1.0", defaults: makeDefaults()))
    }
}
