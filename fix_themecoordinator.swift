import Foundation

let path = "Sources/DeskBar/Views/Engine/ThemeCoordinator.swift"
var content = try! String(contentsOfFile: path)

let oldStart = """
            case "startButton":
                let start = AppsLauncherButtonView()
                containerView.setWidgetView(start, for: def.id)
            default: break
"""

let newStart = """
            case "startButton":
                let start = AppsLauncherButtonView()
                containerView.setWidgetView(start, for: def.id)
            case "liveEvents":
                // Minimal placeholder for now
                let v = NSButton(title: "Live Events", target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                containerView.setWidgetView(v, for: def.id)
            case "taskView":
                let v = NSButton(image: NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                v.isBordered = false
                containerView.setWidgetView(v, for: def.id)
            case "search":
                let v = NSSearchField()
                v.placeholderString = "Search"
                containerView.setWidgetView(v, for: def.id)
            case "widgetsBoard":
                let v = NSButton(image: NSImage(systemSymbolName: "rectangle.3.offgrid", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                v.isBordered = false
                containerView.setWidgetView(v, for: def.id)
            case "downloads":
                let v = NSButton(image: NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                v.isBordered = false
                containerView.setWidgetView(v, for: def.id)
            default: break
"""

content = content.replacingOccurrences(of: oldStart, with: newStart)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
