import SwiftUI

struct SupportView: View {
    private let supportEmail = URL(
        string: "mailto:ad13dtu@gmail.com?subject=PCM%20Notes%20Support"
    )!
    private let instagram = URL(string: "https://instagram.com/apoorvdarshan")!
    private let github = URL(string: "https://github.com/apoorvdarshan/iitjee")!

    var body: some View {
        ZStack {
            NotebookBackground(accent: AppPalette.support)

            ScrollView {
                VStack(spacing: 18) {
                    supportHero

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            helpColumn
                                .frame(minWidth: 380, maxWidth: .infinity)
                            faqColumn
                                .frame(minWidth: 430, maxWidth: .infinity)
                        }

                        VStack(spacing: 18) {
                            helpColumn
                            faqColumn
                        }
                    }
                }
                .readableWidth()
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var supportHero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 24) {
                supportHeroCopy
                Spacer(minLength: 20)
                supportSymbol
            }

            VStack(alignment: .leading, spacing: 18) {
                supportHeroCopy
                supportSymbol
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .notebookGlass(tint: AppPalette.support, cornerRadius: 30)
    }

    private var supportHeroCopy: some View {
        VStack(alignment: .leading, spacing: 10) {
            EyebrowLabel(text: "We can sort it out", color: AppPalette.support)

            Text("Need a hand?")
                .font(.system(.largeTitle, design: .rounded, weight: .black))

            Text("Find a quick answer or send the exact subject, chapter, and page that needs attention.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var supportSymbol: some View {
        Image(systemName: "lifepreserver.fill")
            .font(.system(.largeTitle, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(AppPalette.support)
            .padding(18)
            .background(AppPalette.support.opacity(0.11), in: Circle())
            .accessibilityHidden(true)
    }

    private var helpColumn: some View {
        VStack(spacing: 14) {
            sectionLabel("Get help")

            SupportLinkCard(
                title: "Email support",
                detail: "Questions, corrections, or missing pages",
                symbol: "envelope.fill",
                color: AppPalette.support,
                destination: supportEmail
            )

            SupportInfoCard(
                title: "The complete archive is offline",
                detail: "All 91 chapter PDFs and 2,173 pages are bundled with the app.",
                symbol: "internaldrive.fill",
                color: AppPalette.chemistry
            )

            sectionLabel("Stay in the loop")

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { socialLinks }
                VStack(spacing: 12) { socialLinks }
            }
        }
    }

    private var faqColumn: some View {
        VStack(spacing: 14) {
            sectionLabel("Common questions")

            VStack(spacing: 0) {
                FAQRow(
                    question: "Does the app work without internet?",
                    answer: "Yes. Every handwritten chapter is bundled as a local PDF, so reading and zooming work fully offline."
                )
                Divider().padding(.leading, 18)
                FAQRow(
                    question: "Why can a chapter take a moment to open?",
                    answer: "Long chapters contain up to 92 high-resolution pages. The PDF opens locally, but the device may need a moment to prepare those pages."
                )
                Divider().padding(.leading, 18)
                FAQRow(
                    question: "Is this complete NEET material?",
                    answer: "Physics and Chemistry can support NEET revision. Biology is not included, so this is not a complete NEET library."
                )
                Divider().padding(.leading, 18)
                FAQRow(
                    question: "How do I report a wrong page?",
                    answer: "Email support with the subject, chapter, and PDF page number so it can be checked quickly."
                )
            }
            .paperSurface(tint: AppPalette.support, cornerRadius: 24)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack {
            EyebrowLabel(text: title, color: AppPalette.support)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var socialLinks: some View {
        CompactSocialLink(
            title: "Instagram",
            symbol: "camera.fill",
            color: AppPalette.mathematicsSecondary,
            destination: instagram
        )

        CompactSocialLink(
            title: "GitHub",
            symbol: "chevron.left.forwardslash.chevron.right",
            color: AppPalette.chemistry,
            destination: github
        )
    }
}

private struct SupportLinkCard: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            SupportCardLabel(
                title: title,
                detail: detail,
                symbol: symbol,
                color: color,
                trailingSymbol: "arrow.up.right"
            )
            .paperSurface(tint: color, cornerRadius: 21)
            .hoverEffect(.lift)
        }
        .buttonStyle(.plain)
    }
}

private struct SupportInfoCard: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        SupportCardLabel(
            title: title,
            detail: detail,
            symbol: symbol,
            color: color,
            trailingSymbol: "checkmark"
        )
        .paperSurface(tint: color, cornerRadius: 21)
        .accessibilityElement(children: .combine)
    }
}

private struct SupportCardLabel: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color
    let trailingSymbol: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            Image(systemName: trailingSymbol)
                .font(.caption.weight(.black))
                .foregroundStyle(.secondary)
        }
        .padding(15)
    }
}

private struct FAQRow: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
        } label: {
            Text(question)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .tint(AppPalette.support)
        .padding(18)
    }
}

private struct CompactSocialLink: View {
    let title: String
    let symbol: String
    let color: Color
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .paperSurface(tint: color, cornerRadius: 20)
            .hoverEffect(.lift)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}
