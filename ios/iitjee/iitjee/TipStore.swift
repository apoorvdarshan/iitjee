import Combine
import RevenueCat
import SwiftUI

enum RevenueCatConfiguration {
    // RevenueCat's app-specific public SDK key is designed to ship in the app.
    // The read/write secret key is intentionally never stored in this project.
    static let publicAPIKey = "appl_CVdEBjqTWFFtAFCGLodwdkUfUZQ"

    static func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: publicAPIKey)
    }
}

enum TipProductID: String, CaseIterable, Identifiable, Sendable {
    case small = "com.apoorvdarshan.iitjee.tip.small"
    case medium = "com.apoorvdarshan.iitjee.tip.medium"
    case large = "com.apoorvdarshan.iitjee.tip.large"
    case generous = "com.apoorvdarshan.iitjee.tip.generous"

    var id: String { rawValue }

    var shortID: String {
        switch self {
        case .small: "small"
        case .medium: "medium"
        case .large: "large"
        case .generous: "generous"
        }
    }

    var fallbackName: String {
        switch self {
        case .small: "Small Tip"
        case .medium: "Chai Tip"
        case .large: "Study Fuel"
        case .generous: "Notebook Hero"
        }
    }

    var note: String {
        switch self {
        case .small: "A little high-five"
        case .medium: "Fuel one chai break"
        case .large: "Help with fixes and updates"
        case .generous: "Back the whole notebook"
        }
    }

    var symbol: String {
        switch self {
        case .small: "pencil"
        case .medium: "cup.and.saucer.fill"
        case .large: "bolt.heart.fill"
        case .generous: "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .small: AppPalette.support
        case .medium: AppPalette.chemistry
        case .large: AppPalette.mathematicsSecondary
        case .generous: AppPalette.mathematics
        }
    }
}

/// What the tip jar shows for one product: the store's localized name and price.
struct TipOffer: Equatable, Sendable {
    let tip: TipProductID
    let title: String
    let price: String
}

/// How a tip purchase ended, independent of the store SDK.
enum TipPurchaseOutcome: String, Sendable {
    case purchased
    case cancelled
    case pending
    case failed
}

/// The store behind the tip jar: RevenueCat and StoreKit in the app, a local
/// stand-in in tests and previews.
@MainActor
protocol TipPurchasing: AnyObject {
    /// Offers for the tips the store can sell right now (missing ones are unavailable).
    func loadOffers(for tips: [TipProductID]) async -> [TipOffer]
    func purchase(_ tip: TipProductID) async -> TipPurchaseOutcome
}

/// Loads tip prices from StoreKit and buys tips through RevenueCat.
@MainActor
final class RevenueCatTipPurchasing: TipPurchasing {
    private var productsByID: [String: StoreProduct] = [:]

    func loadOffers(for tips: [TipProductID]) async -> [TipOffer] {
        let loadedProducts = await Purchases.shared.products(tips.map(\.rawValue))
        productsByID = Dictionary(
            uniqueKeysWithValues: loadedProducts.map { ($0.productIdentifier, $0) }
        )
        return tips.compactMap { tip in
            productsByID[tip.rawValue].map { product in
                TipOffer(
                    tip: tip,
                    title: product.localizedTitle,
                    price: product.localizedPriceString
                )
            }
        }
    }

    func purchase(_ tip: TipProductID) async -> TipPurchaseOutcome {
        guard let product = productsByID[tip.rawValue] else { return .failed }

        do {
            let result = try await Purchases.shared.purchase(product: product)
            return result.userCancelled ? .cancelled : .purchased
        } catch {
            return Self.outcome(for: error)
        }
    }

    /// A dismissed payment sheet charges nothing, Ask to Buy and similar
    /// approvals leave the tip pending, and any other error means it failed.
    nonisolated static func outcome(for error: Error) -> TipPurchaseOutcome {
        switch (error as NSError).code {
        case ErrorCode.purchaseCancelledError.rawValue: .cancelled
        case ErrorCode.paymentPendingError.rawValue: .pending
        default: .failed
        }
    }
}

@MainActor
final class TipStore: ObservableObject {
    enum CatalogState: Equatable {
        case idle
        case loading
        case ready
        case unavailable
    }

    struct Feedback: Equatable, Identifiable {
        enum Kind {
            case success
            case pending
            case info
            case error
        }

        let kind: Kind
        let message: String

        var id: String { "\(kind)-\(message)" }
    }

    @Published private(set) var catalogState: CatalogState = .idle
    @Published private(set) var activeProductID: TipProductID?
    @Published private(set) var feedback: Feedback?

    private let purchaser: any TipPurchasing
    private var offersByTip: [TipProductID: TipOffer] = [:]
    private var hasStarted = false

    /// Without a purchaser the store sells through RevenueCat.
    init(purchaser: (any TipPurchasing)? = nil) {
        self.purchaser = purchaser ?? RevenueCatTipPurchasing()
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await loadProducts()
    }

    func offer(for tip: TipProductID) -> TipOffer? {
        offersByTip[tip]
    }

    func loadProducts() async {
        catalogState = .loading

        let offers = await purchaser.loadOffers(for: TipProductID.allCases)
        offersByTip = Dictionary(
            offers.map { ($0.tip, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        catalogState = offersByTip.count == TipProductID.allCases.count
            ? .ready
            : .unavailable
    }

    func purchase(_ tip: TipProductID) async {
        guard activeProductID == nil,
              offer(for: tip) != nil else {
            feedback = Feedback(
                kind: .error,
                message: "That tip is unavailable right now. Please try again later."
            )
            return
        }

        activeProductID = tip
        feedback = nil
        defer { activeProductID = nil }

        switch await purchaser.purchase(tip) {
        case .purchased:
            feedback = Feedback(
                kind: .success,
                message: "Thank you—your tip helps keep PCM Notes free, ad-free, and improving."
            )
        case .cancelled:
            feedback = Feedback(
                kind: .info,
                message: "Tip cancelled. Nothing was charged."
            )
        case .pending:
            feedback = Feedback(
                kind: .pending,
                message: "Your tip is pending approval. Apple will finish it when it is approved."
            )
        case .failed:
            feedback = Feedback(
                kind: .error,
                message: "The tip could not be completed. Check your connection and try again."
            )
        }
    }

    func dismissFeedback() {
        feedback = nil
    }
}
