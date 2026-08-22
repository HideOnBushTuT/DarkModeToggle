import SwiftUI

enum VividTogglePalette {
    static let daySky = Color(red: 70 / 255, green: 133 / 255, blue: 192 / 255)
    static let nightSky = Color(red: 25 / 255, green: 30 / 255, blue: 50 / 255)
    static let sun = Color(red: 1, green: 195 / 255, blue: 35 / 255)
    static let sunHighlight = Color(red: 1, green: 230 / 255, blue: 80 / 255)
    static let moon = Color(red: 195 / 255, green: 200 / 255, blue: 210 / 255)
    static let moonCrater = Color(red: 150 / 255, green: 160 / 255, blue: 180 / 255)
    static let star = Color.white
}

struct VividToggleTrack: View {
    let progress: CGFloat
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool

    var body: some View {
        let scale = metrics.trackScale
        let clampedProgress = min(max(progress, 0), 1)
        let trackShape = RoundedRectangle(
            cornerRadius: 32.5 * scale,
            style: .continuous
        )

        ZStack(alignment: .topLeading) {
            VividTogglePalette.daySky

            VividTogglePalette.nightSky
                .opacity(clampedProgress)

            VividHaloLayer(progress: clampedProgress, scale: scale)

            VividDayScene(reduceMotion: reduceMotion)
                .opacity(1 - clampedProgress)
                .offset(y: clampedProgress * 48 * scale)

            VividNightScene(reduceMotion: reduceMotion)
                .opacity(clampedProgress)
                .offset(y: (1 - clampedProgress) * -12 * scale)
        }
        .frame(width: 169 * scale, height: 65 * scale, alignment: .topLeading)
        .clipShape(trackShape)
        .overlay {
            trackShape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.62),
                            Color.black.opacity(0.18),
                            Color.white.opacity(0.22),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 4 * scale
                )
        }
        .shadow(
            color: Color.black.opacity(0.28),
            radius: 2.8 * scale,
            x: 1.8 * scale,
            y: 2.4 * scale
        )
        .offset(x: 2 * scale, y: 2 * scale)
        .frame(width: metrics.width, height: metrics.trackHeight, alignment: .topLeading)
        .drawingGroup()
    }
}

private struct VividHaloLayer: View {
    let progress: CGFloat
    let scale: CGFloat

    var body: some View {
        let centerX = (40.5 + (130.4 - 40.5) * progress) * scale
        let centerY = 32.5 * scale

        ZStack {
            halo(diameter: 156, opacity: 0.06)
            halo(diameter: 132, opacity: 0.1)
            halo(diameter: 108, opacity: 0.18)
        }
        .position(x: centerX, y: centerY)
        .allowsHitTesting(false)
    }

    private func halo(diameter: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: diameter * scale, height: diameter * scale)
    }
}

private struct VividDayScene: View {
    let reduceMotion: Bool

    @State private var cloudsAreRaised = false

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / DarkModeToggleMetrics.trackArtboard.width

            ZStack(alignment: .topLeading) {
                ForEach(
                    Array(VividToggleArt.cloudGroups.enumerated()),
                    id: \.offset
                ) { _, group in
                    CloudGroupView(group: group)
                        .opacity(group.opacity)
                        .offset(y: cloudOffset(for: scale))
                        .animation(cloudAnimation(for: group), value: cloudsAreRaised)
                }
            }
            .onAppear {
                cloudsAreRaised = true
            }
        }
    }

    private func cloudOffset(for scale: CGFloat) -> CGFloat {
        guard !reduceMotion else { return 0 }
        return (cloudsAreRaised ? -3 : 5) * scale
    }

    private func cloudAnimation(for group: CloudGroup) -> Animation? {
        guard !reduceMotion else { return nil }
        return .easeInOut(duration: group.duration).repeatForever(autoreverses: true)
    }
}

private struct VividNightScene: View {
    let reduceMotion: Bool

    @State private var starsAreExpanded = false

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / DarkModeToggleMetrics.trackArtboard.width

            ZStack(alignment: .topLeading) {
                ForEach(
                    Array(VividToggleArt.stars.enumerated()),
                    id: \.offset
                ) { _, star in
                    FourPointStar()
                        .fill(VividTogglePalette.star)
                        .frame(
                            width: CGFloat(star.radius * 2) * scale,
                            height: CGFloat(star.radius * 2) * scale
                        )
                        .scaleEffect(
                            reduceMotion ? 1 : (starsAreExpanded ? 1 : 0.2),
                            anchor: .center
                        )
                        .position(
                            x: CGFloat(star.x) * scale,
                            y: CGFloat(star.y) * scale
                        )
                        .animation(
                            starAnimation(for: star.group),
                            value: starsAreExpanded
                        )
                }
            }
            .onAppear {
                starsAreExpanded = true
            }
        }
    }

    private func starAnimation(for group: Int) -> Animation? {
        guard !reduceMotion,
              let duration = VividToggleArt.starDurations[group] else {
            return nil
        }
        return .linear(duration: duration).repeatForever(autoreverses: true)
    }
}
