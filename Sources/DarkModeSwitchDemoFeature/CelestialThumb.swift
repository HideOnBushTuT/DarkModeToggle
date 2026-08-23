import SwiftUI

struct CelestialThumb: View {
    let appearanceProgress: CGFloat
    let positionProgress: CGFloat
    let metrics: DarkModeToggleMetrics
    let variant: DarkModeToggleVariant

    var body: some View {
        let scale = metrics.celestialScale
        let clampedAppearanceProgress = min(max(appearanceProgress, 0), 1)

        ZStack(alignment: .topLeading) {
            sun(scale: scale)
                .opacity(1 - clampedAppearanceProgress)

            moon(scale: scale)
                .opacity(clampedAppearanceProgress)
        }
        .frame(
            width: DarkModeToggleMetrics.celestialArtboard.width * scale,
            height: DarkModeToggleMetrics.celestialArtboard.height * scale,
            alignment: .topLeading
        )
        .offset(
            x: metrics.translationX(progress: positionProgress),
            y: metrics.celestialVerticalInset
        )
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func sun(scale: CGFloat) -> some View {
        switch variant {
        case .original:
            SunDisc(scale: scale)
        case .vivid:
            VividSunDisc(scale: scale)
        }
    }

    @ViewBuilder
    private func moon(scale: CGFloat) -> some View {
        switch variant {
        case .original:
            MoonDisc(scale: scale)
        case .vivid:
            VividMoonDisc(scale: scale)
        }
    }
}

private struct SunDisc: View {
    let scale: CGFloat

    private let sourceX: CGFloat = 111.5537
    private let sourceY: CGFloat = 20.365
    private let sourceWidth: CGFloat = 45.4463
    private let sourceHeight: CGFloat = 43.635
    private let sourceRadius: CGFloat = 21.8175

    var body: some View {
        RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
            .fill(TogglePalette.sun.opacity(0.96))
            .overlay {
                RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.clear,
                                Color(red: 1, green: 0.63, blue: 0.29).opacity(0.68),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2.6 * scale
                    )
            }
            .frame(width: sourceWidth * scale, height: sourceHeight * scale)
            .shadow(
                color: TogglePalette.sun.opacity(0.6),
                radius: 5.85 * scale
            )
            .shadow(
                color: Color(red: 0.717, green: 0.717, blue: 0.717).opacity(0.35),
                radius: 2.6 * scale,
                x: -3.9 * scale,
                y: 6.5 * scale
            )
            .offset(x: sourceX * scale, y: sourceY * scale)
    }
}

private struct MoonDisc: View {
    let scale: CGFloat

    private let sourceX: CGFloat = 111.0674
    private let sourceY: CGFloat = 20.3278
    private let sourceWidth: CGFloat = 45.4426
    private let sourceHeight: CGFloat = 43.6315
    private let sourceRadius: CGFloat = 21.8158

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
                .fill(TogglePalette.moon)
                .overlay {
                    RoundedRectangle(cornerRadius: sourceRadius * scale, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    Color.clear,
                                    Color(red: 0.748, green: 0.75, blue: 0.754).opacity(0.58),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2.6 * scale
                        )
                }
                .frame(width: sourceWidth * scale, height: sourceHeight * scale)
                .shadow(
                    color: Color(red: 0.717, green: 0.717, blue: 0.717).opacity(0.31),
                    radius: 9.75 * scale,
                    x: -3.9 * scale
                )
                .offset(x: sourceX * scale, y: sourceY * scale)

            MoonOcclusionShape()
                .fill(TogglePalette.nightSky.opacity(0.79))
                .opacity(0.9)
        }
        .frame(
            width: DarkModeToggleMetrics.celestialArtboard.width * scale,
            height: DarkModeToggleMetrics.celestialArtboard.height * scale,
            alignment: .topLeading
        )
    }
}

private struct MoonOcclusionShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / DarkModeToggleMetrics.celestialArtboard.width
        let scaleY = rect.height / DarkModeToggleMetrics.celestialArtboard.height

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scaleX, y: y * scaleY)
        }

        var path = Path()
        path.move(to: point(132.712, 22.837))
        path.addCurve(
            to: point(112.361, 35.1418),
            control1: point(123.768, 20.7837),
            control2: point(114.702, 26.2647)
        )
        path.addCurve(
            to: point(124.675, 55.4324),
            control1: point(109.965, 44.2237),
            control2: point(115.515, 53.3683)
        )
        path.addLine(to: point(125.016, 55.5092))
        path.addLine(to: point(125.658, 55.6541))
        path.addCurve(
            to: point(146.016, 43.0404),
            control1: point(134.701, 57.6918),
            control2: point(143.815, 52.0444)
        )
        path.addCurve(
            to: point(133.695, 23.0626),
            control1: point(148.211, 34.062),
            control2: point(142.702, 25.1306)
        )
        path.addLine(to: point(132.712, 22.837))
        path.closeSubpath()
        return path
    }
}

private struct VividSunDisc: View {
    let scale: CGFloat

    private let sourceX: CGFloat = 111.5537
    private let sourceY: CGFloat = 20.365
    private let sourceSize: CGFloat = 45.4463

    var body: some View {
        Circle()
            .fill(VividTogglePalette.sun)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.48),
                                VividTogglePalette.sunHighlight.opacity(0.8),
                                Color.black.opacity(0.18),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.1 * scale
                    )
            }
            .frame(width: sourceSize * scale, height: sourceSize * scale)
            .shadow(
                color: VividTogglePalette.sun.opacity(0.54),
                radius: 4.5 * scale
            )
            .shadow(
                color: Color.black.opacity(0.42),
                radius: 3.2 * scale,
                x: 2.4 * scale,
                y: 3.2 * scale
            )
            .offset(x: sourceX * scale, y: sourceY * scale)
    }
}

private struct VividMoonDisc: View {
    let scale: CGFloat

    private let sourceX: CGFloat = 111.5537
    private let sourceY: CGFloat = 20.365
    private let sourceSize: CGFloat = 45.4463

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(VividTogglePalette.moon)

            crater(x: 25, y: 6.5, diameter: 9.5)
            crater(x: 7, y: 18, diameter: 15)
            crater(x: 30, y: 30, diameter: 9.5)
        }
        .overlay {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.86),
                            Color.white.opacity(0.18),
                            Color.black.opacity(0.28),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.1 * scale
                )
        }
        .frame(width: sourceSize * scale, height: sourceSize * scale)
        .shadow(
            color: Color.white.opacity(0.36),
            radius: 5 * scale
        )
        .shadow(
            color: Color.black.opacity(0.46),
            radius: 3.2 * scale,
            x: 2.4 * scale,
            y: 3.2 * scale
        )
        .offset(x: sourceX * scale, y: sourceY * scale)
    }

    private func crater(x: CGFloat, y: CGFloat, diameter: CGFloat) -> some View {
        Circle()
            .fill(VividTogglePalette.moonCrater)
            .overlay {
                Circle()
                    .stroke(Color.black.opacity(0.22), lineWidth: 1.2 * scale)
            }
            .frame(width: diameter * scale, height: diameter * scale)
            .offset(x: x * scale, y: y * scale)
    }
}
