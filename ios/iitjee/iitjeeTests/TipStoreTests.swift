import Foundation
import RevenueCat
import Testing
@testable import iitjee

/// A scripted tip store: no StoreKit, RevenueCat or network.
@MainActor
private final class ScriptedTipPurchaser: TipPurchasing {
    var offers: [TipOffer]
    var outcome: TipPurchaseOutcome
    var holdsPurchases = false
    private(set) var loadCount = 0
    private(set) var purchased: [TipProductID] = []
    private(set) var heldPurchase: CheckedContinuation<Void, Never>?

    /// Without offers every tip is on sale at its StoreKit configuration price.
    init(offers: [TipOffer]? = nil, outcome: TipPurchaseOutcome = .purchased) {
        self.offers = offers ?? TipProductID.allCases.map { LocalTipPurchasing.offer(for: $0) }
        self.outcome = outcome
    }

    func loadOffers(for tips: [TipProductID]) async -> [TipOffer] {
        loadCount += 1
        return offers.filter { tips.contains($0.tip) }
    }

    func purchase(_ tip: TipProductID) async -> TipPurchaseOutcome {
        purchased.append(tip)
        if holdsPurchases {
            await withCheckedContinuation { heldPurchase = $0 }
        }
        return outcome
    }

    func finishHeldPurchase() {
        heldPurchase?.resume()
        heldPurchase = nil
    }
}

@MainActor
struct TipStoreTests {
    @Test func startLoadsTheTipCatalogOnce() async {
        let purchaser = ScriptedTipPurchaser()
        let store = TipStore(purchaser: purchaser)
        #expect(store.catalogState == .idle)

        await store.start()
        await store.start()

        #expect(purchaser.loadCount == 1)
        #expect(store.catalogState == .ready)
        #expect(store.offer(for: .medium) == TipOffer(tip: .medium, title: "Chai Tip", price: "₹99"))
    }

    @Test func missingPricesMakeTheTipJarUnavailableUntilARetrySucceeds() async {
        let purchaser = ScriptedTipPurchaser(offers: [LocalTipPurchasing.offer(for: .small)])
        let store = TipStore(purchaser: purchaser)

        await store.loadProducts()
        #expect(store.catalogState == .unavailable)
        #expect(store.offer(for: .small) != nil)
        #expect(store.offer(for: .generous) == nil)

        purchaser.offers = TipProductID.allCases.map { LocalTipPurchasing.offer(for: $0) }
        await store.loadProducts()
        #expect(store.catalogState == .ready)
        #expect(store.offer(for: .generous)?.price == "₹499")
    }

    @Test func everyPurchaseOutcomeExplainsWhatHappened() async {
        let expected: [(TipPurchaseOutcome, TipStore.Feedback.Kind, String)] = [
            (.purchased, .success, "Thank you—your tip helps keep PCM Notes free, ad-free, and improving."),
            (.cancelled, .info, "Tip cancelled. Nothing was charged."),
            (.pending, .pending, "Your tip is pending approval. Apple will finish it when it is approved."),
            (.failed, .error, "The tip could not be completed. Check your connection and try again."),
        ]
        for (outcome, kind, message) in expected {
            let purchaser = ScriptedTipPurchaser(outcome: outcome)
            let store = TipStore(purchaser: purchaser)
            await store.loadProducts()

            await store.purchase(.large)

            #expect(purchaser.purchased == [.large])
            #expect(store.feedback == TipStore.Feedback(kind: kind, message: message), "\(outcome)")
            #expect(store.activeProductID == nil)
        }
    }

    @Test func unavailableTipNeverReachesTheStore() async {
        let purchaser = ScriptedTipPurchaser(offers: [])
        let store = TipStore(purchaser: purchaser)
        await store.loadProducts()

        await store.purchase(.small)

        #expect(purchaser.purchased.isEmpty)
        #expect(store.feedback?.kind == .error)
        #expect(store.feedback?.message == "That tip is unavailable right now. Please try again later.")
    }

    @Test func secondTipCannotStartWhileOneIsInProgress() async {
        let purchaser = ScriptedTipPurchaser()
        purchaser.holdsPurchases = true
        let store = TipStore(purchaser: purchaser)
        await store.loadProducts()

        let first = Task { await store.purchase(.small) }
        while purchaser.heldPurchase == nil {
            await Task.yield()
        }
        #expect(store.activeProductID == .small)
        #expect(store.feedback == nil)

        await store.purchase(.medium)
        #expect(purchaser.purchased == [.small], "the second tip must not reach the store")
        #expect(store.feedback?.kind == .error)

        purchaser.finishHeldPurchase()
        await first.value
        #expect(store.activeProductID == nil)
        #expect(store.feedback?.kind == .success)
    }

    @Test func dismissingFeedbackClearsIt() async {
        let store = TipStore(purchaser: ScriptedTipPurchaser(outcome: .cancelled))
        await store.loadProducts()
        await store.purchase(.small)
        #expect(store.feedback != nil)

        store.dismissFeedback()
        #expect(store.feedback == nil)
    }

    @Test func revenueCatErrorsMapToOutcomes() {
        #expect(RevenueCatTipPurchasing.outcome(for: ErrorCode.purchaseCancelledError) == .cancelled)
        #expect(RevenueCatTipPurchasing.outcome(for: ErrorCode.paymentPendingError) == .pending)
        #expect(RevenueCatTipPurchasing.outcome(for: ErrorCode.networkError) == .failed)
        #expect(RevenueCatTipPurchasing.outcome(for: ErrorCode.storeProblemError) == .failed)
        #expect(RevenueCatTipPurchasing.outcome(for: URLError(.notConnectedToInternet)) == .failed)
    }

    @Test func localTipStoreUsesTheStoreKitConfigurationPrices() async {
        let local = LocalTipPurchasing(catalog: .unavailableThenReady, outcome: .pending)
        #expect(await local.loadOffers(for: TipProductID.allCases).isEmpty, "first load is offline")
        let offers = await local.loadOffers(for: TipProductID.allCases)
        #expect(offers.map(\.price) == ["₹49", "₹99", "₹199", "₹499"])
        #expect(offers.map(\.title) == TipProductID.allCases.map(\.fallbackName))
        #expect(await local.purchase(.generous) == .pending)
        #expect(local.purchases == [.generous])
    }
}
