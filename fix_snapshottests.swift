import Foundation

let path = "Tests/SnapshotTests/main.swift"
var content = try! String(contentsOfFile: path)

let oldThemes = """
// Only windows11.floatingSplit is snapshot-guarded right now, because it's the only theme actually served by the new stack.
let themeIDs = [
    "windows11.floatingSplit"
]
"""
let newThemes = """
let themeIDs = [
    "split_rounded",
    "split_sharp",
    "compact_rounded",
    "compact_sharp",
    "fullWidth_rounded",
    "fullWidth_sharp"
]
"""
content = content.replacingOccurrences(of: oldThemes, with: newThemes)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
