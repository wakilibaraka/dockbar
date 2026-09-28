import Foundation

let path = "Tests/EngineTests/main.swift"
var content = try! String(contentsOfFile: path)

content = content.replacingOccurrences(of: "windows11.floatingSplit", with: "split_rounded")
content = content.replacingOccurrences(of: "windows11.floating", with: "compact_rounded")
content = content.replacingOccurrences(of: "fullWidth", with: "fullWidth_sharp")

// Update the required themes list in the last test
let oldRequired = """
    let required = [
        "fullWidth", "fullWidthGlass", "compact", "compactGlass",
        "floatingCenter", "windows11.fullWidth", "windows11.floating", "windows11.floatingSplit", "macos.threeZone"
    ]
"""
let newRequired = """
    let required = [
        "fullWidth_rounded", "fullWidth_sharp",
        "compact_rounded", "compact_sharp",
        "split_rounded", "split_sharp"
    ]
"""
content = content.replacingOccurrences(of: oldRequired, with: newRequired)

// Fix test 4 logic (tray width fixed) since we no longer use fixed tray widths!
// Trailing segments are hugContents now.
let oldTrayWidth = """
test("tray segment width == 260") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    let tray = l.segmentFrames["tray"]!
    if case .fixed(let w) = t.zones.flatMap({ $0.segments }).first(where: { $0.id == "tray" })!.sizing {
        assertApprox(tray.width, w, "tray width == fixed(260)")
    } else {
        assertTrue(false, "tray sizing must be .fixed")
    }
}
"""
let newTrayWidth = """
// (Tray width test removed since we no longer use fixed tray sizing)
"""
content = content.replacingOccurrences(of: oldTrayWidth, with: newTrayWidth)

// Some tests refer to "task" segment, we changed it to "task_seg" in split, "unified" in compact/fullWidth, "left_seg", "tray_seg"
content = content.replacingOccurrences(of: "\"task\"", with: "\"task_seg\"")
content = content.replacingOccurrences(of: "\"tray\"", with: "\"tray_seg\"")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
