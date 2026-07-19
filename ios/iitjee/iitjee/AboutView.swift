import SwiftUI

struct AboutView: View {
    private let website = URL(string: "https://iitjee.apoorvdarshan.com")!
    private let creator = URL(string: "https://github.com/apoorvdarshan")!

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ZStack {
            NotebookBackground(accent: AppPalette.about)

            ScrollView {
                LazyVStack(spacing: 16) {
                    aboutHero
                    archiveStats
                    missionCard
                    coverageCard
                    independenceNote
                    linksCard

                    Text(versionText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var aboutHero: some View {
        VStack(spacing: 18) {
            PCMAppMark()

            VStack(spacing: 7) {
                Text("PCM Notes")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))

                Text("Handwritten exam revision")
                    .font(.headline)
                    .foregroundStyle(AppPalette.about)

                Text("A focused Physics, Chemistry, and Mathematics library for JEE preparation—with Physics and Chemistry useful for NEET revision.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .notebookGlass(tint: AppPalette.about, cornerRadius: 30)
    }

    private var archiveStats: some View {
        HStack(spacing: 12) {
            AboutStat(
                value: ChapterCatalog.totalChapterCount.formatted(),
                label: "chapters",
                color: AppPalette.physics
            )
            AboutStat(
                value: ChapterCatalog.totalPageCount.formatted(),
                label: "pages",
                color: AppPalette.chemistry
            )
            AboutStat(
                value: "3",
                label: "subjects",
                color: AppPalette.mathematics
            )
        }
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            EyebrowLabel(text: "Why this exists", color: AppPalette.about)

            Text("Less hunting. More revising.")
                .font(.system(.title3, design: .rounded, weight: .black))

            Text("PCM Notes turns a large handwritten archive into a chapter-first native library. Pick a subject, find the exact topic, and move straight into the pages that matter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .notebookGlass(tint: AppPalette.about, cornerRadius: 24)
    }

    private var coverageCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            EyebrowLabel(text: "Inside the archive", color: AppPalette.about)

            ForEach(SubjectArea.allCases) { subject in
                HStack(spacing: 13) {
                    Image(systemName: subject.symbol)
                        .font(.headline)
                        .foregroundStyle(subject.accent)
                        .frame(width: 38, height: 38)
                        .background(subject.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject.name)
                            .font(.subheadline.weight(.bold))
                        Text("\(subject.chapters.count) chapters · \(subject.pageCount.formatted()) pages")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .notebookGlass(tint: AppPalette.about, cornerRadius: 24)
    }

    private var independenceNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(AppPalette.chemistry)

            Text("PCM Notes is an independent study resource. It is not affiliated with IITs, NTA, JEE, or NEET. Biology is not included.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .notebookGlass(tint: AppPalette.chemistry, cornerRadius: 20)
    }

    private var linksCard: some View {
        VStack(spacing: 0) {
            AboutLink(
                title: "Visit the web archive",
                symbol: "safari.fill",
                color: AppPalette.physics,
                destination: website
            )

            Divider().padding(.leading, 58)

            AboutLink(
                title: "Created by Apoorv Darshan",
                symbol: "person.crop.circle.fill",
                color: AppPalette.mathematics,
                destination: creator
            )
        }
        .notebookGlass(tint: AppPalette.about, cornerRadius: 24)
    }
}

private struct PCMAppMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.physics, AppPalette.mathematics],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Canvas { context, size in
                for y in stride(from: 22.0, through: size.height, by: 16.0) {
                    var path = Path()
                    path.move(to: CGPoint(x: 12, y: y))
                    path.addLine(to: CGPoint(x: size.width - 12, y: y))
                    context.stroke(path, with: .color(.white.opacity(0.14)), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))

            Text("PCM")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .tracking(-1)
                .foregroundStyle(.white)
        }
        .frame(width: 92, height: 92)
        .shadow(color: AppPalette.mathematics.opacity(0.25), radius: 22, y: 12)
        .accessibilityLabel("PCM Notes app icon")
    }
}

private struct AboutStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .black))
                .foregroundStyle(color)

            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .notebookGlass(tint: color, cornerRadius: 20)
        .accessibilityElement(children: .combine)
    }
}

private struct AboutLink: View {
    let title: String
    let symbol: String
    let color: Color
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
