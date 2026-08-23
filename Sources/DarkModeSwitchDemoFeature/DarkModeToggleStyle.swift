import SwiftUI

public extension DarkModeToggle {
    /// A built-in surface treatment for descendant dark-mode toggles.
    struct Style: Hashable, Sendable {
        fileprivate let storage: Storage

        fileprivate init(_ storage: Storage) {
            self.storage = storage
        }

        /// Uses the existing non-Glass surface on every supported platform.
        public static let standard = Self(.standard)

        /// Uses native Liquid Glass on iOS 26+, and Standard elsewhere.
        public static let glass = Self(.glass)

        fileprivate enum Storage: Hashable, Sendable {
            case standard
            case glass
        }
    }
}

private struct DarkModeToggleStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: DarkModeToggle.Style = .standard
}

extension EnvironmentValues {
    // Standard is the natural default because Original/Vivid is selected by
    // the initializer rather than inferred from the surface style.
    var darkModeToggleStyle: DarkModeToggle.Style {
        get { self[DarkModeToggleStyleEnvironmentKey.self] }
        set { self[DarkModeToggleStyleEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Selects the surface treatment for descendant dark-mode toggles.
    func style(_ style: DarkModeToggle.Style) -> some View {
        environment(\.darkModeToggleStyle, style)
    }
}

enum DarkModeToggleVariant: Equatable, Sendable {
    case original
    case vivid
}

enum DarkModeToggleSurface: Equatable, Sendable {
    case standard
    case glass
}

struct DarkModeToggleRendering: Equatable, Sendable {
    let variant: DarkModeToggleVariant
    let surface: DarkModeToggleSurface
}

enum DarkModeToggleStyleResolver {
    static func resolve(
        variant: DarkModeToggleVariant,
        style: DarkModeToggle.Style,
        supportsLiquidGlass: Bool
    ) -> DarkModeToggleRendering {
        let surface: DarkModeToggleSurface

        switch style.storage {
        case .standard:
            surface = .standard
        case .glass:
            // Unsupported systems keep the initialized artwork and drop only
            // the surface instead of receiving an imitation Glass renderer.
            surface = supportsLiquidGlass ? .glass : .standard
        }

        return DarkModeToggleRendering(variant: variant, surface: surface)
    }
}
