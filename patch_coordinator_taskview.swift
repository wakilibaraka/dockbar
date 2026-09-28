import Foundation

let path1 = "Sources/DeskBar/Views/Engine/ThemeCoordinator.swift"
var content1 = try! String(contentsOfFile: path1)
content1 = content1.replacingOccurrences(of: "        settings.$showTaskView.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)\n", with: "")
content1 = content1.replacingOccurrences(of: "        settings.$showDownloads.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)", with: "        settings.$showDownloads.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)\n        settings.$showTrash.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)")

let trashTarget = """
            case "trash":
                let v = NSButton(image: NSImage(systemSymbolName: "trash", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                v.isBordered = false
                v.target = TrashActionHandler.shared
                v.action = #selector(TrashActionHandler.shared.openTrash)
                
                // Add right-click menu
                let menu = NSMenu()
                let emptyItem = NSMenuItem(title: "Empty Trash", action: #selector(TrashActionHandler.shared.emptyTrash), keyEquivalent: "")
                emptyItem.target = TrashActionHandler.shared
                menu.addItem(emptyItem)
                v.menu = menu
                
                containerView.setWidgetView(v, for: def.id)
"""

// We need to inject the case "trash" logic.
let switchTarget = """
            case "downloads":
"""
content1 = content1.replacingOccurrences(of: switchTarget, with: trashTarget + "\n            case \"downloads\":")

let switchStateTarget = """
            case "downloads":
                isEnabled = settings.showDownloads
"""
content1 = content1.replacingOccurrences(of: switchStateTarget, with: """
            case "trash":
                isEnabled = settings.showTrash
            case "downloads":
                isEnabled = settings.showDownloads
""")

// Add TrashActionHandler
let handlerTarget = """
class DownloadsActionHandler {
"""
let trashHandler = """
class TrashActionHandler {
    static let shared = TrashActionHandler()
    @objc func openTrash() {
        let url = URL(fileURLWithPath: "/Users/" + NSUserName() + "/.Trash")
        NSWorkspace.shared.open(url)
    }
    
    @objc func emptyTrash() {
        let alert = NSAlert()
        alert.messageText = "Empty Trash?"
        alert.informativeText = "Are you sure you want to permanently erase the items in the Trash?"
        alert.addButton(withTitle: "Empty Trash")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", "tell application \\"Finder\\" to empty trash"]
            try? task.run()
        }
    }
}

class DownloadsActionHandler {
"""
content1 = content1.replacingOccurrences(of: handlerTarget, with: trashHandler)

try! content1.write(toFile: path1, atomically: true, encoding: .utf8)
