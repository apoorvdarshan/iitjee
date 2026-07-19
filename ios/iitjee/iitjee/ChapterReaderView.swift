import PDFKit
import SwiftUI

private enum PDFReadingLayout: String, CaseIterable, Identifiable {
    case continuous
    case spread

    var id: String { rawValue }

    var title: String {
        switch self {
        case .continuous: "Continuous"
        case .spread: "Two-page spread"
        }
    }

    var symbol: String {
        switch self {
        case .continuous: "rectangle.portrait"
        case .spread: "rectangle.split.2x1"
        }
    }
}

struct ChapterReaderView: View {
    let subject: SubjectArea
    let chapter: Chapter

    @State private var currentPage: Int
    @State private var renderedPageCount = 0
    @Environment(\.dismiss) private var dismiss

    init(subject: SubjectArea, chapter: Chapter) {
        self.subject = subject
        self.chapter = chapter

        let storedPage = UserDefaults.standard.integer(
            forKey: chapter.readingProgressKey(for: subject)
        )
        _currentPage = State(
            initialValue: min(max(storedPage, 1), chapter.pageCount)
        )
    }

    private var pdfURL: URL? {
        chapter.pdfURL(for: subject)
    }

    var body: some View {
        Group {
            if let pdfURL {
                FocusPDFReader(
                    title: chapter.title,
                    pdfURL: pdfURL,
                    accent: subject.accent,
                    currentPage: $currentPage,
                    pageCount: $renderedPageCount
                )
            } else {
                missingPDF
            }
        }
        .onChange(of: currentPage) { _, newPage in
            UserDefaults.standard.set(
                newPage,
                forKey: chapter.readingProgressKey(for: subject)
            )
        }
    }

    private var missingPDF: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ContentUnavailableView {
                Label("PDF unavailable", systemImage: "doc.badge.exclamationmark")
            } description: {
                Text("Rebuild and reinstall PCM Notes to embed this chapter's offline PDF.")
            } actions: {
                Button("Return to chapters") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(subject.accent)
            }
            .foregroundStyle(.white)
            .padding(30)
        }
        .preferredColorScheme(.dark)
    }
}

private struct ReaderControlBar: View {
    @Binding var currentPage: Int
    let pageCount: Int
    let accent: Color
    let spreadMode: Bool

    private var sliderValue: Binding<Double> {
        Binding {
            Double(currentPage)
        } set: { newValue in
            currentPage = min(max(Int(newValue.rounded()), 1), max(pageCount, 1))
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            pageButton(
                symbol: "chevron.left",
                label: "Previous page",
                isDisabled: currentPage <= 1
            ) {
                moveBackward()
            }

            Slider(
                value: sliderValue,
                in: 1...Double(max(pageCount, 2)),
                step: 1
            )
            .tint(accent)
            .accessibilityLabel("Page position")
            .accessibilityValue(pagePositionLabel)
            .accessibilityIdentifier("reader.pageSlider")

            Text(pageCounterLabel)
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(.secondary)
                .frame(minWidth: spreadMode ? 78 : 54, alignment: .trailing)

            pageButton(
                symbol: "chevron.right",
                label: "Next page",
                isDisabled: spreadMode
                    ? spreadStart >= lastSpreadStart
                    : currentPage >= pageCount
            ) {
                moveForward()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .notebookGlass(tint: accent, cornerRadius: 19, interactive: true)
    }

    private func pageButton(
        symbol: String,
        label: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.weight(.black))
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.11), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(label)
    }

    private var spreadStart: Int {
        guard currentPage > 1 else { return 1 }
        return currentPage.isMultiple(of: 2) ? currentPage : currentPage - 1
    }

    private var lastSpreadStart: Int {
        guard pageCount > 1 else { return 1 }
        return pageCount.isMultiple(of: 2) ? pageCount : pageCount - 1
    }

    private var pageCounterLabel: String {
        guard spreadMode, spreadStart > 1 else {
            return "\(currentPage) / \(pageCount)"
        }

        let spreadEnd = min(spreadStart + 1, pageCount)
        return "\(spreadStart)–\(spreadEnd) / \(pageCount)"
    }

    private var pagePositionLabel: String {
        guard spreadMode, spreadStart > 1 else {
            return "Page \(currentPage) of \(pageCount)"
        }

        let spreadEnd = min(spreadStart + 1, pageCount)
        return "Pages \(spreadStart) through \(spreadEnd) of \(pageCount)"
    }

    private func moveBackward() {
        guard spreadMode else {
            currentPage -= 1
            return
        }

        currentPage = spreadStart <= 2 ? 1 : spreadStart - 2
    }

    private func moveForward() {
        guard spreadMode else {
            currentPage += 1
            return
        }

        currentPage = spreadStart == 1
            ? min(2, pageCount)
            : min(spreadStart + 2, pageCount)
    }
}

private struct FocusPDFReader: View {
    let title: String
    let pdfURL: URL
    let accent: Color
    @Binding var currentPage: Int
    @Binding var pageCount: Int

