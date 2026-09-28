import Foundation

let path = "Sources/DockBarCore/TaskbarTheme.swift"
var content = try! String(contentsOfFile: path)

content = content.replacingOccurrences(of: "case floating", with: "case floating\n    case compact")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
