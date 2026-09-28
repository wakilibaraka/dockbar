import Foundation

let path = "Sources/DockBarCore/ThemeRegistry.swift"
var content = try! String(contentsOfFile: path)

let oldSwitch = """
                switch preset {
                case "split":
                    zones = [
                        Zone(id: "left", anchor: .leadingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "left_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: [.leading])
                        ]),
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "task_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 16, bottom: 0, right: 16), sizing: .hugContents, minWidth: 420, slots: [.startButton, .taskArea])
                        ]),
                        Zone(id: "right", anchor: .trailingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "tray_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: [.tray])
                        ])
                    ]
                case "compact":
                    zones = [
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "unified", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: 420, slots: [.startButton, .leading, .taskArea, .tray])
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
"""

let newSwitch = """
                let leadingSlots: [SlotKind] = [.leading, .liveEvents]
                let centerSlots: [SlotKind] = [.startButton, .taskView, .search, .widgetsBoard, .taskArea, .downloads]
                let trailingSlots: [SlotKind] = [.tray]

                switch preset {
                case "split":
                    zones = [
                        Zone(id: "left", anchor: .leadingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "left_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: leadingSlots)
                        ]),
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "task_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 16, bottom: 0, right: 16), sizing: .hugContents, minWidth: 420, slots: centerSlots)
                        ]),
                        Zone(id: "right", anchor: .trailingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "tray_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: trailingSlots)
                        ])
                    ]
                case "compact":
                    zones = [
                        Zone(id: "left", anchor: .leadingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "left_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: leadingSlots)
                        ]),
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "task_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 16, bottom: 0, right: 16), sizing: .hugContents, minWidth: 420, slots: centerSlots)
                        ]),
                        Zone(id: "right", anchor: .trailingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "tray_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: trailingSlots)
                        ])
                    ]
                case "fullWidth":
                    zones = [
                        Zone(id: "left", anchor: .leadingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "left_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: leadingSlots)
                        ]),
                        Zone(id: "center", anchor: .center, interSegmentGap: 0, segments: [
                            Segment(id: "task_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 16, bottom: 0, right: 16), sizing: .fill, minWidth: nil, slots: centerSlots)
                        ]),
                        Zone(id: "right", anchor: .trailingEdge, interSegmentGap: 0, segments: [
                            Segment(id: "tray_seg", surface: isRounded ? glassSurface : solidSurface, border: .default, cornerRadius: cornerRadius, contentInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12), sizing: .hugContents, minWidth: nil, slots: trailingSlots)
                        ])
                    ]
                default: break
                }
"""
content = content.replacingOccurrences(of: oldSwitch, with: newSwitch)

let oldShape = """
                let isRounded = (edgeStyle == "rounded")
                let shape: BarShape = (preset == "fullWidth" && !isRounded) ? .fullWidth : .floating
"""
let newShape = """
                let isRounded = (edgeStyle == "rounded")
                let shape: BarShape
                if preset == "compact" { shape = .compact }
                else if preset == "fullWidth" && !isRounded { shape = .fullWidth }
                else { shape = .floating }
"""
content = content.replacingOccurrences(of: oldShape, with: newShape)

// Also fix indicator!
let oldInd = """
        let dotsIndicator = IndicatorStyle(
            kind: .dots,
            unfocusedWidth: 4, focusedWidth: 6, thickness: 4,
            groupedSegmented: false, colorToken: "indicator",
            minimizedIconOpacity: 0.5, animationDuration: 0.15
        )
"""
let newInd = """
        let win11Indicator = IndicatorStyle(
            kind: .win11Line,
            unfocusedWidth: 16, focusedWidth: 24, thickness: 3,
            groupedSegmented: true, colorToken: "indicator",
            minimizedIconOpacity: 0.5, animationDuration: 0.15
        )
"""
content = content.replacingOccurrences(of: oldInd, with: newInd)
content = content.replacingOccurrences(of: "indicator: dotsIndicator,", with: "indicator: win11Indicator,")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
