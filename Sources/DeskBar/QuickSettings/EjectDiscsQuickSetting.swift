import AppKit

final class EjectDiscsQuickSetting: QuickSetting {
    let id = "ejectDiscs"
    let title = "Eject Discs"
    let symbolName = "eject.fill"
    var isOn: Bool = false
    let isAction: Bool = true
    
    func refreshState() {}
    
    func toggle() {
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeIsRemovableKey], options: []) ?? []
        for vol in volumes {
            if let removable = try? vol.resourceValues(forKeys: [.volumeIsRemovableKey]).volumeIsRemovable, removable {
                try? NSWorkspace.shared.unmountAndEjectDevice(at: vol)
            }
        }
    }
}
