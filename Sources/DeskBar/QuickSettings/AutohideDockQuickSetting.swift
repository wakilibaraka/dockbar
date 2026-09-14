import AppKit

final class AutohideDockQuickSetting: QuickSetting {
    let id = "autohideDock"
    let title = "Dock Autohide"
    let symbolName = "dock.rectangle"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
    }
    
    func toggle() {
        let newValue = !isOn
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        // USING CORRECT ARGUMENTS FROM INSTRUCTIONS
        proc.arguments = ["write", "com.apple.dock", "autohide", "-bool", newValue ? "YES" : "NO"]
        try? proc.run()
        proc.waitUntilExit()
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Dock"]
        try? killall.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.refreshState() }
    }
}
