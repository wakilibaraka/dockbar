import Foundation

let path1 = "Sources/DeskBar/Views/Engine/ThemeCoordinator.swift"
var content1 = try! String(contentsOfFile: path1)

let duplicateLogic = """
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

// We need to find the SECOND occurrence and replace it with nothing, but wait, the second one is followed by `case "trash": isEnabled = settings.showTrash`.
// Actually I can just replace `duplicateLogic + "\n            case \"trash\":\n                isEnabled = settings.showTrash"` with just the `isEnabled` part.
let target = duplicateLogic + "\n            case \"trash\":\n                isEnabled = settings.showTrash"
let newTarget = """
            case "trash":
                isEnabled = settings.showTrash
"""
content1 = content1.replacingOccurrences(of: target, with: newTarget)
try! content1.write(toFile: path1, atomically: true, encoding: .utf8)

