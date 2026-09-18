import AppKit

final class ScreenshotQuickSetting: QuickSetting {
    let id = "screenshot"
    let title = "Screenshot"
    let symbolName = "camera.viewfinder"
    var isOn: Bool = false
    let isAction: Bool = true
    
    func refreshState() {}
    
    func toggle() {
        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i"]
            try? process.run()
        }
    }
}
