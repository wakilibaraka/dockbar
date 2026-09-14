import AppKit

final class XcodeCacheQuickSetting: QuickSetting {
    let id = "xcodeCache"
    let title = "Xcode Cache"
    let symbolName = "hammer.circle.fill"
    var isOn: Bool = false
    let isAction: Bool = true
    
    func refreshState() {}
    
    func toggle() {
        DispatchQueue.global(qos: .utility).async {
            let derivedData = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Developer/Xcode/DerivedData")
            try? FileManager.default.removeItem(at: derivedData)
        }
    }
}
