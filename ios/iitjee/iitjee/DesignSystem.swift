import SwiftUI

enum AppPalette {
    static let ink = Color(red: 0.04, green: 0.08, blue: 0.15)
    static let paper = Color(red: 0.97, green: 0.98, blue: 1.00)
    static let physics = Color(red: 0.12, green: 0.48, blue: 0.96)
    static let physicsSecondary = Color(red: 0.14, green: 0.80, blue: 0.94)
    static let chemistry = Color(red: 0.04, green: 0.68, blue: 0.47)
    static let chemistrySecondary = Color(red: 0.48, green: 0.88, blue: 0.38)
    static let mathematics = Color(red: 0.52, green: 0.30, blue: 0.96)
    static let mathematicsSecondary = Color(red: 0.95, green: 0.39, blue: 0.69)
    static let margin = Color(red: 0.94, green: 0.31, blue: 0.37)
    static let support = Color(red: 1.00, green: 0.55, blue: 0.14)
    static let about = Color(red: 0.25, green: 0.62, blue: 0.95)
}

struct NotebookBackground: View {
    let accent: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark ? AppPalette.ink : AppPalette.paper)

            Canvas { context, size in
                let lineOpacity = colorScheme == .dark ? 0.055 : 0.075
                let marginX = min(max(size.width * 0.07, 24), 42)

                for y in stride(from: 30.0, through: size.height, by: 28.0) {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(
                        line,
                        with: .color(accent.opacity(lineOpacity)),
                        lineWidth: 0.7
                    )
                }

                var margin = Path()
                margin.move(to: CGPoint(x: marginX, y: 0))
                margin.addLine(to: CGPoint(x: marginX, y: size.height))
                context.stroke(
                    margin,
                    with: .color(AppPalette.margin.opacity(colorScheme == .dark ? 0.16 : 0.22)),
                    lineWidth: 1.25
                )
            }

            RadialGradient(
                colors: [accent.opacity(colorScheme == .dark ? 0.14 : 0.09), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct MetricPill: View {
    let value: String
    let label: String
    let color: Color

    @ScaledMetric(relativeTo: .subheadline) private var spacing = 7

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                metricValue
                metricLabel
            }

            VStack(alignment: .leading, spacing: 1) {
                metricValue
                metricLabel
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.11), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private var metricValue: some View {
        Text(value)
            .font(.system(.subheadline, design: .monospaced, weight: .bold))
            .foregroundStyle(.primary)
    }

    private var metricLabel: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

struct EyebrowLabel: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(text.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .tracking(1.05)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PaperSurfaceModifier: ViewModifier {
    let tint: Color
    let cornerRadius: CGFloat
    let selected: Bool

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background {
                shape.fill(
                    Color(uiColor: colorScheme == .dark
                        ? .secondarySystemBackground
                        : .systemBackground)
                )
            }
            .overlay {
                shape.strokeBorder(
                    tint.opacity(selected ? 0.52 : (colorScheme == .dark ? 0.22 : 0.16)),
                    lineWidth: selected ? 1.5 : 1
                )
            }
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(selected ? 1 : 0.66))
                    .frame(width: selected ? 4 : 2)
                    .padding(.vertical, 12)
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.055),
                radius: selected ? 12 : 7,
                y: selected ? 6 : 3
            )
    }
}

extension View {
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
        modifier(
            PaperSurfaceModifier(
                tint: tint,
                cornerRadius: cornerRadius,
                selected: selected
            )
        )
    }

    func readableWidth(_ maxWidth: CGFloat = 1_050) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    func nativeTabMinimization() -> some View {
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.onScrollDown)
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
