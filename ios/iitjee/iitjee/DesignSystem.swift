import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "app.appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppPalette {
    static let ink = Color(red: 0.055, green: 0.09, blue: 0.14)
    static let paper = Color(red: 0.975, green: 0.985, blue: 0.975)
    static let graphite = Color(red: 0.14, green: 0.19, blue: 0.24)
    static let rule = Color(red: 0.53, green: 0.67, blue: 0.78)
    static let physics = adaptive(
        light: UIColor(red: 0.03, green: 0.31, blue: 0.72, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.48, blue: 0.96, alpha: 1)
    )
    static let physicsSecondary = adaptive(
        light: UIColor(red: 0.00, green: 0.43, blue: 0.55, alpha: 1),
        dark: UIColor(red: 0.14, green: 0.80, blue: 0.94, alpha: 1)
    )
    static let chemistry = adaptive(
        light: UIColor(red: 0.00, green: 0.40, blue: 0.27, alpha: 1),
        dark: UIColor(red: 0.04, green: 0.68, blue: 0.47, alpha: 1)
    )
    static let chemistrySecondary = adaptive(
        light: UIColor(red: 0.30, green: 0.43, blue: 0.03, alpha: 1),
        dark: UIColor(red: 0.48, green: 0.78, blue: 0.26, alpha: 1)
    )
    static let mathematics = adaptive(
        light: UIColor(red: 0.36, green: 0.18, blue: 0.72, alpha: 1),
        dark: UIColor(red: 0.52, green: 0.30, blue: 0.96, alpha: 1)
    )
    static let mathematicsSecondary = adaptive(
        light: UIColor(red: 0.66, green: 0.15, blue: 0.39, alpha: 1),
        dark: UIColor(red: 0.95, green: 0.39, blue: 0.69, alpha: 1)
    )
    static let margin = adaptive(
        light: UIColor(red: 0.68, green: 0.22, blue: 0.27, alpha: 1),
        dark: UIColor(red: 0.90, green: 0.35, blue: 0.40, alpha: 1)
    )
    static let support = adaptive(
        light: UIColor(red: 0.69, green: 0.29, blue: 0.02, alpha: 1),
        dark: UIColor(red: 0.96, green: 0.49, blue: 0.08, alpha: 1)
    )
    static let about = adaptive(
        light: UIColor(red: 0.08, green: 0.38, blue: 0.68, alpha: 1),
        dark: UIColor(red: 0.22, green: 0.57, blue: 0.91, alpha: 1)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct NotebookBackground: View {
    let accent: Color

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        ZStack {
            (colorScheme == .dark ? AppPalette.ink : AppPalette.paper)

            Canvas { context, size in
                let strongContrast = colorSchemeContrast == .increased
                let lineOpacity = colorScheme == .dark
                    ? (strongContrast ? 0.16 : 0.10)
                    : (strongContrast ? 0.22 : 0.14)
                let marginOpacity = colorScheme == .dark
                    ? (strongContrast ? 0.48 : 0.32)
                    : (strongContrast ? 0.58 : 0.42)
                let contentWidth = min(size.width, 1_050)
                let marginX = max(56, ((size.width - contentWidth) / 2) + 56)

                for y in stride(from: 26.0, through: size.height, by: 32.0) {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y + 0.35))
                    context.stroke(
                        line,
                        with: .color(AppPalette.rule.opacity(lineOpacity)),
                        lineWidth: strongContrast ? 1 : 0.75
                    )
                }

                var margin = Path()
                margin.move(to: CGPoint(x: marginX, y: 0))
                margin.addCurve(
                    to: CGPoint(x: marginX + 0.5, y: size.height),
                    control1: CGPoint(x: marginX - 0.8, y: size.height * 0.33),
                    control2: CGPoint(x: marginX + 1.0, y: size.height * 0.67)
                )
                context.stroke(
                    margin,
                    with: .color(AppPalette.margin.opacity(marginOpacity)),
                    lineWidth: strongContrast ? 1.8 : 1.25
                )

                for y in stride(from: 92.0, through: size.height, by: 176.0) {
                    let holeRect = CGRect(x: marginX - 39, y: y, width: 8, height: 8)
                    context.stroke(
                        Path(ellipseIn: holeRect),
                        with: .color(AppPalette.graphite.opacity(colorScheme == .dark ? 0.18 : 0.12)),
                        lineWidth: 1
                    )
                }

                for index in 0..<18 {
                    let x = CGFloat((index * 83 + 29) % max(Int(size.width), 1))
                    let y = CGFloat((index * 137 + 41) % max(Int(size.height), 1))
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.1, height: 1.1)),
                        with: .color(AppPalette.graphite.opacity(colorScheme == .dark ? 0.08 : 0.055))
                    )
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct DoodleRule: View {
    let color: Color
    var lineWidth: CGFloat = 1.15

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let midY = size.height / 2
            path.move(to: CGPoint(x: 0, y: midY))

            for x in stride(from: 0.0, through: size.width, by: 12.0) {
                let y = midY + sin(x * 0.075) * 0.9 + cos(x * 0.031) * 0.45
                path.addLine(to: CGPoint(x: x, y: y))
            }

            context.stroke(
                path,
                with: .color(color.opacity(colorSchemeContrast == .increased ? 0.62 : 0.34)),
                style: StrokeStyle(
                    lineWidth: colorSchemeContrast == .increased ? lineWidth + 0.5 : lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .frame(height: 7)
        .accessibilityHidden(true)
    }
}

struct DoodleVerticalRule: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let midX = size.width / 2
            path.move(to: CGPoint(x: midX, y: 0))

            for y in stride(from: 0.0, through: size.height, by: 12.0) {
                let x = midX + sin(y * 0.065) * 0.8
                path.addLine(to: CGPoint(x: x, y: y))
            }

            context.stroke(
                path,
                with: .color(color.opacity(0.28)),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
            )
        }
        .frame(width: 9)
        .accessibilityHidden(true)
    }
}

