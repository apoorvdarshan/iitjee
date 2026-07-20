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

    private var productsByID: [String: StoreProduct] = [:]
    private var hasStarted = false

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await loadProducts()
    }

    func product(for tip: TipProductID) -> StoreProduct? {
        productsByID[tip.rawValue]
    }

    func loadProducts() async {
        catalogState = .loading

        let loadedProducts = await Purchases.shared.products(
            TipProductID.allCases.map(\.rawValue)
        )
        productsByID = Dictionary(
            uniqueKeysWithValues: loadedProducts.map { ($0.productIdentifier, $0) }
        )
        catalogState = productsByID.count == TipProductID.allCases.count
            ? .ready
            : .unavailable
    }

    func purchase(_ tip: TipProductID) async {
        guard activeProductID == nil,
              let product = product(for: tip) else {
            feedback = Feedback(
                kind: .error,
                message: "That tip is unavailable right now. Please try again later."
            )
            return
        }

        activeProductID = tip
        feedback = nil
        defer { activeProductID = nil }

        do {
            let result = try await Purchases.shared.purchase(product: product)

            if result.userCancelled {
                feedback = Feedback(
                    kind: .info,
                    message: "Tip cancelled. Nothing was charged."
                )
            } else {
                feedback = Feedback(
                    kind: .success,
                    message: "Thank you—your tip helps keep PCM Notes free, ad-free, and improving."
                )
            }
        } catch {
            let errorCode = (error as NSError).code

            if errorCode == ErrorCode.purchaseCancelledError.rawValue {
                feedback = Feedback(
                    kind: .info,
                    message: "Tip cancelled. Nothing was charged."
                )
            } else if errorCode == ErrorCode.paymentPendingError.rawValue {
                feedback = Feedback(
                    kind: .pending,
                    message: "Your tip is pending approval. Apple will finish it when it is approved."
                )
            } else {
                feedback = Feedback(
                    kind: .error,
                    message: "The tip could not be completed. Check your connection and try again."
                )
            }
        }
    }

    func dismissFeedback() {
        feedback = nil
    }
}
