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
            let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
            let contents = (try? FileManager.default.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil)) ?? []
            for item in contents {
                try? FileManager.default.removeItem(at: item)
            }
        }
    }
}
