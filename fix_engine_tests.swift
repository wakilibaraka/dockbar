import Foundation

let path = "Tests/EngineTests/main.swift"
var content = try! String(contentsOfFile: path)

// Fix indicator tests
content = content.replacingOccurrences(of: "assertApprox(ind.unfocusedWidth, 4.0, \"unfocusedWidth\")", with: "assertApprox(ind.unfocusedWidth, 16.0, \"unfocusedWidth\")")
content = content.replacingOccurrences(of: "assertApprox(ind.focusedWidth, 6.0, \"focusedWidth\")", with: "assertApprox(ind.focusedWidth, 24.0, \"focusedWidth\")")
content = content.replacingOccurrences(of: "assertApprox(ind.thickness, 4.0, \"thickness\")", with: "assertApprox(ind.thickness, 3.0, \"thickness\")")
content = content.replacingOccurrences(of: "assertEqual(ind.groupedSegmented, false, \"groupedSegmented must be false\")", with: "assertTrue(ind.groupedSegmented, \"groupedSegmented must be true\")")
content = content.replacingOccurrences(of: "groupedSegmented = false for dots", with: "groupedSegmented = true for win11 themes")
content = content.replacingOccurrences(of: "unfocusedWidth = 4, focusedWidth = 6, thickness = 4", with: "unfocusedWidth = 16, focusedWidth = 24, thickness = 3")

let oldTest9 = """
test("fullWidth_sharp has exactly 1 segment, interSegmentGap=0") {
    let t = registry.theme(for: "fullWidth_sharp")!
    assertEqual(t.zones.count, 1)
    assertEqual(t.zones[0].segments.count, 1)
    assertEqual(t.zones[0].interSegmentGap, 0)
}
"""
let newTest9 = """
test("All 6 generated themes have exactly 3 zones with anchors leadingEdge/center/trailingEdge") {
    let presets = ["fullWidth", "compact", "split"]
    let edges = ["rounded", "sharp"]
    for p in presets {
        for e in edges {
            let id = "\\(p)_\\(e)"
            let t = registry.theme(for: id)!
            assertEqual(t.zones.count, 3, "\\(id) must have 3 zones")
            if t.zones.count == 3 {
                assertEqual(t.zones[0].anchor, .leadingEdge, "\\(id) zone 0 anchor")
                assertEqual(t.zones[1].anchor, .center, "\\(id) zone 1 anchor")
                assertEqual(t.zones[2].anchor, .trailingEdge, "\\(id) zone 2 anchor")
            }
        }
    }
}
test("fullWidth center segment has sizing .fill") {
    let t = registry.theme(for: "fullWidth_sharp")!
    if t.zones.count >= 2 {
        assertEqual(t.zones[1].segments.first?.sizing == .fill, true, "fullWidth center must fill")
    }
}
"""
content = content.replacingOccurrences(of: oldTest9, with: newTest9)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
