import AppKit

final class DockRecentAppsQuickSetting: QuickSetting {
    let id = "dockRecentApps"
    let title = "Dock Recents"
    let symbolName = "clock.fill"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "show-recents") ?? true
    }
    
    func toggle() {
        let newValue = !isOn
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "com.apple.dock", "show-recents", "-bool", newValue ? "YES" : "NO"]
        try? proc.run()
        proc.waitUntilExit()
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Dock"]
        try? killall.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.refreshState() }
    }
}
