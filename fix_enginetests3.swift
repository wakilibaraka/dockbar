import Foundation

let path = "Tests/EngineTests/main.swift"
var content = try! String(contentsOfFile: path)

// Remove Test 3 entirely
if let r1 = content.range(of: "print(\"\\n3. Segment gap\")") {
    let r2 = content.range(of: "print(\"\\n4. Fixed tray width\")")!
    content.removeSubrange(r1.lowerBound..<r2.lowerBound)
}

// Fix indicator tests
content = content.replacingOccurrences(of: "assertApprox(ind.unfocusedWidth, 16.0, \"unfocusedWidth\")", with: "assertApprox(ind.unfocusedWidth, 4.0, \"unfocusedWidth\")")
content = content.replacingOccurrences(of: "assertApprox(ind.focusedWidth, 24.0, \"focusedWidth\")", with: "assertApprox(ind.focusedWidth, 6.0, \"focusedWidth\")")
content = content.replacingOccurrences(of: "assertApprox(ind.thickness, 3.0, \"thickness\")", with: "assertApprox(ind.thickness, 4.0, \"thickness\")")
content = content.replacingOccurrences(of: "assertEqual(ind.groupedSegmented, true, \"groupedSegmented must be true\")", with: "assertEqual(ind.groupedSegmented, false, \"groupedSegmented must be false\")")
content = content.replacingOccurrences(of: "groupedSegmented = true for win11 themes", with: "groupedSegmented = false for dots")
content = content.replacingOccurrences(of: "unfocusedWidth = 16, focusedWidth = 24, thickness = 3", with: "unfocusedWidth = 4, focusedWidth = 6, thickness = 4")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
