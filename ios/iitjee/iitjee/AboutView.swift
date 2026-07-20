import SwiftUI

struct AboutView: View {
    @AppStorage(AppAppearance.storageKey) private var storedAppearance = AppAppearance.system.rawValue

    private var versionText: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ZStack {
            NotebookBackground(accent: AppPalette.about)

            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    aboutHero
                    ArchiveStatLine()

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 30) {
                            VStack(alignment: .leading, spacing: 32) {
                                missionSection
                                coverageSection
                            }
                            .frame(minWidth: 410, maxWidth: .infinity, alignment: .topLeading)

                            DoodleVerticalRule(color: AppPalette.about)

                            VStack(alignment: .leading, spacing: 32) {
                                offlineSection
                                appearanceSection
                                legalSection
                                independenceNote
                                creatorCredit
                            }
                            .frame(minWidth: 340, maxWidth: .infinity, alignment: .topLeading)
                        }

                        VStack(alignment: .leading, spacing: 32) {
                            missionSection
                            offlineSection
                            appearanceSection
                            coverageSection
                            legalSection
                            independenceNote
                            creatorCredit
                        }
                    }

                    Text(versionText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                .readableWidth()
                .padding(.leading, 72)
                .padding(.trailing, 24)
                .padding(.top, 22)
                .padding(.bottom, 38)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var aboutHero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 26) {
                PCMAppMark()
                aboutHeroCopy
            }

            VStack(alignment: .leading, spacing: 20) {
                PCMAppMark()
                aboutHeroCopy
            }
        }
    }

    private var aboutHeroCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel(text: "Inside cover", color: AppPalette.about)

            Text("PCM Notes")
                .font(.custom("Noteworthy-Bold", size: 44, relativeTo: .largeTitle))
                .markerHighlight(AppPalette.physicsSecondary)

            Text("Handwritten exam revision")
                .font(.headline)
                .foregroundStyle(AppPalette.about)

            Text("Physics, Chemistry, and Mathematics notes organised for fast JEE revision—with Physics and Chemistry also useful for NEET.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var missionSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            DoodleSectionTitle(
                title: "Why this exists",
                color: AppPalette.about,
                annotation: "the short version"
            )

            Text("Less hunting. More revising.")
                .font(.custom("Noteworthy-Bold", size: 26, relativeTo: .title2))
                .markerHighlight(AppPalette.about)

            Text("A large handwritten archive is easier to use when every topic has a clear place. Pick a subject, find the chapter, and open the complete PDF—even without a connection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var offlineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DoodleSectionTitle(
                title: "Built for focus",
                color: AppPalette.chemistry,
                annotation: "no loading links"
            )

            OfflineStamp()

            Text("The roughly 500 MB archive is packaged as local PDFs. Reading, zooming, sharing, and returning to your saved page never depends on the website.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Label("No internet required", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppPalette.chemistry)
        }
    }

    private var coverageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            DoodleSectionTitle(
                title: "Inside the notebook",
                color: AppPalette.mathematics,
                annotation: "full syllabus index"
            )

            ForEach(SubjectArea.allCases) { subject in
                HStack(spacing: 14) {
                    Image(systemName: subject.symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(subject.accent)
                        .frame(width: 32)
                        .rotationEffect(.degrees(subject == .chemistry ? -5 : 3))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject.name)
                            .font(.headline)

                        Text("\(subject.chapters.count) chapters · \(subject.pageCount.formatted()) pages")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) {
                    DoodleRule(color: subject.accent)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            DoodleSectionTitle(
                title: "Paper & ink",
                color: AppPalette.about,
                annotation: "appearance"
            )

            HStack(spacing: 8) {
                ForEach(AppAppearance.allCases) { appearance in
                    AppearanceChoice(
                        appearance: appearance,
                        isSelected: storedAppearance == appearance.rawValue
                    ) {
                        storedAppearance = appearance.rawValue
                    }
                }
            }

            Text("System follows your device. Light and Dark stay fixed until you change them here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var independenceNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            DoodleRule(color: AppPalette.chemistry, lineWidth: 1.4)

            HStack(alignment: .top, spacing: 12) {
                Text("NB")
                    .font(.caption.monospaced().weight(.black))
                    .foregroundStyle(AppPalette.chemistry)
                    .rotationEffect(.degrees(-5))

                Text("PCM Notes is an independent study resource. It is not affiliated with IITs, NTA, JEE, or NEET. Biology is not included.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DoodleRule(color: AppPalette.chemistry, lineWidth: 1.4)
        }
        .accessibilityElement(children: .combine)
    }

    private var legalSection: some View {
        LegalLinksSection(color: AppPalette.about, annotation: "privacy + terms")
    }

    private var creatorCredit: some View {
        HStack(spacing: 12) {
            Text("Made by Apoorv Darshan")
                .font(.custom("Noteworthy-Bold", size: 21, relativeTo: .body))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Text("INDIE")
                .font(.caption2.monospaced().weight(.black))
                .foregroundStyle(AppPalette.mathematics)
                .rotationEffect(.degrees(-4))
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            DoodleRule(color: AppPalette.mathematics)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("about.creator")
    }
}

private struct AppearanceChoice: View {
    let appearance: AppAppearance
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    if isSelected {
                        DoodleLoop(color: AppPalette.about)
                            .frame(width: 44, height: 36)
                    }

                    Image(systemName: appearance.symbol)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isSelected ? AppPalette.about : .secondary)
                }
                .frame(height: 38)

                Text(appearance.title)
                    .font(.caption.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                DoodleRule(color: isSelected ? AppPalette.about : AppPalette.rule)
                    .opacity(isSelected ? 1 : 0.42)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appearance.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Changes the app appearance")
        .accessibilityIdentifier("appearance.\(appearance.rawValue)")
    }
}

private struct PCMAppMark: View {
    var body: some View {
        ZStack {
            DoodleLoop(color: AppPalette.mathematics)
                .rotationEffect(.degrees(-4))

            Text("PCM")
                .font(.custom("Noteworthy-Bold", size: 31, relativeTo: .title))
                .tracking(-0.5)
                .foregroundStyle(.primary)
                .markerHighlight(AppPalette.physicsSecondary)
        }
        .frame(width: 118, height: 88)
        .accessibilityLabel("PCM Notes")
    }
}

private struct ArchiveStatLine: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 13) {
                stat(ChapterCatalog.totalChapterCount.formatted(), "chapters", AppPalette.physics)
                cross
                stat(ChapterCatalog.totalPageCount.formatted(), "pages", AppPalette.chemistry)
                cross
                stat("3", "subjects", AppPalette.mathematics)
            }

            VStack(alignment: .leading, spacing: 12) {
                stat(ChapterCatalog.totalChapterCount.formatted(), "chapters", AppPalette.physics)
                stat(ChapterCatalog.totalPageCount.formatted(), "pages", AppPalette.chemistry)
                stat("3", "subjects", AppPalette.mathematics)
            }
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            DoodleRule(color: AppPalette.about, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }

    private var cross: some View {
        Text("×")
            .font(.custom("Noteworthy-Bold", size: 20, relativeTo: .body))
            .foregroundStyle(.tertiary)
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .monospaced, weight: .black))
                .foregroundStyle(color)

            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct OfflineStamp: View {
    var body: some View {
        ZStack {
            Canvas { context, size in
                let inset: CGFloat = 3
                var border = Path()
                border.move(to: CGPoint(x: inset + 2, y: inset))
                border.addLine(to: CGPoint(x: size.width - inset, y: inset + 1))
                border.addLine(to: CGPoint(x: size.width - inset - 1, y: size.height - inset))
                border.addLine(to: CGPoint(x: inset, y: size.height - inset - 1))
                border.closeSubpath()
                context.stroke(
                    border,
                    with: .color(AppPalette.chemistry.opacity(0.72)),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )
            }

            Text("OFFLINE · 91 PDFs")
                .font(.system(.subheadline, design: .monospaced, weight: .black))
                .foregroundStyle(AppPalette.chemistry)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .fixedSize()
        .rotationEffect(.degrees(-2.5))
        .accessibilityLabel("91 PDFs available offline")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
