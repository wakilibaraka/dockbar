import AppKit

final class AutohideMenuBarQuickSetting: QuickSetting {
    let id = "autohideMenuBar"
    let title = "Menubar Hide"
    let symbolName = "menubar.rectangle"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = UserDefaults(suiteName: "NSGlobalDomain")?.bool(forKey: "_HIHideMenuBar") ?? false
    }
    
    func toggle() {
        let newValue = !isOn
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "NSGlobalDomain", "_HIHideMenuBar", "-bool", newValue ? "YES" : "NO"]
        try? proc.run()
        proc.waitUntilExit()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.refreshState() }
    }
}
