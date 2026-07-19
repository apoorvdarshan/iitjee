import SwiftUI

struct SubjectView: View {
    let subject: SubjectArea

    @State private var searchText = ""

    private var filteredChapters: [Chapter] {
        guard !searchText.isEmpty else { return subject.chapters }

        return subject.chapters.filter { chapter in
            chapter.title.localizedCaseInsensitiveContains(searchText)
                || String(chapter.number).localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            NotebookBackground(accent: subject.accent)

            ScrollView {
                LazyVStack(spacing: 13) {
                    SubjectHero(subject: subject)
                        .padding(.bottom, 8)

                    HStack {
                        EyebrowLabel(text: "Chapter index", color: subject.accent)
                        Spacer()
                        Text("\(filteredChapters.count) shown")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)

                    if filteredChapters.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .frame(minHeight: 260)
                    } else {
                        ForEach(filteredChapters) { chapter in
                            NavigationLink(value: chapter) {
                                ChapterCard(chapter: chapter, subject: subject)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(subject.tabName)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Find a chapter")
        .navigationDestination(for: Chapter.self) { chapter in
            ChapterGalleryView(subject: subject, chapter: chapter)
        }
        .animation(.snappy(duration: 0.24), value: filteredChapters)
    }
}

private struct SubjectHero: View {
    let subject: SubjectArea

    private var examLabel: String {
        subject == .mathematics ? "JEE MAIN + ADVANCED" : "JEE + NEET REVISION"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 14) {
                EyebrowLabel(text: examLabel, color: subject.accent)

                Text(subject.name)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.78)

                Text(subject.tagline)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 48)

                HStack(spacing: 9) {
                    MetricPill(
                        value: "\(subject.chapters.count)",
                        label: "chapters",
                        color: subject.accent
                    )
                    MetricPill(
                        value: subject.pageCount.formatted(),
                        label: "pages",
                        color: subject.secondaryAccent
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: subject.symbol)
                .font(.system(size: 70, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(subject.accent.opacity(0.22))
                .rotationEffect(.degrees(subject == .chemistry ? -8 : 7))
                .offset(x: 8, y: 8)
                .accessibilityHidden(true)
        }
        .padding(22)
        .notebookGlass(tint: subject.accent, cornerRadius: 30)
        .shadow(color: subject.accent.opacity(0.10), radius: 22, y: 12)
    }
}

private struct ChapterCard: View {
    let chapter: Chapter
    let subject: SubjectArea

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(subject.accent.opacity(0.13))

                Text(String(format: "%02d", chapter.number))
                    .font(.system(.subheadline, design: .monospaced, weight: .black))
                    .foregroundStyle(subject.accent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 5) {
                Text(chapter.title)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Label("\(chapter.pageCount) handwritten pages", systemImage: "doc.text.image")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(subject.accent)
                .padding(9)
                .background(subject.accent.opacity(0.10), in: Circle())
        }
        .padding(14)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .notebookGlass(tint: subject.accent, cornerRadius: 22, interactive: true)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the handwritten notes gallery")
    }
}

#Preview {
    NavigationStack {
        SubjectView(subject: .physics)
    }
}
