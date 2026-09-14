import AppKit

protocol QuickSetting: AnyObject {
    var id: String { get }
    var title: String { get }
    var symbolName: String { get }
    var isOn: Bool { get }
    var isAction: Bool { get } // true = momentary action (no on/off state)
    var settingsURL: URL? { get } // Used for right-click to open sys prefs
    var customImage: NSImage? { get }
    func toggle()
    func refreshState() // Re-read system state
}

extension QuickSetting {
    var isAction: Bool { false }
    var settingsURL: URL? { nil }
    var customImage: NSImage? { nil }
}
