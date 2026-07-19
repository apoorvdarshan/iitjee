import SwiftUI

struct SubjectScene: View {
    let subject: SubjectArea

    @State private var selectedChapter: Chapter?
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            SubjectBrowserView(
                subject: subject,
                selectedChapter: $selectedChapter
            )
            .navigationSplitViewColumnWidth(min: 292, ideal: 350, max: 410)
        } detail: {
            SubjectWelcomeView(subject: subject)
        }
        .navigationSplitViewStyle(.balanced)
        .tint(subject.accent)
        .fullScreenCover(item: $selectedChapter) { chapter in
            ChapterReaderView(subject: subject, chapter: chapter)
                .id(chapter.id)
        }
    }
}

private struct SubjectBrowserView: View {
    let subject: SubjectArea
    @Binding var selectedChapter: Chapter?

    @State private var searchText = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            List {
                SubjectHero(subject: subject)
                    .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 14, trailing: 14))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                Section {
                    if filteredChapters.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .frame(maxWidth: .infinity, minHeight: 260)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredChapters) { chapter in
                            Button {
                                selectedChapter = chapter
                            } label: {
                                ChapterRow(
                                    chapter: chapter,
                                    subject: subject,
                                    isSelected: selectedChapter == chapter
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(
                                EdgeInsets(top: 5, leading: 14, bottom: 5, trailing: 14)
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accessibilityLabel(
                                "Chapter \(chapter.number), \(chapter.title), \(chapter.pageCount) pages"
                            )
                            .accessibilityHint("Opens the bundled handwritten PDF full screen")
                            .accessibilityIdentifier("chapter.\(subject.slug).\(chapter.number)")
                        }
                    }
                } header: {
                    HStack {
                        EyebrowLabel(text: "Chapter spine", color: subject.accent)

                        Spacer()

                        if !searchText.isEmpty {
                            Text("\(filteredChapters.count) shown")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .textCase(nil)
                    .padding(.horizontal, 2)
                    .padding(.top, 4)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("PCM Notes")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Find a chapter")
        .animation(reduceMotion ? nil : .snappy(duration: 0.24), value: filteredChapters)
    }
}

private struct SubjectHero: View {
    let subject: SubjectArea

    @ScaledMetric(relativeTo: .largeTitle) private var glyphSize = 66
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var examLabel: String {
        subject == .mathematics ? "JEE MAIN + ADVANCED" : "JEE + NEET REVISION"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                EyebrowLabel(text: examLabel, color: subject.accent)

                Text(subject.name)
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.78)

                Text(subject.tagline)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, dynamicTypeSize.isAccessibilitySize ? 0 : 42)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { heroMetrics }
                    VStack(alignment: .leading, spacing: 8) { heroMetrics }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: subject.symbol)
                    .font(.system(size: glyphSize, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(subject.accent.opacity(0.20))
                    .rotationEffect(.degrees(subject == .chemistry ? -8 : 7))
                    .offset(x: 8, y: 7)
                    .accessibilityHidden(true)
            }
        }
        .padding(20)
        .notebookGlass(tint: subject.accent, cornerRadius: 28)
        .shadow(color: subject.accent.opacity(0.08), radius: 18, y: 9)
    }

    @ViewBuilder
    private var heroMetrics: some View {
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

private struct ChapterRow: View {
    let chapter: Chapter
    let subject: SubjectArea
    let isSelected: Bool

    @AppStorage private var savedPage: Int
    @ScaledMetric(relativeTo: .body) private var badgeSize = 44
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(chapter: Chapter, subject: SubjectArea, isSelected: Bool) {
        self.chapter = chapter
        self.subject = subject
        self.isSelected = isSelected
        _savedPage = AppStorage(
            wrappedValue: 0,
            chapter.readingProgressKey(for: subject)
        )
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 11) {
                    numberBadge
                    chapterCopy
                }
            } else {
                HStack(spacing: 12) {
                    numberBadge
                    chapterCopy
                    Spacer(minLength: 2)
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .contentShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .paperSurface(tint: subject.accent, cornerRadius: 19, selected: isSelected)
        .hoverEffect(.lift)
        .accessibilityElement(children: .combine)
    }

    private var numberBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(subject.accent.opacity(isSelected ? 0.18 : 0.11))

            Text(String(format: "%02d", chapter.number))
                .font(.system(.subheadline, design: .monospaced, weight: .black))
                .foregroundStyle(.primary)
        }
        .frame(width: min(badgeSize, 64), height: min(badgeSize, 64))
    }

    private var chapterCopy: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(chapter.title)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Label(progressLabel, systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
                .fixedSize(horizontal: false, vertical: true)

            if savedPage > 1 {
                ProgressView(
                    value: Double(savedPage),
                    total: Double(chapter.pageCount)
                )
                .tint(subject.accent)
                .accessibilityLabel("Reading progress")
                .accessibilityValue("Page \(savedPage) of \(chapter.pageCount)")
            }
        }
    }

    private var progressLabel: String {
        if savedPage > 1 {
            "Resume page \(savedPage) of \(chapter.pageCount)"
        } else {
            "\(chapter.pageCount) pages · offline PDF"
        }
    }
}

private struct SubjectWelcomeView: View {
    let subject: SubjectArea

    var body: some View {
        ZStack {
            NotebookBackground(accent: subject.accent)

            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(subject.accent.opacity(0.12))
                            .frame(width: 132, height: 132)

                        Image(systemName: subject.symbol)
                            .font(.system(size: 58, weight: .light))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(subject.accent)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        EyebrowLabel(text: "Your offline study desk", color: subject.accent)

                        Text(subject.name)
                            .font(.system(.largeTitle, design: .rounded, weight: .black))

                        Text("Choose a chapter from the spine to open its handwritten PDF full screen. Close it to return straight to the list.")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        MetricPill(
                            value: "\(subject.chapters.count)",
                            label: "chapters",
                            color: subject.accent
                        )
                        MetricPill(
                            value: subject.pageCount.formatted(),
                            label: "offline pages",
                            color: subject.secondaryAccent
                        )
                    }

                    Label("No internet required", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .notebookGlass(tint: subject.accent, cornerRadius: 18)
                }
                .frame(maxWidth: 620)
                .padding(.horizontal, 28)
                .padding(.vertical, 72)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("iPhone") {
    SubjectScene(subject: .physics)
}

#Preview("iPad", traits: .landscapeLeft) {
    SubjectScene(subject: .chemistry)
}
