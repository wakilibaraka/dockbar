import AppKit

final class ShowFinderPathBarQuickSetting: QuickSetting {
    let id = "finderPathBar"
    let title = "Finder Path Bar"
    let symbolName = "sidebar.leading"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = UserDefaults(suiteName: "com.apple.finder")?.bool(forKey: "ShowPathbar") ?? false
    }
    
    func toggle() {
        let newValue = !isOn
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "com.apple.finder", "ShowPathbar", "-bool", newValue ? "YES" : "NO"]
        try? proc.run()
        proc.waitUntilExit()
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Finder"]
        try? killall.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.refreshState() }
    }
}
