import DarkModeSwitchDemoFeature
import SwiftUI
import Testing

@Test("exposes initializer variants and container styles")
@MainActor
func exposesIndependentVariantAndStyleAPI() {
    let standardGroup = VStack {
        DarkModeToggle(isDarkMode: .constant(false))
        DarkModeToggle(vivid: .constant(false))
    }
    .style(.standard)

    let glassGroup = VStack {
        DarkModeToggle(isDarkMode: .constant(false))
        DarkModeToggle(vivid: .constant(false))
    }
    .style(.glass)

    _ = standardGroup
    _ = glassGroup
}
