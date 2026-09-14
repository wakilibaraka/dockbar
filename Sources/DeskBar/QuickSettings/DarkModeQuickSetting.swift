import AppKit

final class DarkModeQuickSetting: QuickSetting {
    let id = "darkMode"
    let title = "Dark Mode"
    let symbolName = "moon.fill"
    var settingsURL: URL? { URL(string: "x-apple.systempreferences:com.apple.Appearance-Settings.extension") }
    var isOn: Bool = false

    init() { refreshState() }

    func refreshState() {
        isOn = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    func toggle() {
        // AppleScript is the only public API for toggling appearance globally
        let src = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to not dark mode
            end tell
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: src)?.executeAndReturnError(&error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.refreshState()
        }
    }
}
