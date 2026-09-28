import Foundation

let path = "Tests/EngineTests/main.swift"
var content = try! String(contentsOfFile: path)

let oldTest = """
test("fullWidth_sharp has exactly 1 segment, interSegmentGap=0") {
    let t = registry.theme(for: "fullWidth_sharp")!
    assertEqual(t.zones.flatMap({ $0.segments }).count, 1, "fullWidth_sharp must have exactly 1 segment")
    assertApprox(t.zones.first?.interSegmentGap ?? 0, 0, "interSegmentGap must be 0")
}
"""

let newTest = """
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

content = content.replacingOccurrences(of: oldTest, with: newTest)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
