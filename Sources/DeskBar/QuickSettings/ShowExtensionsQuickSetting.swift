import AppKit

final class ShowExtensionsQuickSetting: QuickSetting {
    let id = "showExtensions"
    let title = "Show Extensions"
    let symbolName = "doc.text.fill"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = UserDefaults.standard.bool(forKey: "AppleShowAllExtensions")
    }
    
    func toggle() {
        let newValue = !isOn
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "NSGlobalDomain", "AppleShowAllExtensions", "-bool", newValue ? "YES" : "NO"]
        try? proc.run()
        proc.waitUntilExit()
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Finder"]
        try? killall.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.refreshState() }
    }
}
