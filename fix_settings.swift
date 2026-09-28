import Foundation

let path = "Sources/DeskBar/Models/TaskbarSettings.swift"
var content = try! String(contentsOfFile: path)

// 1. Remove DeskBarLayoutMode enum
if let range = content.range(of: "enum DeskBarLayoutMode: String, CaseIterable {") {
    let endRange = content[range.lowerBound...].range(of: "\n}\n")!
    content.removeSubrange(range.lowerBound...endRange.upperBound)
}

// 2. Add new enums
let newEnums = """
public enum DeskBarPreset: String, CaseIterable, Codable {
    case fullWidth, compact, split
}

public enum DeskBarEdgeStyle: String, CaseIterable, Codable {
    case rounded, sharp
}
"""
content = content.replacingOccurrences(of: "import AppKit", with: "import AppKit\n\n" + newEnums)

// 3. Replace @Published var layoutMode
let layoutModeDecl = """
    @Published var layoutMode: DeskBarLayoutMode {
        didSet {
            defaults.set(layoutMode.rawValue, forKey: "layoutMode")
            if layoutMode == .windows11FullWidth || layoutMode == .windows11Floating {
                showTitles = false
            }
        }
    }
"""
let newProps = """
    @Published var preset: DeskBarPreset {
        didSet { defaults.set(preset.rawValue, forKey: "preset") }
    }
    
    @Published var edgeStyle: DeskBarEdgeStyle {
        didSet { defaults.set(edgeStyle.rawValue, forKey: "edgeStyle") }
    }
"""
content = content.replacingOccurrences(of: layoutModeDecl, with: newProps)

// 4. Remove useSplitTheme
let useSplitThemeDecl = """
    @Published var useSplitTheme: Bool {
        didSet { defaults.set(useSplitTheme, forKey: "useSplitTheme") }
    }
"""
content = content.replacingOccurrences(of: useSplitThemeDecl, with: "")

// 5. Update init
let oldInitLine = """
        layoutMode = DeskBarLayoutMode(rawValue: defaults.string(forKey: "layoutMode") ?? "") ?? .compactGlass
        useSplitTheme = defaults.object(forKey: "useSplitTheme") as? Bool ?? false
"""
let newInitLine = """
        // Migrate old layoutMode to preset/edge if needed
        let oldLayoutModeStr = defaults.string(forKey: "layoutMode") ?? ""
        if !oldLayoutModeStr.isEmpty, let old = defaults.string(forKey: "layoutMode") {
            switch old {
            case "fullWidth", "fullWidthGlass", "windows11FullWidth":
                preset = .fullWidth
                edgeStyle = .sharp
            case "compact", "compactGlass":
                preset = .compact
                edgeStyle = .rounded
            case "windows11Floating", "floatingCenter", "macos.threeZone":
                preset = .split
                edgeStyle = .rounded
            default:
                preset = .split
                edgeStyle = .rounded
            }
            defaults.removeObject(forKey: "layoutMode")
            defaults.removeObject(forKey: "useSplitTheme")
            edgeStyle = DeskBarEdgeStyle(rawValue: defaults.string(forKey: "edgeStyle") ?? "") ?? edgeStyle
            preset = DeskBarPreset(rawValue: defaults.string(forKey: "preset") ?? "") ?? preset
        } else {
            preset = DeskBarPreset(rawValue: defaults.string(forKey: "preset") ?? "") ?? .split
            edgeStyle = DeskBarEdgeStyle(rawValue: defaults.string(forKey: "edgeStyle") ?? "") ?? .rounded
        }
"""
content = content.replacingOccurrences(of: oldInitLine, with: newInitLine)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
print("Settings updated")
