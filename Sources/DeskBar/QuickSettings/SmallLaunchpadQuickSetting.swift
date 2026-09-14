import AppKit

final class SmallLaunchpadQuickSetting: QuickSetting {
    let id = "smallLaunchpad"
    let title = "Small Launchpad"
    let symbolName = "square.grid.3x3.fill"
    var isOn: Bool = false
    
    // Default Launchpad columns is 7 rows, small means more columns
    private let smallColumns = 10
    private let normalColumns = 7
    
    init() { refreshState() }
    
    func refreshState() {
        let cols = UserDefaults(suiteName: "com.apple.dock")?.integer(forKey: "springboard-columns") ?? normalColumns
        isOn = cols >= smallColumns
    }
    
    func toggle() {
        let newCols = isOn ? normalColumns : smallColumns
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "com.apple.dock", "springboard-columns", "-int", "\(newCols)"]
        try? proc.run()
        proc.waitUntilExit()
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Dock"]
        try? killall.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.refreshState() }
    }
}
