import AppKit

struct AppGroup: Identifiable {
    let id: String
    let appName: String
    let icon: NSImage?
    var windows: [WindowInfo]
    var isExpanded: Bool = false
    var isPinned: Bool = false
    var pinnedApp: PinnedApp? = nil

    var windowCount: Int { windows.count }
}
