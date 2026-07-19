import SwiftUI

struct ChapterGalleryView: View {
    let subject: SubjectArea
    let chapter: Chapter

    @State private var selectedPage: NotePageReference?

    var body: some View {
        ZStack {
            NotebookBackground(accent: subject.accent)

            ScrollView {
                LazyVStack(spacing: 18) {
                    chapterHeader

                    ForEach(1...chapter.pageCount, id: \.self) { page in
                        let reference = NotePageReference(
                            chapterTitle: chapter.title,
                            page: page,
                            pageCount: chapter.pageCount,
                            url: chapter.pageURL(for: subject, page: page)
                        )

                        RemoteNotePage(reference: reference, accent: subject.accent)
                            .onTapGesture {
                                selectedPage = reference
                            }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedPage) { reference in
            NotePageViewer(reference: reference, accent: subject.accent)
        }
    }

    private var chapterHeader: some View {
        VStack(alignment: .leading, spacing: 13) {
            EyebrowLabel(
                text: "\(subject.name) · Chapter \(chapter.number)",
                color: subject.accent
            )

            Text(chapter.title)
                .font(.system(.title, design: .rounded, weight: .black))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 9) {
                MetricPill(
                    value: "\(chapter.pageCount)",
                    label: "pages",
                    color: subject.accent
                )

                Label("Tap a page to focus", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Label("An internet connection is required to load pages.", systemImage: "wifi")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .notebookGlass(tint: subject.accent, cornerRadius: 26)
    }
}

private struct NotePageReference: Identifiable {
    let chapterTitle: String
    let page: Int
    let pageCount: Int
    let url: URL

    var id: URL { url }
}

private struct RemoteNotePage: View {
    let reference: NotePageReference
    let accent: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PAGE \(String(format: "%02d", reference.page))")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(accent)

                Spacer()

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Open full screen")
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)

            AsyncImage(
                url: reference.url,
                transaction: Transaction(animation: .easeOut(duration: 0.25))
            ) { phase in
                switch phase {
                case .empty:
                    NotePagePlaceholder(accent: accent)

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .transition(.opacity)

                case .failure:
                    NotePageFailure(url: reference.url, accent: accent)

                @unknown default:
                    NotePagePlaceholder(accent: accent)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 7)
            .padding(.bottom, 7)
        }
        .notebookGlass(tint: accent, cornerRadius: 22, interactive: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Page \(reference.page) of \(reference.pageCount)")
    }
}

private struct NotePagePlaceholder: View {
    let accent: Color

    var body: some View {
        ZStack {
            Color.white.opacity(0.72)

            VStack(spacing: 12) {
                ProgressView()
                    .tint(accent)

                Text("Loading handwritten page")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(0.72, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

private struct NotePageFailure: View {
    let url: URL
    let accent: Color

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(accent)

            Text("This page could not load")
                .font(.headline)

            Text("Check your connection, then try opening the original page.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Link(destination: url) {
                Label("Open original", systemImage: "safari")
                    .font(.subheadline.weight(.bold))
            }
            .buttonStyle(.bordered)
            .tint(accent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(Color.white.opacity(0.72))
    }
}

private struct NotePageViewer: View {
    let reference: NotePageReference
    let accent: Color

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: reference.url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(magnificationGesture)
                        .onTapGesture(count: 2) {
                            withAnimation(.snappy) {
                                scale = scale > 1 ? 1 : 2.25
                                settledScale = scale
                            }
                        }

                case .failure:
                    ContentUnavailableView(
                        "Page unavailable",
                        systemImage: "wifi.exclamationmark",
                        description: Text("Check your internet connection and try again.")
                    )
                    .foregroundStyle(.white)

                @unknown default:
                    EmptyView()
                }
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(.black.opacity(0.52))
                    .accessibilityLabel("Close")

                    Spacer()

                    Text("\(reference.page) / \(reference.pageCount)")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(.black.opacity(0.52), in: Capsule())

                    ShareLink(item: reference.url) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(.black.opacity(0.52))
                    .accessibilityLabel("Share page")
                }

                Spacer()

                Text("Pinch or double-tap to zoom")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.52), in: Capsule())
            }
            .padding()
        }
        .statusBarHidden()
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(settledScale * value, 1), 5)
            }
            .onEnded { _ in
                settledScale = scale
            }
    }
}

#Preview {
    NavigationStack {
        ChapterGalleryView(subject: .physics, chapter: ChapterCatalog.physics[0])
    }
}
