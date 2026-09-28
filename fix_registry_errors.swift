import Foundation

let path = "Sources/DockBarCore/ThemeRegistry.swift"
var content = try! String(contentsOfFile: path)

content = content.replacingOccurrences(of: "kind: .dot,", with: "kind: .dots,")
content = content.replacingOccurrences(of: "groupedSegmented: false", with: "groupedSegmented: false, colorToken: \"indicator\"")
content = content.replacingOccurrences(of: "SegmentSurface.adaptive", with: "SurfaceStyle.adaptive")
content = content.replacingOccurrences(of: "SegmentSurface.solid", with: "SurfaceStyle.solid")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
