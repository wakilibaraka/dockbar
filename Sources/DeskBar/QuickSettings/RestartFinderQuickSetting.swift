import AppKit

final class RestartFinderQuickSetting: QuickSetting {
    let id = "restartFinder"
    let title = "Restart Finder"
    let symbolName = "macwindow"
    var isOn: Bool = false
    let isAction: Bool = true
    
    func refreshState() {}
    
    func toggle() {
        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            process.arguments = ["Finder"]
            try? process.run()
        }
    }
}
