import Foundation
let path = "Sources/DockBarCore/ThemeRegistry.swift"
var content = try! String(contentsOfFile: path)
content = content.replacingOccurrences(of: "minWidth: 420", with: "minWidth: nil")
content = content.replacingOccurrences(of: "icons: IconStyle(size: 24, spacing: 8, hitTargetSize: 36)", with: "icons: IconStyle(size: height - 12, spacing: 8, hitTargetSize: height)")
try! content.write(toFile: path, atomically: true, encoding: .utf8)