struct DoodleLoop: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 3
            let rect = CGRect(
                x: inset,
                y: inset + 1,
                width: size.width - inset * 2,
                height: size.height - inset * 2 - 1
            )
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
            path.addCurve(
                to: CGPoint(x: rect.midX, y: rect.minY),
                control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.22),
                control2: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY)
            )
            path.addCurve(
                to: CGPoint(x: rect.maxX, y: rect.midY + 1),
                control1: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY - 1),
                control2: CGPoint(x: rect.maxX + 1, y: rect.minY + rect.height * 0.30)
            )
            path.addCurve(
                to: CGPoint(x: rect.midX - 1, y: rect.maxY),
                control1: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.24),
                control2: CGPoint(x: rect.maxX - rect.width * 0.26, y: rect.maxY + 1)
            )
            path.addCurve(
                to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY),
                control1: CGPoint(x: rect.minX + rect.width * 0.27, y: rect.maxY),
                control2: CGPoint(x: rect.minX - 1, y: rect.maxY - rect.height * 0.26)
            )
            context.stroke(
                path,
                with: .color(color.opacity(0.78)),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            )
        }
        .accessibilityHidden(true)
    }
}

struct DoodleProgressLine: View {
    let value: Double
    let total: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let y = size.height / 2
                var track = Path()
                track.move(to: CGPoint(x: 0, y: y))
                track.addCurve(
                    to: CGPoint(x: size.width, y: y),
                    control1: CGPoint(x: size.width * 0.32, y: y - 1),
                    control2: CGPoint(x: size.width * 0.70, y: y + 1)
                )
                context.stroke(
                    track,
                    with: .color(AppPalette.rule.opacity(0.35)),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )

                let fraction = min(max(total > 0 ? value / total : 0, 0), 1)
                var progress = Path()
                progress.move(to: CGPoint(x: 0, y: y))
                progress.addCurve(
                    to: CGPoint(x: size.width * fraction, y: y),
                    control1: CGPoint(x: size.width * fraction * 0.35, y: y - 1.1),
                    control2: CGPoint(x: size.width * fraction * 0.72, y: y + 0.8)
                )
                context.stroke(
                    progress,
                    with: .color(color.opacity(0.9)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(height: 7)
        .accessibilityHidden(true)
    }
}

struct DoodleSectionTitle: View {
    let title: String
    let color: Color
    var annotation: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.custom("Noteworthy-Bold", size: 22, relativeTo: .title3))
                    .foregroundStyle(.primary)

                if let annotation {
                    Text(annotation)
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            DoodleRule(color: color, lineWidth: 1.4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct MetricPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(.headline, design: .monospaced, weight: .black))
                .foregroundStyle(color)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            DoodleRule(color: color)
                .frame(maxWidth: 84)
        }
        .accessibilityElement(children: .combine)
    }
}

struct EyebrowLabel: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Text("✦")
                .font(.caption.weight(.black))
                .foregroundStyle(color)

            Text(text.uppercased())
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MarkerHighlightModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .background {
                Canvas { context, size in
                    var stroke = Path()
                    stroke.move(to: CGPoint(x: -3, y: size.height * 0.62))
                    stroke.addLine(to: CGPoint(x: size.width + 4, y: size.height * 0.54))
                    stroke.addLine(to: CGPoint(x: size.width + 1, y: size.height * 0.91))
                    stroke.addLine(to: CGPoint(x: -1, y: size.height * 0.96))
                    stroke.closeSubpath()
                    context.fill(stroke, with: .color(color.opacity(0.20)))
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

private struct PaperSurfaceModifier: ViewModifier {
    let tint: Color
    let selected: Bool

    func body(content: Content) -> some View {
        content
            .background(selected ? tint.opacity(0.055) : Color.clear)
            .overlay(alignment: .bottom) {
                DoodleRule(color: tint)
            }
    }
}

extension View {
    func markerHighlight(_ color: Color) -> some View {
        modifier(MarkerHighlightModifier(color: color))
    }

    @ViewBuilder
    func notebookGlass(
        tint: Color,
        cornerRadius: CGFloat = 24,
        interactive: Bool = false
    ) -> some View {
        modifier(
            NotebookGlassModifier(
                tint: tint,
                cornerRadius: cornerRadius,
                interactive: interactive
            )
        )
    }

    func paperSurface(
        tint: Color,
        cornerRadius: CGFloat = 20,
        selected: Bool = false
    ) -> some View {
        modifier(PaperSurfaceModifier(tint: tint, selected: selected))
    }

    func readableWidth(_ maxWidth: CGFloat = 1_050) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    func persistentTabBar() -> some View {
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.never)
        } else {
            self
        }
    }
}

private struct NotebookGlassModifier: ViewModifier {
    let tint: Color
    let cornerRadius: CGFloat
    let interactive: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if reduceTransparency {
            content
                .background(Color(uiColor: .secondarySystemBackground), in: shape)
                .overlay {
                    shape.strokeBorder(tint.opacity(0.24), lineWidth: 1)
                }
        } else if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular.tint(tint.opacity(0.12)).interactive(interactive),
                in: shape
            )
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(tint.opacity(0.15), lineWidth: 1)
                }
        }
    }
}
