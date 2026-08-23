import Foundation
import SwiftUI
import Testing
@testable import DarkModeSwitchDemoFeature

@Suite("Public initializers")
struct PublicInitializerTests {
    @Test("keeps initializer-selected variants independent")
    @MainActor
    @available(*, deprecated)
    func initializerVariants() {
        let binding = Binding.constant(false)

        #expect(DarkModeToggle(isDarkMode: binding).variant == .original)
        #expect(DarkModeToggle(vivid: binding).variant == .vivid)
        #expect(DarkModeToggle(vividIsDarkMode: binding).variant == .vivid)
    }
}

@Suite("Dark mode toggle styles")
struct DarkModeToggleStyleTests {
    @Test("defaults Environment style to Standard")
    func environmentStorage() {
        var values = EnvironmentValues()

        #expect(values.darkModeToggleStyle == .standard)
        values.darkModeToggleStyle = .glass
        #expect(values.darkModeToggleStyle == .glass)
    }

    @Test("preserves variants across the capability matrix")
    func capabilityMatrix() {
        #expect(resolve(.original, .standard, false) == value(.original, .standard))
        #expect(resolve(.original, .standard, true) == value(.original, .standard))
        #expect(resolve(.vivid, .standard, false) == value(.vivid, .standard))
        #expect(resolve(.vivid, .standard, true) == value(.vivid, .standard))
        #expect(resolve(.original, .glass, false) == value(.original, .standard))
        #expect(resolve(.original, .glass, true) == value(.original, .glass))
        #expect(resolve(.vivid, .glass, false) == value(.vivid, .standard))
        #expect(resolve(.vivid, .glass, true) == value(.vivid, .glass))
    }

    private func resolve(
        _ variant: DarkModeToggleVariant,
        _ style: DarkModeToggle.Style,
        _ supportsLiquidGlass: Bool
    ) -> DarkModeToggleRendering {
        DarkModeToggleStyleResolver.resolve(
            variant: variant,
            style: style,
            supportsLiquidGlass: supportsLiquidGlass
        )
    }

    private func value(
        _ variant: DarkModeToggleVariant,
        _ surface: DarkModeToggleSurface
    ) -> DarkModeToggleRendering {
        DarkModeToggleRendering(variant: variant, surface: surface)
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

    @Test("guards iOS 26 SDK symbols from the Swift 6.1 compiler")
    func guardsLiquidGlassSDKSymbols() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sources = packageRoot
            .appending(path: "Sources")
            .appending(path: "DarkModeSwitchDemoFeature")
        let compilerGuard = "#if os(iOS) && compiler(>=6.2)"
        let nativeTrackSource = try String(
            contentsOf: sources.appending(path: "LiquidGlassToggleTrack.swift"),
            encoding: .utf8
        )
        let toggleSource = try String(
            contentsOf: sources.appending(path: "DarkModeToggle.swift"),
            encoding: .utf8
        )

        // The native track and both references to it must disappear entirely
        // when this package is compiled by the Swift 6.1 toolchain in Xcode 16.
        #expect(nativeTrackSource.hasPrefix(compilerGuard))
        #expect(toggleSource.components(separatedBy: compilerGuard).count - 1 == 2)
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