    @Environment(\.dismiss) private var dismiss
    @AppStorage("reader.ipad.layout") private var storedLayout = PDFReadingLayout.continuous.rawValue

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var readingLayout: PDFReadingLayout {
        PDFReadingLayout(rawValue: storedLayout) ?? .continuous
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LocalPDFView(
                url: pdfURL,
                readingLayout: readingLayout,
                currentPage: $currentPage,
                pageCount: $pageCount
            )
            .background(Color.black)
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top) {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .background(.black.opacity(0.62), in: Circle())
                .accessibilityLabel("Close focus reader")

                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(.white)

                Spacer()

                if isPad {
                    Menu {
                        Picker("Page layout", selection: $storedLayout) {
                            ForEach(PDFReadingLayout.allCases) { layout in
                                Label(layout.title, systemImage: layout.symbol)
                                    .tag(layout.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: readingLayout.symbol)
                            .font(.headline)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .background(.black.opacity(0.62), in: Circle())
                    .accessibilityLabel("Reading layout")
                    .accessibilityValue(readingLayout.title)
                    .accessibilityIdentifier("reader.layoutMenu")
                }

                ShareLink(item: pdfURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .background(.black.opacity(0.62), in: Circle())
                .accessibilityLabel("Share chapter PDF")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.78))
        }
        .safeAreaInset(edge: .bottom) {
            ReaderControlBar(
                currentPage: $currentPage,
                pageCount: max(pageCount, 1),
                accent: accent,
                spreadMode: readingLayout == .spread
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.black.opacity(0.76))
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
}

private struct LocalPDFView: UIViewRepresentable {
    let url: URL
    let readingLayout: PDFReadingLayout
    @Binding var currentPage: Int
    @Binding var pageCount: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.backgroundColor = .clear
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.pageBreakMargins = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        pdfView.displayBox = .cropBox
        pdfView.autoScales = true
        configure(pdfView, for: readingLayout)
        context.coordinator.observe(pdfView)
        loadDocument(into: pdfView, coordinator: context.coordinator)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.loadedURL != url {
            loadDocument(into: pdfView, coordinator: context.coordinator)
            return
        }

        if context.coordinator.loadedLayout != readingLayout {
            context.coordinator.loadedLayout = readingLayout
            configure(pdfView, for: readingLayout)
            refit(pdfView)
        }

        guard
            let document = pdfView.document,
            let visiblePage = pdfView.currentPage
        else { return }

        let targetIndex = min(max(currentPage - 1, 0), max(document.pageCount - 1, 0))
        if document.index(for: visiblePage) != targetIndex,
           let targetPage = document.page(at: targetIndex) {
            pdfView.go(to: targetPage)
        }
    }

    static func dismantleUIView(_ pdfView: PDFView, coordinator: Coordinator) {
        coordinator.stopObserving()
        pdfView.document = nil
    }

    private func loadDocument(into pdfView: PDFView, coordinator: Coordinator) {
        guard let document = PDFDocument(url: url) else { return }

        coordinator.loadedURL = url
        coordinator.loadedLayout = readingLayout
        pdfView.document = document
        pdfView.autoScales = true
        let documentPageCount = document.pageCount

        DispatchQueue.main.async {
            pageCount = documentPageCount
        }

        let targetIndex = min(max(currentPage - 1, 0), max(document.pageCount - 1, 0))

        refit(pdfView, targetIndex: targetIndex)
    }

    private func configure(_ pdfView: PDFView, for layout: PDFReadingLayout) {
        switch layout {
        case .continuous:
            pdfView.displayMode = .singlePageContinuous
            pdfView.displaysAsBook = false
        case .spread:
            pdfView.displayMode = .twoUpContinuous
            pdfView.displaysAsBook = true
        }
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
    }

    private func refit(_ pdfView: PDFView, targetIndex: Int? = nil) {
        let fallbackIndex = min(
            max(currentPage - 1, 0),
            max((pdfView.document?.pageCount ?? 1) - 1, 0)
        )

        DispatchQueue.main.async {
            let fitScale = pdfView.scaleFactorForSizeToFit
            if fitScale > 0 {
                pdfView.scaleFactor = fitScale
                pdfView.autoScales = true
            }

            if let targetPage = pdfView.document?.page(at: targetIndex ?? fallbackIndex) {
                pdfView.go(to: targetPage)
            }
        }
    }

    final class Coordinator: NSObject {
        var parent: LocalPDFView
        var loadedURL: URL?
        var loadedLayout: PDFReadingLayout?
        private var pageObserver: NSObjectProtocol?

        init(parent: LocalPDFView) {
            self.parent = parent
        }

        func observe(_ pdfView: PDFView) {
            pageObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: pdfView,
                queue: .main
            ) { [weak self, weak pdfView] _ in
                guard
                    let self,
                    let pdfView,
                    let document = pdfView.document,
                    let page = pdfView.currentPage
                else { return }

                let visiblePage = document.index(for: page) + 1
                let documentPageCount = document.pageCount

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }

                    if parent.currentPage != visiblePage {
                        parent.currentPage = visiblePage
                    }
                    if parent.pageCount != documentPageCount {
                        parent.pageCount = documentPageCount
                    }
                }
            }
        }

        func stopObserving() {
            if let pageObserver {
                NotificationCenter.default.removeObserver(pageObserver)
            }
            pageObserver = nil
        }

        deinit {
            stopObserving()
        }
    }
}

#Preview {
    ChapterReaderView(subject: .physics, chapter: ChapterCatalog.physics[0])
}
