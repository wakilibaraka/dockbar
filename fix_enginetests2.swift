import Foundation

let path = "Tests/EngineTests/main.swift"
var lines = try! String(contentsOfFile: path).components(separatedBy: .newlines)

if let idx = lines.firstIndex(where: { $0.contains("let required = [") }) {
    var endIdx = idx
    while !lines[endIdx].contains("]") {
        endIdx += 1
    }
    lines.removeSubrange(idx...endIdx)
    lines.insert("""
    let required = [
        "fullWidth_rounded", "fullWidth_sharp",
        "compact_rounded", "compact_sharp",
        "split_rounded", "split_sharp"
    ]
""", at: idx)
}

try! lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
