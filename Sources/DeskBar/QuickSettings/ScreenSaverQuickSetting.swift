import AppKit

final class ScreenSaverQuickSetting: QuickSetting {
    let id = "screenSaver"
    let title = "Screen Saver"
    let symbolName = "sparkles.tv.fill"
    var isOn: Bool = false
    let isAction: Bool = true
    
    func refreshState() {}
    
    func toggle() {
        if let url = URL(string: "file:///System/Library/CoreServices/ScreenSaverEngine.app") {
            NSWorkspace.shared.open(url)
        }
    }
}
