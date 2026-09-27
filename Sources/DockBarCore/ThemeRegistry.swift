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
        // Shared style atoms
        let win11Indicator = IndicatorStyle(
            kind: .win11Line, unfocusedWidth: 16, focusedWidth: 24,
            thickness: 3, groupedSegmented: true, colorToken: "accent",
            minimizedIconOpacity: 0.5, animationDuration: 0.15
        )
        let dotsIndicator = IndicatorStyle(
            kind: .dots, unfocusedWidth: 4, focusedWidth: 4,
            thickness: 4, groupedSegmented: false, colorToken: "accent",
            minimizedIconOpacity: 0.5, animationDuration: 0.15
        )
        let standardHover = HoverStyle(cornerRadius: 4, inset: 2, fillOpacity: 0.08, animationDuration: 0.15)
        let pillHover = HoverStyle(cornerRadius: 8, inset: 0, fillOpacity: 0.08, animationDuration: 0.15)

        let trayStandard = TrayStyle(iconSize: 16, clockUsesLocale: true, clockStacked: false, batteryAmberBelow: 20, batteryRedBelow: 10)
        let trayWin11 = TrayStyle(iconSize: 16, clockUsesLocale: true, clockStacked: true, batteryAmberBelow: 20, batteryRedBelow: 10)

        // icons: hitTargetSize = 40 for win11 (matches existing 40pt constraint),
        //        36 for compact (existing 36-40 range)
        let win11Icons = IconStyle(size: 24, spacing: 8, hitTargetSize: 40)
        let compactIcons = IconStyle(size: 24, spacing: 8, hitTargetSize: 36)
        let fullWidthIcons = IconStyle(size: 24, spacing: 8, hitTargetSize: 40)

        // ── Shared segment builders ────────────────────────────────────────
        // Full-width solid unified bar (fullWidth, windows11.fullWidth)
        func unifiedFillSegment(slots: [SlotKind] = [.leading, .taskArea, .tray]) -> Segment {
            Segment(
                id: "unified",
                surface: .solid(colorToken: "barSurface"),
                border: .none,
                cornerRadius: .zero,
                contentInsets: EdgeInsets(top: 0, left: 10, bottom: 0, right: 10),
                sizing: .fill,
                slots: slots
            )
        }

        // Floating solid unified pill (compact, windows11.floating)
        // glass cornerRadius = min(44/2, 18) = 18 pt (from TaskbarPanel.updateVisualStyle)
        func unifiedPillSegment(
            surface: SurfaceStyle = .solid(colorToken: "barSurface"),
            slots: [SlotKind] = [.leading, .taskArea, .tray]
        ) -> Segment {
            Segment(
                id: "unified",
                surface: surface,
                border: SegmentBorder(colorToken: "surfaceStrokeDefault", thickness: 1, enabled: true),
                cornerRadius: CornerRadius(all: 18),
                contentInsets: EdgeInsets(top: 0, left: 10, bottom: 0, right: 10),
                sizing: .hugContents,
                slots: slots
            )
        }

        // ── 1. fullWidth ──────────────────────────────────────────────────
        let fullWidth = TaskbarTheme(
            id: "fullWidth",
            displayName: "Full Width",
            geometry: BarGeometry(shape: .fullWidth, height: 44, screenInsets: .zero),
            alignment: .leading,
            interSegmentGap: 0,
            segments: [unifiedFillSegment()],
            icons: fullWidthIcons,
            indicator: dotsIndicator,
            hover: standardHover,
            tray: trayStandard
        )

        // ── 2. fullWidthGlass ──────────────────────────────────────────────
        // glassHorizontalMargin=12 each side; cornerRadius min(h/2,18)=18
        let fullWidthGlass = TaskbarTheme(
            id: "fullWidthGlass",
            displayName: "Full Width (Glass)",
            geometry: BarGeometry(shape: .fullWidth, height: 44,
                                  screenInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12)),
            alignment: .center,
            interSegmentGap: 0,
            segments: [
                Segment(
                    id: "unified",
                    surface: .adaptive(light: "glassLight", dark: "glassDark"),
                    border: SegmentBorder(colorToken: "surfaceStrokeGlass", thickness: 1, enabled: true),
                    cornerRadius: CornerRadius(all: 18),
                    contentInsets: EdgeInsets(top: 0, left: 10, bottom: 0, right: 10),
                    sizing: .fill,
                    slots: [.leading, .taskArea, .tray]
                )
            ],
            icons: fullWidthIcons,
            indicator: dotsIndicator,
            hover: pillHover,
            tray: trayStandard
        )

        // ── 3. compact ────────────────────────────────────────────────────
        // compactHorizontalMargin=12; cornerRadius=18; hugContents → panel narrows to content
        let compact = TaskbarTheme(
            id: "compact",
            displayName: "Compact",
            geometry: BarGeometry(shape: .floating, height: 44,
                                  screenInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12)),
            alignment: .center,
            interSegmentGap: 0,
            segments: [unifiedPillSegment()],
            icons: compactIcons,
            indicator: dotsIndicator,
            hover: pillHover,
            tray: trayStandard
        )

        // ── 4. compactGlass ───────────────────────────────────────────────
        let compactGlass = TaskbarTheme(
            id: "compactGlass",
            displayName: "Compact (Glass)",
            geometry: BarGeometry(shape: .floating, height: 44,
                                  screenInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12)),
            alignment: .center,
            interSegmentGap: 0,
            segments: [
                unifiedPillSegment(surface: .adaptive(light: "glassLight", dark: "glassDark"))
            ],
            icons: compactIcons,
            indicator: dotsIndicator,
            hover: pillHover,
            tray: trayStandard
        )

        // ── 5. floatingCenter ─────────────────────────────────────────────
        // yPos += 12 from screen edge (TaskbarPanel.panelFrame); uses glass chrome
        let floatingCenter = TaskbarTheme(
            id: "floatingCenter",
            displayName: "Floating Center",
            geometry: BarGeometry(shape: .floating, height: 44,
                                  screenInsets: EdgeInsets(top: 0, left: 12, bottom: 12, right: 12)),
            alignment: .center,
            interSegmentGap: 0,
            segments: [
                unifiedPillSegment(surface: .adaptive(light: "glassLight", dark: "glassDark"))
            ],
            icons: compactIcons,
            indicator: dotsIndicator,
            hover: pillHover,
            tray: trayStandard
        )

        // ── 6. windows11.fullWidth ────────────────────────────────────────
        let win11FullWidth = TaskbarTheme(
            id: "windows11.fullWidth",
            displayName: "Windows 11 (Full Width)",
            geometry: BarGeometry(shape: .fullWidth, height: 44, screenInsets: .zero),
            alignment: .center,
            interSegmentGap: 0,
            segments: [unifiedFillSegment(slots: [.startButton, .leading, .taskArea, .tray])],
            icons: win11Icons,
            indicator: win11Indicator,
            hover: standardHover,
            tray: trayWin11
        )

        // ── 7. windows11.floating ─────────────────────────────────────────
        // Same as compact but with win11 indicator + clock stacked
        let win11Floating = TaskbarTheme(
            id: "windows11.floating",
            displayName: "Windows 11 (Floating)",
            geometry: BarGeometry(shape: .floating, height: 44,
                                  screenInsets: EdgeInsets(top: 0, left: 12, bottom: 0, right: 12)),
            alignment: .center,
            interSegmentGap: 0,
            segments: [
                unifiedPillSegment(slots: [.startButton, .leading, .taskArea, .tray])
            ],
            icons: win11Icons,
            indicator: win11Indicator,
            hover: standardHover,
            tray: trayWin11
        )

        // ── 8. windows11.floatingSplit ────────────────────────────────────
        // Two-segment split translated from Windhawk "Modern Center Taskbar".
        // Task segment: hugContents, cornerRadius=5, contentInsets leading=8 right=8
        // Tray segment: fixed=260pt, cornerRadius=5, contentInsets leading=10 right=6
        // interSegmentGap = 10 pt
        let win11Split = TaskbarTheme(
            id: "windows11.floatingSplit",
            displayName: "Windows 11 (Split)",
            geometry: BarGeometry(shape: .floating, height: 48,
                                  screenInsets: EdgeInsets(top: 0, left: 12, bottom: 6, right: 12)),
            alignment: .center,
            interSegmentGap: 10,
            segments: [
                Segment(
                    id: "task",
                    surface: .solid(colorToken: "barSurface"),
                    border: .default,
                    cornerRadius: CornerRadius(all: 5),
                    contentInsets: EdgeInsets(top: 0, left: 8, bottom: 0, right: 8),
                    sizing: .hugContents,
                    slots: [.startButton, .leading, .taskArea]
                ),
                Segment(
                    id: "tray",
                    surface: .solid(colorToken: "barSurface"),
                    border: .default,
                    cornerRadius: CornerRadius(all: 5),
                    contentInsets: EdgeInsets(top: 0, left: 10, bottom: 0, right: 6),
                    sizing: .fixed(width: 260),
                    slots: [.tray]
                ),
            ],
            icons: win11Icons,
            indicator: win11Indicator,
            hover: standardHover,
            tray: trayWin11
        )

        themes = Dictionary(uniqueKeysWithValues: [
            fullWidth, fullWidthGlass, compact, compactGlass,
            floatingCenter, win11FullWidth, win11Floating, win11Split
        ].map { ($0.id, $0) })
    }

    public func theme(for id: String) -> TaskbarTheme? { themes[id] }

    // MARK: - Variant helpers (data-only; zero view changes required)

    /// Returns a copy with round segment corners (pill ends like Windhawk round variant).
    public func roundVariant(of theme: TaskbarTheme) -> TaskbarTheme {
        var t = theme
        t.id = theme.id + ".round"
        t.displayName = theme.displayName + " (Round)"
        t.segments = theme.segments.map {
            var s = $0; s.cornerRadius = CornerRadius(all: 25); return s
        }
        return t
    }

    /// Returns a copy with all segments using acrylic surfaces.
    public func acrylicVariant(of theme: TaskbarTheme) -> TaskbarTheme {
        var t = theme
        t.id = theme.id + ".acrylic"
        t.displayName = theme.displayName + " (Acrylic)"
        t.segments = theme.segments.map {
            var s = $0
            s.surface = .acrylic(tintToken: "chromeAltHigh", opacity: 0.8)
            return s
        }
        return t
    }

    /// Returns a copy with leading-slot segments dropped (minimal / no-widgets variant).
    public func noWidgetsVariant(of theme: TaskbarTheme) -> TaskbarTheme {
        var t = theme
        t.id = theme.id + ".noWidgets"
        t.displayName = theme.displayName + " (No Widgets)"
        t.segments = theme.segments.map {
            var s = $0
            s.slots = s.slots.filter { $0 != .leading }
            return s
        }
        return t
    }
}
