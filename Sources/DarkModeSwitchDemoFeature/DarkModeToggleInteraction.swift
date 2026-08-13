import CoreGraphics

enum DarkModeToggleDragAxis: Sendable, Equatable {
    case horizontal
    case vertical
}

struct DarkModeToggleInteraction: Sendable {
    static let dragThreshold: CGFloat = 10

    static func restingProgress(isDarkMode: Bool) -> CGFloat {
        isDarkMode ? 1 : 0
    }

    static func progress(
        startingAt startProgress: CGFloat,
        translation: CGFloat,
        travel: CGFloat
    ) -> CGFloat {
        guard travel > 0 else {
            return clamped(startProgress)
        }

        return clamped(startProgress + translation / travel)
    }

    static func axis(for translation: CGSize) -> DarkModeToggleDragAxis {
        abs(translation.width) > abs(translation.height) ? .horizontal : .vertical
    }

    static func targetIsDark(
        startingAt startProgress: CGFloat,
        predictedTranslation: CGFloat,
        travel: CGFloat
    ) -> Bool {
        progress(
            startingAt: startProgress,
            translation: predictedTranslation,
            travel: travel
        ) >= 0.5
    }

    private static func clamped(_ progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }
}
