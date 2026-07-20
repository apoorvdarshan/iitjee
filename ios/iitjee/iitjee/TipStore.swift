import Combine
import StoreKit
import SwiftUI

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

    private var productsByID: [String: Product] = [:]
    private var handledTransactionIDs: Set<UInt64> = []
    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    deinit {
        updatesTask?.cancel()
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        updatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                await self.process(result)
            }
        }

        await finishUnfinishedTransactions()
        await loadProducts()
    }

    func product(for tip: TipProductID) -> Product? {
        productsByID[tip.rawValue]
    }

    func loadProducts() async {
        catalogState = .loading

        do {
            let loadedProducts = try await Product.products(
                for: TipProductID.allCases.map(\.rawValue)
            )
            productsByID = Dictionary(
                uniqueKeysWithValues: loadedProducts
                    .filter { $0.type == .consumable }
                    .map { ($0.id, $0) }
            )
            catalogState = productsByID.count == TipProductID.allCases.count
                ? .ready
                : .unavailable
        } catch {
            productsByID = [:]
            catalogState = .unavailable
        }
    }

    func purchase(_ tip: TipProductID) async {
        guard activeProductID == nil,
              let product = product(for: tip),
              product.type == .consumable else {
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
            switch try await product.purchase() {
            case .success(let verification):
                await process(verification)
            case .pending:
                feedback = Feedback(
                    kind: .pending,
                    message: "Your tip is pending approval. Apple will finish it when it is approved."
                )
            case .userCancelled:
                feedback = Feedback(
                    kind: .info,
                    message: "Tip cancelled. Nothing was charged."
                )
            @unknown default:
                feedback = Feedback(
                    kind: .error,
                    message: "The App Store returned an unfamiliar result. Please try again later."
                )
            }
        } catch {
            feedback = Feedback(
                kind: .error,
                message: "The tip could not be completed. Check your connection and try again."
            )
        }
    }

    func dismissFeedback() {
        feedback = nil
    }

    private func finishUnfinishedTransactions() async {
        for await result in StoreKit.Transaction.unfinished {
            await process(result, showsThankYou: false)
        }
    }

    private func process(
        _ result: VerificationResult<StoreKit.Transaction>,
        showsThankYou: Bool = true
    ) async {
        switch result {
        case .verified(let transaction):
            guard TipProductID(rawValue: transaction.productID) != nil else { return }
            guard handledTransactionIDs.insert(transaction.id).inserted else { return }
            await transaction.finish()

            if showsThankYou {
                feedback = Feedback(
                    kind: .success,
                    message: "Thank you—your tip helps keep PCM Notes free, ad-free, and improving."
                )
            }
        case .unverified:
            feedback = Feedback(
                kind: .error,
                message: "Apple could not verify this transaction. Nothing was unlocked or changed."
            )
        }
    }
}
