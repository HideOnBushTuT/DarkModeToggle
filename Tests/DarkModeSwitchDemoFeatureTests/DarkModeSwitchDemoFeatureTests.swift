import Foundation
import SwiftUI
import Testing
@testable import DarkModeSwitchDemoFeature

@Suite("Public initializers")
struct PublicInitializerTests {
    @Test("constructs the concise Vivid initializer")
    @MainActor
    func conciseVividInitializer() {
        _ = DarkModeToggle(vivid: .constant(false))
    }

    @Test("keeps historical initializer defaults")
    @MainActor
    @available(*, deprecated)
    func historicalDefaults() {
        let binding = Binding.constant(false)

        #expect(DarkModeToggle(isDarkMode: binding).initializerStyle == .original)
        #expect(DarkModeToggle(vividIsDarkMode: binding).initializerStyle == .vivid)
    }

    @Test("constructs every public modifier style")
    @MainActor
    func constructsModifierStyles() {
        let binding = Binding.constant(false)

        _ = DarkModeToggle(isDarkMode: binding).darkModeStyle(.original)
        _ = DarkModeToggle(isDarkMode: binding).darkModeStyle(.vivid)
        _ = DarkModeToggle(isDarkMode: binding).darkModeStyle(.liquidGlass)
        _ = DarkModeToggle(isDarkMode: binding).darkModeStyle(.automatic)
    }
}

@Suite("Dark mode toggle styles")
struct DarkModeToggleStyleTests {
    @Test("stores an optional style in Environment values")
    func environmentStorage() {
        var values = EnvironmentValues()

        #expect(values.darkModeToggleStyle == nil)
        values.darkModeToggleStyle = .vivid
        #expect(values.darkModeToggleStyle == .vivid)
    }

    @Test("uses the initializer fallback when no modifier is present")
    func initializerFallback() {
        #expect(DarkModeToggleStyleResolver.resolve(
            environmentStyle: nil,
            initializerStyle: .vivid,
            supportsLiquidGlass: true
        ) == .vivid)
    }

    @Test("the nearest Environment style overrides the initializer")
    func environmentOverride() {
        #expect(DarkModeToggleStyleResolver.resolve(
            environmentStyle: .original,
            initializerStyle: .vivid,
            supportsLiquidGlass: true
        ) == .original)
    }

    @Test("resolves the complete platform capability matrix")
    func capabilityMatrix() {
        #expect(resolve(.original, supportsLiquidGlass: false) == .original)
        #expect(resolve(.original, supportsLiquidGlass: true) == .original)
        #expect(resolve(.vivid, supportsLiquidGlass: false) == .vivid)
        #expect(resolve(.vivid, supportsLiquidGlass: true) == .vivid)
        #expect(resolve(.liquidGlass, supportsLiquidGlass: false) == .original)
        #expect(resolve(.liquidGlass, supportsLiquidGlass: true) == .liquidGlass)
        #expect(resolve(.automatic, supportsLiquidGlass: false) == .original)
        #expect(resolve(.automatic, supportsLiquidGlass: true) == .liquidGlass)
    }

    private func resolve(
        _ style: DarkModeToggle.Style,
        supportsLiquidGlass: Bool
    ) -> DarkModeToggleVisualStyle {
        DarkModeToggleStyleResolver.resolve(
            environmentStyle: style,
            initializerStyle: .original,
            supportsLiquidGlass: supportsLiquidGlass
        )
    }
}

@Suite("Package boundaries")
struct PackageBoundaryTests {
    @Test("keeps application ContentView out of the package")
    func excludesApplicationContentView() {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appContentView = packageRoot
            .appending(path: "Sources")
            .appending(path: "DarkModeSwitchDemoFeature")
            .appending(path: "ContentView.swift")

        #expect(!FileManager.default.fileExists(atPath: appContentView.path))
    }
}

@Suite("Dark mode toggle metrics")
struct DarkModeToggleMetricsTests {
    @Test("matches the source component geometry at 130 points wide")
    func sourceGeometry() {
        let metrics = DarkModeToggleMetrics(width: 130)

        #expect(abs(metrics.componentHeight - 80) < 0.0001)
        #expect(abs(metrics.trackHeight - 51.84971098) < 0.0001)
        #expect(abs(metrics.celestialScale - (156.0 / 173.0)) < 0.0001)
        #expect(abs(metrics.celestialVerticalInset - 2.12716763) < 0.0001)
    }

