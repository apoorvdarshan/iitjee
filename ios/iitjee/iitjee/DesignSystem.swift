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
    static let margin = Color(red: 0.98, green: 0.36, blue: 0.42)
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
                let lineOpacity = colorScheme == .dark ? 0.075 : 0.105

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
                margin.move(to: CGPoint(x: 26, y: 0))
                margin.addLine(to: CGPoint(x: 26, y: size.height))
                context.stroke(
                    margin,
                    with: .color(AppPalette.margin.opacity(colorScheme == .dark ? 0.12 : 0.17)),
                    lineWidth: 1
                )
            }

            RadialGradient(
                colors: [accent.opacity(colorScheme == .dark ? 0.18 : 0.12), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 360
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

    var body: some View {
        HStack(spacing: 7) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(color)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.11), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

struct EyebrowLabel: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

extension View {
    @ViewBuilder
    func notebookGlass(
        tint: Color,
        cornerRadius: CGFloat = 24,
        interactive: Bool = false
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if #available(iOS 26.0, *) {
            glassEffect(
                .regular.tint(tint.opacity(0.12)).interactive(interactive),
                in: shape
            )
        } else {
            background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(tint.opacity(0.15), lineWidth: 1)
                }
        }
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
