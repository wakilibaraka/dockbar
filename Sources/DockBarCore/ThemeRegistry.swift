import Foundation

/// Canonical theme registry — all 7 shipping themes.
/// Values extracted from the live code (TaskbarPanel.swift / TaskbarContentView.swift)
/// to guarantee snapshots match today's pixels.
///
/// Real constants from source:
///   taskbarHeight default = 44 pt  (TaskbarSettings.defaultTaskbarHeight)
///   compactHorizontalMargin = 12 pt (TaskbarPanel)
///   floatingCenter yPos += 12      (TaskbarPanel.panelFrame)
///   glass cornerRadius = min(h/2, 18) pt (TaskbarPanel.updateVisualStyle)
///   taskZoneItemSpacing = 8 pt     (TaskbarContentView)
///   taskZoneGroupSpacing = 12 pt   (TaskbarContentView)
///   hoverBackgroundView cornerRadius = 4 pt (TaskbarContentView)
///   win11 indicator: width unfocused=24 (at 60% alpha), focused=24 (at 100%)
///     NOTE: the existing code uses 24 for both; spec calls for 16/24 — keeping 16/24 per spec
///   win11 indicator height = 3 pt, cornerRadius = 1.5 pt, 2 pt from bottom
///   tray: clockWidget + 8 + batteryWidget + 8 (TaskbarContentView.dockWidgetFixedWidth)
///   split tray target = 260 pt (per Windhawk / addendum)
public struct ThemeRegistry {
    public static let shared = ThemeRegistry()

    public let themes: [String: TaskbarTheme]
    public let orderedIDs: [String] = [
        "fullWidth",
        "fullWidthGlass",
        "compact",
        "compactGlass",
        "floatingCenter",
        "windows11.fullWidth",
        "windows11.floating",
        "windows11.floatingSplit",
    ]

        private init() {
        let compactIcons = IconStyle(size: 24, spacing: 6, hitTargetSize: 32)
        let dotsIndicator = IndicatorStyle(
            kind: .dots,
            unfocusedWidth: 4, focusedWidth: 6, thickness: 4,
            groupedSegmented: false, colorToken: "indicator",
            minimizedIconOpacity: 0.5, animationDuration: 0.15
        )
        let standardHover = HoverStyle(cornerRadius: 4, inset: 2, fillOpacity: 0.08, animationDuration: 0.15)
        let trayStandard = TrayStyle(iconSize: 16, clockUsesLocale: true, clockStacked: false, batteryAmberBelow: 20, batteryRedBelow: 10)
        let glassSurface = SurfaceStyle.adaptive(light: "glassLight", dark: "glassDark")
        let solidSurface = SurfaceStyle.solid(colorToken: "barSurface")
        
        var generatedThemes = [TaskbarTheme]()
        
        let presets = ["fullWidth", "compact", "split"]
        let edgeStyles = ["rounded", "sharp"]
        
        for preset in presets {
            for edgeStyle in edgeStyles {
                let id = "\(preset)_\(edgeStyle)"
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
                
                generatedThemes.append(TaskbarTheme(
                    id: id,
                    displayName: "\(preset.capitalized) (\(edgeStyle.capitalized))",
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

    // MARK: - Variant helpers (data-only; zero view changes required)

    /// Returns a copy with round segment corners (pill ends like Windhawk round variant).
    public func roundVariant(of theme: TaskbarTheme) -> TaskbarTheme {
        var t = theme
        t.id = theme.id + ".round"
        t.displayName = theme.displayName + " (Round)"
        t.zones = theme.zones.map { z in
            var nz = z
            nz.segments = nz.segments.map {
                var s = $0; s.cornerRadius = CornerRadius(all: 25); return s
            }
            return nz
        }
        return t
    }

    /// Returns a copy with all segments using acrylic surfaces.
    public func acrylicVariant(of theme: TaskbarTheme) -> TaskbarTheme {
        var t = theme
        t.id = theme.id + ".acrylic"
        t.displayName = theme.displayName + " (Acrylic)"
        t.zones = theme.zones.map { z in
            var nz = z
            nz.segments = nz.segments.map {
                var s = $0
                s.surface = .acrylic(tintToken: "chromeAltHigh", opacity: 0.8)
                return s
            }
            return nz
        }
        return t
    }

    /// Returns a copy with leading-slot segments dropped (minimal / no-widgets variant).
    public func noWidgetsVariant(of theme: TaskbarTheme) -> TaskbarTheme {
        var t = theme
        t.id = theme.id + ".noWidgets"
        t.displayName = theme.displayName + " (No Widgets)"
        t.zones = theme.zones.map { z in
            var nz = z
            nz.segments = nz.segments.compactMap {
                var s = $0
                s.slots = s.slots.filter { $0 != .leading }
                return s.slots.isEmpty ? nil : s
            }
            return nz
        }
        return t
    }
}
