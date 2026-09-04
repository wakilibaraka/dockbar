import AppKit

final class HideDesktopQuickSetting: QuickSetting {
    let id = "hideDesktop"
    let title = "Hide Desktop"
    let symbolName = "rectangle.dashed"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        let val = UserDefaults(suiteName: "com.apple.finder")?.object(forKey: "CreateDesktop")
        if let b = val as? Bool {
            isOn = !b
        } else {
            isOn = false
        }
    }
    
    func toggle() {
        let newShowDesktop = isOn // currently hidden, so toggle to show
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "com.apple.finder", "CreateDesktop", "-bool", newShowDesktop ? "YES" : "NO"]
        try? proc.run()
        proc.waitUntilExit()
        let killall = Process()
        killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killall.arguments = ["Finder"]
        try? killall.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.refreshState() }
    }
}
