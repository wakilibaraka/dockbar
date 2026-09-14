import AppKit

final class HiddenFilesQuickSetting: QuickSetting {
    let id = "hiddenFiles"
    let title = "Hidden Files"
    let symbolName = "eye.fill"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        let value = UserDefaults(suiteName: "com.apple.finder")?.bool(forKey: "AppleShowAllFiles")
        isOn = value ?? false
    }
    
    func toggle() {
        let newValue = !isOn
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "com.apple.finder", "AppleShowAllFiles", newValue ? "YES" : "NO"]
        try? proc.run()
        proc.waitUntilExit()
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Finder"]
        try? killall.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.refreshState() }
    }
}
