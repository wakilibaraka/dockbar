import Foundation

let path = "Sources/DockBarCore/ThemeRegistry.swift"
var content = try! String(contentsOfFile: path)

// Find the beginning of init()
let initStartRange = content.range(of: "private init() {")!
let initEndRange = content.range(of: "    public func theme(for id: String) -> TaskbarTheme? { themes[id] }")!

let newInit = """
    private init() {
        let compactIcons = IconStyle(size: 24, spacing: 6, hitTargetSize: 32)
        let dotsIndicator = IndicatorStyle(
            kind: .dot,
            unfocusedWidth: 4, focusedWidth: 6, thickness: 4,
            minimizedIconOpacity: 0.5, animationDuration: 0.15,
            groupedSegmented: false
        )
        let standardHover = HoverStyle(cornerRadius: 4, inset: 2, fillOpacity: 0.08, animationDuration: 0.15)
        let trayStandard = TrayStyle(iconSize: 16, clockUsesLocale: true, clockStacked: false, batteryAmberBelow: 20, batteryRedBelow: 10)
        let glassSurface = SegmentSurface.adaptive(light: "glassLight", dark: "glassDark")
        let solidSurface = SegmentSurface.solid(colorToken: "barSurface")
        
        var generatedThemes = [TaskbarTheme]()
        
        let presets = ["fullWidth", "compact", "split"]
        let edgeStyles = ["rounded", "sharp"]
        
        for preset in presets {
            for edgeStyle in edgeStyles {
                let id = "\\(preset)_\\(edgeStyle)"
                let isRounded = (edgeStyle == "rounded")
                let shape: BarShape = (preset == "fullWidth" && !isRounded) ? .fullWidth : .floating
                
                let screenInsets = isRounded 
                    ? EdgeInsets(top: 0, left: 16, bottom: 8, right: 16) 
                    : .zero
                    
                let cornerRadius = CornerRadius(all: isRounded ? 22 : 0)
                
                var zones: [Zone] = []
                
                switch preset {
                case "split":
                    zones = [
                        Zone(id: "left", anchor: .leadingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "left_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents(minWidth: nil), slots: [.leading])
                        ]),
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "task_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 16, bottom: 0, right: 16), sizing: .hugContents(minWidth: 420), slots: [.startButton, .taskArea])
                        ]),
                        Zone(id: "right", anchor: .trailingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "tray_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents(minWidth: nil), slots: [.tray])
                        ])
                    ]
                case "compact":
                    zones = [
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "unified", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents(minWidth: 420), slots: [.startButton, .leading, .taskArea, .tray])
                        ])
                    ]
                case "fullWidth":
                    zones = [
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "unified", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .fill, slots: [.startButton, .leading, .taskArea, .tray])
                        ])
                    ]
                default: break
                }
                
                generatedThemes.append(TaskbarTheme(
                    id: id,
                    displayName: "\\(preset.capitalized) (\\(edgeStyle.capitalized))",
                    geometry: BarGeometry(shape: shape, height: 44, screenInsets: screenInsets),
                    zones: zones,
                    icons: compactIcons,
                    indicator: dotsIndicator,
                    hover: standardHover,
                    tray: trayStandard
                ))
            }
        }
        
        themes = Dictionary(uniqueKeysWithValues: generatedThemes.map { ($0.id, $0) })
    }

    public func theme(for id: String) -> TaskbarTheme? { themes[id] }
"""

content.replaceSubrange(initStartRange.lowerBound..<initEndRange.upperBound, with: newInit)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
