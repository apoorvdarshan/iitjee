#if DEBUG
import Foundation

/// Launch controls for automated tests. This file compiles only into Debug builds
/// and the controls act only in the Simulator, so a device or App Store build can
/// never reset data or bypass StoreKit and RevenueCat.
///
/// UI tests launch with `--ui-testing`: the tip jar then uses `LocalTipPurchasing`
/// (fixed prices, nothing charged, no network) and `--ui-testing-reset` starts from
/// empty reading progress and preferences. When XCTest hosts the app for unit
/// tests, RevenueCat is skipped the same way, so no test depends on the network.
enum TestEnvironment {
    static let uiTestingArgument = "--ui-testing"
    static let resetArgument = "--ui-testing-reset"
    /// `ready`, `unavailable` or `unavailable-then-ready` (see `LocalTipPurchasing.Catalog`).
    static let tipCatalogPrefix = "--ui-testing-tips="
    /// `purchased`, `cancelled`, `pending` or `failed`.
    static let tipOutcomePrefix = "--ui-testing-tip-outcome="

    /// The tip store for a test launch, or nil for a normal launch.
    static func tipPurchaser(
        arguments: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        defaults: UserDefaults = .standard
    ) -> (any TipPurchasing)? {
        #if targetEnvironment(simulator)
        if arguments.contains(uiTestingArgument) {
            if arguments.contains(resetArgument), let domain = Bundle.main.bundleIdentifier {
                defaults.removePersistentDomain(forName: domain)
            }
            return LocalTipPurchasing(
                catalog: value(prefixed: tipCatalogPrefix, in: arguments)
                    .flatMap(LocalTipPurchasing.Catalog.init(rawValue:)) ?? .ready,
                outcome: value(prefixed: tipOutcomePrefix, in: arguments)
                    .flatMap(TipPurchaseOutcome.init(rawValue:)) ?? .purchased
            )
        }
        if isHostingTests(environment) {
            return LocalTipPurchasing()
        }
        #endif
        return nil
    }

    /// XCTest sets these when the app hosts a test bundle.
    static func isHostingTests(_ environment: [String: String]) -> Bool {
        ["XCTestConfigurationFilePath", "XCTestBundlePath", "XCTestSessionIdentifier"]
            .contains { environment[$0] != nil }
    }

    private static func value(prefixed prefix: String, in arguments: [String]) -> String? {
        arguments.last { $0.hasPrefix(prefix) }.map { String($0.dropFirst(prefix.count)) }
    }
}

/// A deterministic tip store for tests and previews: the prices of
/// PCMNotes.storekit, instant results, no StoreKit, RevenueCat or network, and
/// nothing is ever charged.
final class LocalTipPurchasing: TipPurchasing {
    enum Catalog: String {
        case ready
        case unavailable
        /// The first load fails (as when offline) and every retry succeeds.
        case unavailableThenReady = "unavailable-then-ready"
    }

    private let catalog: Catalog
    private let outcome: TipPurchaseOutcome
    private(set) var loadCount = 0
    private(set) var purchases: [TipProductID] = []

    init(catalog: Catalog = .ready, outcome: TipPurchaseOutcome = .purchased) {
        self.catalog = catalog
        self.outcome = outcome
    }

    func loadOffers(for tips: [TipProductID]) async -> [TipOffer] {
        loadCount += 1
        switch catalog {
        case .ready:
            return tips.map(Self.offer)
        case .unavailable:
            return []
        case .unavailableThenReady:
            return loadCount == 1 ? [] : tips.map(Self.offer)
        }
    }

    func purchase(_ tip: TipProductID) async -> TipPurchaseOutcome {
        purchases.append(tip)
        return outcome
    }

    static func offer(for tip: TipProductID) -> TipOffer {
        let rupees = switch tip {
        case .small: 49
        case .medium: 99
        case .large: 199
        case .generous: 499
        }
        return TipOffer(tip: tip, title: tip.fallbackName, price: "₹\(rupees)")
    }
}
#endif
