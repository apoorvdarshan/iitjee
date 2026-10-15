import Foundation

/// When PCM Notes asks for an App Store rating with Apple's in-app prompt. iOS shows
/// that prompt at most three times a year and may skip it silently.
///
/// - Support's Rate button requests the prompt unless one was requested in the last
///   `interval`; then it opens the App Store review page, so the button always does
///   something visible.
/// - Automatically, the prompt is requested only on returning to the chapter list
///   after a good reading session (`isGoodSession`), once the app has been opened on
///   `usageDays` different days and `minimumAge` has passed since its first launch,
///   at most once per app version and never within `interval` of an earlier
///   request. Never at launch or while reading.
enum ReviewPrompt {
    static let interval: TimeInterval = 122 * 24 * 60 * 60
    static let usageDays = 3
    static let minimumAge: TimeInterval = 2 * 24 * 60 * 60
    static let sessionPages = 10
    static let finishedChapterPages = 3

    enum Key {
        static let lastRequest = "support.lastReviewRequest"
        static let lastRequestVersion = "review.lastRequestVersion"
        static let firstLaunch = "review.firstLaunch"
        static let usageDayCount = "review.usageDayCount"
        static let lastUsageDay = "review.lastUsageDay"
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    /// Whether a prompt may be requested, given when the last one was (seconds since
    /// 1970, or 0 for never).
    static func shouldRequestInAppPrompt(lastRequest: Double, now: Date) -> Bool {
        lastRequest <= 0 || now.timeIntervalSince1970 - lastRequest >= interval
    }

    /// Notes that the app was opened: the first launch, and each new calendar day.
    static func recordAppOpen(now: Date = Date(), calendar: Calendar = .current, defaults: UserDefaults = .standard) {
        if defaults.double(forKey: Key.firstLaunch) <= 0 {
            defaults.set(now.timeIntervalSince1970, forKey: Key.firstLaunch)
        }
        let parts = calendar.dateComponents([.year, .month, .day], from: now)
        let day = "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
        if defaults.string(forKey: Key.lastUsageDay) != day {
            defaults.set(day, forKey: Key.lastUsageDay)
            defaults.set(defaults.integer(forKey: Key.usageDayCount) + 1, forKey: Key.usageDayCount)
        }
    }

    /// A session worth asking after: `sessionPages` different pages, or reaching the
    /// end of a chapter after at least `finishedChapterPages` pages.
    static func isGoodSession(pagesViewed: Int, reachedEnd: Bool) -> Bool {
        pagesViewed >= sessionPages || (reachedEnd && pagesViewed >= finishedChapterPages)
    }

    /// Whether to request the prompt automatically after a good session.
    static func shouldAutoRequest(now: Date = Date(), version: String = appVersion, defaults: UserDefaults = .standard) -> Bool {
        let firstLaunch = defaults.double(forKey: Key.firstLaunch)
        return firstLaunch > 0
            && now.timeIntervalSince1970 - firstLaunch >= minimumAge
            && defaults.integer(forKey: Key.usageDayCount) >= usageDays
            && defaults.string(forKey: Key.lastRequestVersion) != version
            && shouldRequestInAppPrompt(lastRequest: defaults.double(forKey: Key.lastRequest), now: now)
    }

    static func recordRequest(now: Date = Date(), version: String = appVersion, defaults: UserDefaults = .standard) {
        defaults.set(now.timeIntervalSince1970, forKey: Key.lastRequest)
        defaults.set(version, forKey: Key.lastRequestVersion)
    }
}
