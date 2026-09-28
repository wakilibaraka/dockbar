import Foundation

let path = "Tests/SnapshotTests/main.swift"
var content = try! String(contentsOfFile: path)

let oldSet = """
    for id in reqs.map({ $0.id }) { container.setWidgetView(NSView(), for: id) }
"""

let newSet = """
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
content = content.replacingOccurrences(of: oldSet, with: newSet)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
