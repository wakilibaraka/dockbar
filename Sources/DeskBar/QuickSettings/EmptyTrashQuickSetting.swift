import AppKit

final class EmptyTrashQuickSetting: QuickSetting {
    let id = "emptyTrash"
    let title = "Empty Trash"
    let symbolName = "trash.fill"
    var isOn: Bool = false
    let isAction: Bool = true
    
    func refreshState() {}
    
    func toggle() {
        DispatchQueue.global(qos: .utility).async {
            let script = "tell application \"Finder\" to empty trash"
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if let err = error {
                    print("Error emptying trash: \(err)")
                }
            }
        }
    }
}
