import AppKit

final class DarkModeQuickSetting: QuickSetting {
    let id = "darkMode"
    let title = "Dark Mode"
    let symbolName = "moon.fill"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    
    func toggle() {
        let targetValue = isOn ? "Light" : "Dark"
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: targetValue
        )
        // Also try defaults
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "-g", "AppleInterfaceStyle", isOn ? "" : "Dark"]
        try? proc.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshState()
        }
    }
}