    @Test("preserves the source light and dark translations")
    func sourceTranslations() {
        let metrics = DarkModeToggleMetrics(width: 130)

        #expect(abs(metrics.translationX(isDarkMode: false) - (-90.17341040)) < 0.0001)
        #expect(abs(metrics.translationX(isDarkMode: true) - (-22.54335260)) < 0.0001)
        #expect(abs(metrics.translationX(progress: 0.5) - (-56.35838150)) < 0.0001)
        #expect(abs(metrics.translationTravel - 67.63005780) < 0.0001)
    }

    @Test("derives the Liquid Glass scene from the existing track scale")
    func liquidGlassGeometry() {
        let metrics = DarkModeToggleMetrics(width: 130)
        let sceneMetrics = metrics.liquidGlassSceneMetrics

        #expect(abs(metrics.liquidGlassShellInset - (390.0 / 173.0)) < 0.0001)
        #expect(abs(sceneMetrics.width - (130.0 - 780.0 / 173.0)) < 0.0001)
        #expect(sceneMetrics.trackHeight < metrics.trackHeight)
    }
}

@Suite("Dark mode toggle interaction")
struct DarkModeToggleInteractionTests {
    @Test("maps binding endpoints to normalized progress")
    func restingProgress() {
        #expect(DarkModeToggleInteraction.restingProgress(isDarkMode: false) == 0)
        #expect(DarkModeToggleInteraction.restingProgress(isDarkMode: true) == 1)
    }

    @Test("normalizes symmetric translations and clamps both bounds")
    func translatedProgress() {
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 0,
            translation: 25,
            travel: 100
        ) == 0.25)
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 1,
            translation: -25,
            travel: 100
        ) == 0.75)
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 0,
            translation: -20,
            travel: 100
        ) == 0)
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 1,
            translation: 20,
            travel: 100
        ) == 1)
    }

    @Test("selects an axis from the dominant translation")
    func dragAxis() {
        #expect(DarkModeToggleInteraction.axis(
            for: CGSize(width: 12, height: 4)
        ) == .horizontal)
        #expect(DarkModeToggleInteraction.axis(
            for: CGSize(width: 4, height: 12)
        ) == .vertical)
        #expect(DarkModeToggleInteraction.axis(
            for: CGSize(width: 8, height: 8)
        ) == .vertical)
    }

    @Test("uses predicted progress and a dark-inclusive midpoint")
    func predictedTarget() {
        #expect(!DarkModeToggleInteraction.targetIsDark(
            startingAt: 0,
            predictedTranslation: 49,
            travel: 100
        ))
        #expect(DarkModeToggleInteraction.targetIsDark(
            startingAt: 0,
            predictedTranslation: 50,
            travel: 100
        ))
        #expect(!DarkModeToggleInteraction.targetIsDark(
            startingAt: 1,
            predictedTranslation: -51,
            travel: 100
        ))
    }
}

@Suite("Dark mode toggle source artwork")
struct DarkModeToggleArtTests {
    @Test("preserves all source cloud groups")
    func sourceClouds() {
        let groups = DarkModeToggleArt.cloudGroups

        #expect(groups.count == 4)
        #expect(groups.allSatisfy { $0.circles.count == 6 })
        #expect(groups.map(\.duration) == [3.5, 4.5, 2.5, 5.5])
        #expect(groups.map(\.opacity) == [0.95, 0.95, 0.6, 0.6])
        #expect(groups[0].circles[0] == ArtCircle(x: 94.2504, y: 60.8421, radius: 13.65))
        #expect(groups[3].circles[5] == ArtCircle(x: 105.433, y: 60.3442, radius: 13.65))
    }

    @Test("preserves all source stars and twinkle timings")
    func sourceStars() {
        let stars = DarkModeToggleArt.stars

        #expect(stars.count == 22)
        #expect(stars.filter { $0.group == 0 }.count == 2)
        #expect(DarkModeToggleArt.starDurations == [1: 3, 2: 2, 3: 1, 4: 5])
        #expect(stars[0] == ArtStar(group: 1, x: 16.95, y: 23.45, radius: 1.95))
        #expect(stars[19] == ArtStar(group: 1, x: 83.25, y: 39.05, radius: 0.65))
        #expect(stars.last == ArtStar(group: 3, x: 45.55, y: 26.05, radius: 0.65))
    }

    @Test("keeps vivid artwork independent from the original artwork")
    func vividArtwork() {
        #expect(VividToggleArt.cloudGroups.count == 2)
        #expect(VividToggleArt.cloudGroups.allSatisfy { $0.circles.count == 6 })
        #expect(VividToggleArt.stars.count == 6)
        #expect(VividToggleArt.stars.map(\.group) == [1, 2, 3, 4, 5, 6])
        #expect(VividToggleArt.starDurations == [
            1: 3.5,
            2: 4.1,
            3: 4.9,
            4: 5.3,
            5: 3,
            6: 2.2,
        ])
    }
}
