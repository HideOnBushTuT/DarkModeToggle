#if os(iOS)
import SwiftUI

@available(iOS 26.0, *)
struct LiquidGlassToggleTrack: View {
    let progress: CGFloat
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool
    let variant: DarkModeToggleVariant

    var body: some View {
        let sceneMetrics = metrics.liquidGlassSceneMetrics

        ZStack {
            // Keep native Glass outside ToggleTrack's drawingGroup so it can
            // continue sampling the live page content behind the control.
            Color.clear
                .frame(width: metrics.width, height: metrics.trackHeight)
                .glassEffect(.regular.interactive(), in: Capsule())

            scene(metrics: sceneMetrics)
            .frame(width: sceneMetrics.width, height: sceneMetrics.trackHeight)
        }
        .frame(width: metrics.width, height: metrics.trackHeight)
    }

    @ViewBuilder
    private func scene(metrics: DarkModeToggleMetrics) -> some View {
        switch variant {
        case .original:
            ToggleTrack(
                progress: progress,
                metrics: metrics,
                reduceMotion: reduceMotion
            )
        case .vivid:
            VividToggleTrack(
                progress: progress,
                metrics: metrics,
                reduceMotion: reduceMotion
            )
        }
    }
}
#endif
