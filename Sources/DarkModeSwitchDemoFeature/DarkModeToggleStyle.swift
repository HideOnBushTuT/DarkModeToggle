import SwiftUI

public extension DarkModeToggle {
    /// A built-in visual treatment for ``DarkModeToggle``.
    struct Style: Hashable, Sendable {
        fileprivate let storage: Storage

        fileprivate init(_ storage: Storage) {
            self.storage = storage
        }

        /// Preserves the original soft day and night artwork on every platform.
        static let original = Self(.original)

        /// Uses the high-saturation artwork on every platform.
        static let vivid = Self(.vivid)

        /// Uses native Liquid Glass on iOS 26+, and Original elsewhere.
        static let liquidGlass = Self(.liquidGlass)

        /// Follows the newest supported system treatment, and Original elsewhere.
        static let automatic = Self(.automatic)

        fileprivate enum Storage: Hashable, Sendable {
            case original
            case vivid
            case liquidGlass
            case automatic
        }
    }
}

private struct DarkModeToggleStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: DarkModeToggle.Style? = nil
}

extension EnvironmentValues {
    // Optionality distinguishes no modifier from an explicit style, allowing
    // compatibility initializers to supply their historical default.
    var darkModeToggleStyle: DarkModeToggle.Style? {
        get { self[DarkModeToggleStyleEnvironmentKey.self] }
        set { self[DarkModeToggleStyleEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Selects the visual treatment for descendant dark-mode toggles.
    func darkModeStyle(_ style: DarkModeToggle.Style) -> some View {
        environment(\.darkModeToggleStyle, style)
    }
}

enum DarkModeToggleStyleResolver {
    static func resolve(
        environmentStyle: DarkModeToggle.Style?,
        initializerStyle: DarkModeToggle.Style,
        supportsLiquidGlass: Bool
    ) -> DarkModeToggleVisualStyle {
        let requestedStyle = environmentStyle ?? initializerStyle

        switch requestedStyle.storage {
        case .original:
            return .original
        case .vivid:
            return .vivid
        case .liquidGlass, .automatic:
            // Unsupported systems intentionally preserve the existing Original
            // renderer instead of receiving an imitation glass treatment.
            return supportsLiquidGlass ? .liquidGlass : .original
        }
    }
}
