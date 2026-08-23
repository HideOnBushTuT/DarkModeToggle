import SwiftUI
import Testing
import DarkModeSwitchDemoFeature

@Test("exposes built-in styles to external consumers")
@MainActor
func exposesBuiltInStyles() {
    let toggle = DarkModeToggle(isDarkMode: .constant(false))
    let vivid = DarkModeToggle(vivid: .constant(false))

    _ = toggle.darkModeStyle(.original)
    _ = toggle.darkModeStyle(.vivid)
    _ = toggle.darkModeStyle(.liquidGlass)
    _ = toggle.darkModeStyle(.automatic)
    _ = vivid
}
