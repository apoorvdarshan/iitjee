import StoreKit
import SwiftUI

struct TipJarSection: View {
    @EnvironmentObject private var tipStore: TipStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let firstColumn: [TipProductID] = [.small, .medium]
    private let secondColumn: [TipProductID] = [.large, .generous]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DoodleSectionTitle(
                title: "Support the notebook",
                color: AppPalette.support,
                annotation: "optional tip jar"
            )

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 28) {
                    tipList(firstColumn)
                        .frame(minWidth: 285, maxWidth: .infinity)

                    DoodleVerticalRule(color: AppPalette.support)

                    tipList(secondColumn)
                        .frame(minWidth: 285, maxWidth: .infinity)
                }

                tipList(TipProductID.allCases)
            }

            HStack(alignment: .top, spacing: 12) {
                Text("FREE")
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(AppPalette.chemistry)
                    .rotationEffect(.degrees(-4))

                Text("PCM Notes stays complete whether or not you tip. Tips are optional, repeatable, processed by Apple, and unlock no content or features.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("tip.disclosure")

            if let feedback = tipStore.feedback {
                TipFeedbackNote(feedback: feedback, reduceMotion: reduceMotion) {
                    tipStore.dismissFeedback()
                }
                .transition(
                    reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                )
            } else if tipStore.catalogState == .unavailable {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundStyle(AppPalette.support)

                    Text("Tip prices are unavailable right now.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 4)

                    Button("Retry") {
                        Task { await tipStore.loadProducts() }
                    }
                    .font(.caption.weight(.bold))
                    .buttonStyle(.plain)
                    .foregroundStyle(AppPalette.support)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("tip.retry")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("tip.status")
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: tipStore.feedback)
    }

    private func tipList(_ tips: [TipProductID]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(tips) { tip in
                TipPurchaseRow(tip: tip)
            }
        }
    }
}

private struct TipPurchaseRow: View {
    @EnvironmentObject private var tipStore: TipStore
    let tip: TipProductID

    private var product: Product? {
        tipStore.product(for: tip)
    }

    private var priceText: String {
        if let product {
            return product.displayPrice
        }

        switch tipStore.catalogState {
        case .idle, .loading:
            return "checking…"
        case .ready, .unavailable:
            return "unavailable"
        }
    }

    private var isPurchasing: Bool {
        tipStore.activeProductID == tip
    }

    var body: some View {
        Button {
            Task { await tipStore.purchase(tip) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(tip.color)
                    } else {
                        DoodleLoop(color: tip.color)
                            .frame(width: 42, height: 38)

                        Image(systemName: tip.symbol)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(tip.color)
                    }
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(product?.displayName ?? tip.fallbackName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(tip.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(priceText)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(product == nil ? Color.secondary : tip.color)
                    .markerHighlight(tip.color)
                    .lineLimit(1)
            }
            .padding(.vertical, 13)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                DoodleRule(color: tip.color)
            }
        }
        .buttonStyle(.plain)
        .disabled(product == nil || tipStore.activeProductID != nil)
        .accessibilityIdentifier("tip.product.\(tip.shortID)")
        .accessibilityLabel("\(product?.displayName ?? tip.fallbackName), \(priceText)")
        .accessibilityHint("Optional repeatable tip. It unlocks no content or features.")
    }
}

private struct TipFeedbackNote: View {
    let feedback: TipStore.Feedback
    let reduceMotion: Bool
    let dismiss: () -> Void

    private var symbol: String {
        switch feedback.kind {
        case .success: "heart.fill"
        case .pending: "clock.fill"
        case .info: "info.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch feedback.kind {
        case .success: AppPalette.chemistry
        case .pending, .info: AppPalette.about
        case .error: AppPalette.margin
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .rotationEffect(.degrees(reduceMotion ? 0 : -5))

            Text(feedback.message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss tip status")
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            DoodleRule(color: color)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tip.status")
    }
}

#Preview {
    TipJarSection()
        .environmentObject(TipStore())
        .padding()
}
