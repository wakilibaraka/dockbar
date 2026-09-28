import Foundation

let path = "Sources/DockBarCore/SegmentView.swift"
var content = try! String(contentsOfFile: path)

let applyChromeMatch = """
        // Shadow configuration based on surface
        let usesGlassChrome = (segment.surface != .solid(colorToken: "barSurface"))
        if usesGlassChrome {
            layer?.shadowOpacity = 0.35
            layer?.shadowRadius = 12
"""
let applyChromeReplace = """
        // Shadow configuration based on surface
        let usesGlassChrome = (segment.surface != .solid(colorToken: "barSurface"))
        
        switch segment.surface {
        case .solid:
            effectView.material = .windowBackground
            effectView.blendingMode = .withinWindow
        case .adaptive, .acrylic:
            effectView.material = .popover
            effectView.blendingMode = .behindWindow
        }

        if usesGlassChrome {
            layer?.shadowOpacity = 0.35
            layer?.shadowRadius = 12
"""
content = content.replacingOccurrences(of: applyChromeMatch, with: applyChromeReplace)

let switchSurfaceMatch = """
        switch segment.surface {
        case .solid(let token):
            surfaceLayer.backgroundColor = resolveColorToken(token).cgColor
        case .adaptive(let light, let dark):
"""
let switchSurfaceReplace = """
        switch segment.surface {
        case .solid:
            surfaceLayer.backgroundColor = NSColor.clear.cgColor
        case .adaptive(let light, let dark):
"""
content = content.replacingOccurrences(of: switchSurfaceMatch, with: switchSurfaceReplace)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
