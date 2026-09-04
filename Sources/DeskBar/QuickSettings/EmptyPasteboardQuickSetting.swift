import AppKit

final class EmptyPasteboardQuickSetting: QuickSetting {
    let id = "emptyPasteboard"
    let title = "Clear Clipboard"
    let symbolName = "clipboard"
    var isOn: Bool = false
    let isAction: Bool = true
    
    func refreshState() {}
    
    func toggle() {
        NSPasteboard.general.clearContents()
    }
}
