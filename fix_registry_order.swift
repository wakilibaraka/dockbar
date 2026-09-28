import Foundation

let path = "Sources/DockBarCore/ThemeRegistry.swift"
var content = try! String(contentsOfFile: path)

let oldIndicator = """
        let dotsIndicator = IndicatorStyle(
            kind: .dots,
            unfocusedWidth: 4, focusedWidth: 6, thickness: 4,
            minimizedIconOpacity: 0.5, animationDuration: 0.15,
            groupedSegmented: false, colorToken: "indicator"
        )
"""
let newIndicator = """
        let dotsIndicator = IndicatorStyle(
            kind: .dots,
            unfocusedWidth: 4, focusedWidth: 6, thickness: 4,
            groupedSegmented: false, colorToken: "indicator",
            minimizedIconOpacity: 0.5, animationDuration: 0.15
        )
"""
content = content.replacingOccurrences(of: oldIndicator, with: newIndicator)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
