import Foundation

let path = "Tests/EngineTests/main.swift"
var content = try! String(contentsOfFile: path)

let old14 = """
// ── 14. Registry ─────────────────────────────────────────────────────────
print("\\n14. Registry completeness & locale rule")
test("all 8 required themes exist") {
    let ids = ["fullWidth", "fullWidthGlass", "compact", "compactGlass", "floatingCenter", "windows11.fullWidth", "windows11.floating", "windows11.floatingSplit"]
    for id in ids {
        assertTrue(registry.theme(for: id) != nil, "Missing theme \\(id)")
    }
}
"""

let new14 = """
// ── 14. Registry ─────────────────────────────────────────────────────────
print("\\n14. Registry completeness & locale rule")
test("all 6 required themes exist") {
    let ids = ["split_rounded", "split_sharp", "compact_rounded", "compact_sharp", "fullWidth_rounded", "fullWidth_sharp"]
    for id in ids {
        assertTrue(registry.theme(for: id) != nil, "Missing theme \\(id)")
    }
}
"""
content = content.replacingOccurrences(of: old14, with: new14)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
