import Foundation

let path1 = "Tests/SnapshotTests/main.swift"
var content1 = try! String(contentsOfFile: path1)
content1 = content1.replacingOccurrences(of: "        .taskView:    CGSize(width: 44, height: 44),\n", with: "")
try! content1.write(toFile: path1, atomically: true, encoding: .utf8)

let path2 = "Sources/DockBarCore/LayoutEngine.swift"
var content2 = try! String(contentsOfFile: path2)
content2 = content2.replacingOccurrences(of: "    case taskView", with: "")
try! content2.write(toFile: path2, atomically: true, encoding: .utf8)

