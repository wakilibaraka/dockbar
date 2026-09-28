import Foundation

let path = "Sources/DeskBar/App/AppDelegate.swift"
var content = try! String(contentsOfFile: path)

let oldSwitch = """
            let themeID: String
            if settings.useSplitTheme {
                themeID = "windows11.floatingSplit"
            } else {
                switch settings.layoutMode {
                case .fullWidth: themeID = "fullWidth"
                case .fullWidthGlass: themeID = "fullWidthGlass"
                case .compact: themeID = "compact"
                case .compactGlass: themeID = "compactGlass"
                case .floatingCenter: themeID = "floatingCenter"
                case .windows11FullWidth: themeID = "windows11.fullWidth"
                case .windows11Floating: themeID = "windows11.floating"
                case .macosThreeZone: themeID = "macos.threeZone"
                }
            }
"""

let newSwitch = """
            let themeID = "\\(settings.preset.rawValue)_\\(settings.edgeStyle.rawValue)"
"""
content = content.replacingOccurrences(of: oldSwitch, with: newSwitch)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
