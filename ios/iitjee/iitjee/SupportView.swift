import SwiftUI

struct SupportView: View {
    private let supportEmail = URL(
        string: "mailto:ad13dtu@gmail.com?subject=PCM%20Notes%20Support"
    )!
    private let website = URL(string: "https://iitjee.apoorvdarshan.com")!
    private let instagram = URL(string: "https://instagram.com/apoorvdarshan")!
    private let github = URL(string: "https://github.com/apoorvdarshan/iitjee")!

    var body: some View {
        ZStack {
            NotebookBackground(accent: AppPalette.support)

            ScrollView {
                LazyVStack(spacing: 16) {
                    supportHero

                    sectionLabel("Get help")

                    SupportLinkCard(
                        title: "Email support",
                        detail: "Questions, corrections, or missing pages",
                        symbol: "envelope.fill",
                        color: AppPalette.support,
                        destination: supportEmail
                    )

                    SupportLinkCard(
                        title: "Open the web library",
                        detail: "Use the original gallery in Safari",
                        symbol: "safari.fill",
                        color: AppPalette.physics,
                        destination: website
                    )

                    sectionLabel("Common questions")

                    VStack(spacing: 0) {
                        FAQRow(
                            question: "Why is a page still loading?",
                            answer: "Pages stream from the online notes archive. Check your internet connection, then reopen the chapter."
                        )
                        Divider().padding(.leading, 18)
                        FAQRow(
                            question: "Does the app work offline?",
                            answer: "The chapter index is built in, but note images currently require an internet connection."
                        )
                        Divider().padding(.leading, 18)
                        FAQRow(
                            question: "Is this complete NEET material?",
                            answer: "Physics and Chemistry can support NEET revision. Biology is not included, so this is not a complete NEET library."
                        )
                        Divider().padding(.leading, 18)
                        FAQRow(
                            question: "How do I report a wrong page?",
                            answer: "Email support with the subject, chapter, and page number so it can be checked quickly."
                        )
                    }
                    .notebookGlass(tint: AppPalette.support, cornerRadius: 24)

                    sectionLabel("Stay in the loop")

                    HStack(spacing: 12) {
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
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var supportHero: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                EyebrowLabel(text: "We can sort it out", color: AppPalette.support)

                Text("Need a hand?")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))

                Text("Find a quick answer or send the exact chapter and page that needs attention.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Image(systemName: "lifepreserver.fill")
                .font(.system(size: 54, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppPalette.support)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .notebookGlass(tint: AppPalette.support, cornerRadius: 30)
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack {
            EyebrowLabel(text: title, color: AppPalette.support)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
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

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(color)
            }
            .padding(14)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .notebookGlass(tint: color, cornerRadius: 22, interactive: true)
        }
        .buttonStyle(.plain)
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
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)

                HStack {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .notebookGlass(tint: color, cornerRadius: 22, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}
