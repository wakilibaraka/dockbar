import Foundation
let path = "Sources/DockBarCore/TaskbarTheme.swift"
var lines = try! String(contentsOfFile: path).components(separatedBy: .newlines)

if let idx = lines.firstIndex(where: { $0.contains("public init(") && $0.contains("id: String, surface: SurfaceStyle, border: SegmentBorder,") && !$0.contains("minWidth") }) {
    // Delete lines until }
    var endIdx = idx
    while !lines[endIdx].hasPrefix("    }") {
        endIdx += 1
    }
    lines.removeSubrange(idx...endIdx)
}

try! lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
