#if os(iOS)
import SwiftUI

@available(iOS 26.0, *)
struct LiquidGlassToggleTrack: View {
    let progress: CGFloat
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool

    var body: some View {
        let sceneMetrics = metrics.liquidGlassSceneMetrics

        ZStack {
            // Keep native Glass outside ToggleTrack's drawingGroup so it can
            // continue sampling the live page content behind the control.
            Color.clear
                .frame(width: metrics.width, height: metrics.trackHeight)
                .glassEffect(.regular.interactive(), in: Capsule())

            ToggleTrack(
                progress: progress,
                metrics: sceneMetrics,
                reduceMotion: reduceMotion
            )
            .frame(width: sceneMetrics.width, height: sceneMetrics.trackHeight)
        }
        .frame(width: metrics.width, height: metrics.trackHeight)
    }
}
#endif
