import Foundation

let path = "Tests/SnapshotTests/main.swift"
var content = try! String(contentsOfFile: path)

let oldFixtures = """
    static let canonicalWidgets: [SlotKind: CGSize] = [
        .leading:     CGSize(width: 80, height: 28),
        .tray:        CGSize(width: 260, height: 40),
        .startButton: CGSize(width: 40, height: 40),
    ]
"""

let newFixtures = """
    static let canonicalWidgets: [SlotKind: CGSize] = [
        .leading:     CGSize(width: 80, height: 28),
        .liveEvents:  CGSize(width: 80, height: 28),
        .startButton: CGSize(width: 44, height: 44),
        .taskView:    CGSize(width: 44, height: 44),
        .search:      CGSize(width: 150, height: 44),
        .widgetsBoard:CGSize(width: 44, height: 44),
        .downloads:   CGSize(width: 44, height: 44),
        .tray:        CGSize(width: 260, height: 40)
    ]
"""
content = content.replacingOccurrences(of: oldFixtures, with: newFixtures)

let oldMount = """
    for id in reqs.map({ $0.id }) {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
        v.layer?.borderColor = NSColor.systemBlue.cgColor
        v.layer?.borderWidth = 1
        v.layer?.cornerRadius = 4
        container.setWidgetView(v, for: id)
    }
"""

let newMount = """
    for req in reqs {
        let v = NSButton(title: "\\(req.slot)", target: nil, action: nil)
        v.bezelStyle = .texturedRounded
        v.setButtonType(.momentaryPushIn)
        container.setWidgetView(v, for: req.id)
    }
"""
content = content.replacingOccurrences(of: oldMount, with: newMount)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
