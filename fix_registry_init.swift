import Foundation

let path = "Sources/DockBarCore/ThemeRegistry.swift"
var content = try! String(contentsOfFile: path)

content = content.replacingOccurrences(of: "sizing: .hugContents(minWidth: nil)", with: "sizing: .hugContents, minWidth: nil")
content = content.replacingOccurrences(of: "sizing: .hugContents(minWidth: 420)", with: "sizing: .hugContents, minWidth: 420")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
