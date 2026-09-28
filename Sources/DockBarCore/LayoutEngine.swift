import Foundation
import CoreGraphics

// MARK: - Layout Engine

/// A stateless resolver: takes frozen inputs, returns exact frames. No AppKit.
/// This is the only place positioning math lives.
public struct LayoutEngine {

    // MARK: - Input

    public struct AppItem: Equatable {
        public var id: String
        public var isRunning: Bool
        public var isFocused: Bool
        public var hasMultipleWindows: Bool
        public var isMinimized: Bool

        public init(id: String, isRunning: Bool, isFocused: Bool, hasMultipleWindows: Bool, isMinimized: Bool) {
            self.id = id; self.isRunning = isRunning; self.isFocused = isFocused
            self.hasMultipleWindows = hasMultipleWindows; self.isMinimized = isMinimized
        }
    }

    public struct Input {
        public var theme: TaskbarTheme
        /// Full bounds of the screen (origin may be non-zero for secondary monitors).
        public var screenFrame: CGRect
        /// The usable area of the screen (excludes menu bar on top — not used for bar placement
        /// since we pin to the bottom, but needed for overflow guards).
        public var visibleFrame: CGRect
        /// Ordered list of app/window groups left → right.
        public var apps: [AppItem]
        public var activeAppID: String?
        /// Measured widths of active widgets, keyed by SlotKind.
        /// The engine does not measure widgets itself — the caller injects sizes.
        public struct WidgetRequest: Equatable {
            public var id: String
            public var slot: SlotKind
            public var rule: WidgetLocation
            public var size: CGSize
            public init(id: String, slot: SlotKind, rule: WidgetLocation, size: CGSize) {
                self.id = id; self.slot = slot; self.rule = rule; self.size = size
            }
        }
        public var widgetRequests: [Input.WidgetRequest]
        public var isDockHidden: Bool
        public var isFullScreen: Bool
        public var appAlignment: String

        public init(
            theme: TaskbarTheme, screenFrame: CGRect, visibleFrame: CGRect,
            apps: [AppItem], activeAppID: String?,
            widgetRequests: [Input.WidgetRequest], isDockHidden: Bool, isFullScreen: Bool, appAlignment: String = "centered"
        ) {
            self.theme = theme; self.screenFrame = screenFrame; self.visibleFrame = visibleFrame
            self.apps = apps; self.activeAppID = activeAppID
            self.widgetRequests = widgetRequests; self.isDockHidden = isDockHidden; self.isFullScreen = isFullScreen
            self.appAlignment = appAlignment
        }
    }

    // MARK: - Output

    public struct ResolvedLayout: Equatable {
        /// The panel's frame in screen coordinates.
        public var panelFrame: CGRect
        /// Each segment's rect in panel-local coordinates.
        public var segmentFrames: [String: CGRect]    // segment.id → frame
        /// Task button frames, panel-local.
        public var taskButtonFrames: [String: CGRect] // app.id → frame
        public var indicatorStates: [String: IndicatorState]
        /// Hover rect per app (panel-local, already inset per HoverStyle).
        public var hoverRects: [String: CGRect]
        /// Widget frames, panel-local.
        public var widgetFrames: [String: CGRect]
        public var menuBarWidgets: [String]
        public var geometryInsets: EdgeInsets
        /// Whether any overflow occurred (more icons than available width).
        public var hasTaskOverflow: Bool

        public init(
            panelFrame: CGRect, segmentFrames: [String: CGRect],
            taskButtonFrames: [String: CGRect], indicatorStates: [String: IndicatorState],
            hoverRects: [String: CGRect], widgetFrames: [String: CGRect],
            menuBarWidgets: [String], geometryInsets: EdgeInsets,
            hasTaskOverflow: Bool
        ) {
            self.panelFrame = panelFrame; self.segmentFrames = segmentFrames
            self.taskButtonFrames = taskButtonFrames; self.indicatorStates = indicatorStates
            self.hoverRects = hoverRects; self.widgetFrames = widgetFrames
            self.menuBarWidgets = menuBarWidgets; self.geometryInsets = geometryInsets
            self.hasTaskOverflow = hasTaskOverflow
        }
    }

    public enum IndicatorState: Equatable {
        case none
        case unfocused
        case focused
        case groupedFocused
    }

    // MARK: - Resolution


    public static func resolve(input: Input) -> ResolvedLayout {
        var placedInDock = input.widgetRequests.filter { $0.rule == .dock }
        var placedInMenuBar = input.widgetRequests.filter { $0.rule == .menuBar }.map(\.id)
        let auto = input.widgetRequests.filter { $0.rule == .auto }
        
        let canUseDock = !input.isDockHidden && !input.isFullScreen
        if canUseDock {
            placedInDock.append(contentsOf: auto)
        } else {
            placedInMenuBar.append(contentsOf: auto.map(\.id))
        }
        
        let g = input.theme.geometry
        
        // Return type of layout pass
        struct ZoneLayoutInfo {
            let id: String
            let anchor: ZoneAnchor
            let measuredWidths: [Int: CGFloat]
            let sizesBySlot: [SlotKind: [Input.WidgetRequest]]
            let naturalWidth: CGFloat
            let segments: [Segment]
            let hasTaskOverflow: Bool
        }
        
        func measureZone(zone: Zone, dockWidgets: [Input.WidgetRequest]) -> ZoneLayoutInfo {
            var sizesBySlot: [SlotKind: [Input.WidgetRequest]] = [:]
            for w in dockWidgets { sizesBySlot[w.slot, default: []].append(w) }
            
            var measuredWidths: [Int: CGFloat] = [:]
            var fixedAndHugTotal: CGFloat = 0
            
            for (idx, seg) in zone.segments.enumerated() {
                switch seg.sizing {
                case .fixed(let w):
                    measuredWidths[idx] = w
                    fixedAndHugTotal += w
                case .hugContents:
                    var w = huggingWidth(segment: seg, taskContentWidth: taskAreaWidth(apps: input.apps, icons: input.theme.icons), dockWidgets: sizesBySlot, icons: input.theme.icons)
                    if let mw = seg.minWidth { w = max(w, mw) }
                    measuredWidths[idx] = w
                    fixedAndHugTotal += w
                case .fill:
                    break // handled later
                }
            }
            
            let gapTotal = CGFloat(max(0, zone.segments.count - 1)) * zone.interSegmentGap
            // Assume fill takes remaining available width from screen
            let availableWidth = input.visibleFrame.width - g.screenInsets.left - g.screenInsets.right
            let fillRemainder = max(0, availableWidth - fixedAndHugTotal - gapTotal)
            let fillCount = zone.segments.filter { $0.sizing == .fill }.count
            let fillWidth = fillCount > 0 ? fillRemainder / CGFloat(fillCount) : 0
            
            for (idx, seg) in zone.segments.enumerated() {
                if case .fill = seg.sizing { measuredWidths[idx] = fillWidth }
            }
            
            let naturalWidth = measuredWidths.values.reduce(0, +) + gapTotal
            
            var hasTaskOverflow = false
            if let taskSegIdx = zone.segments.firstIndex(where: { $0.slots.contains(.taskArea) }) {
                let segW = measuredWidths[taskSegIdx] ?? 0
                let seg = zone.segments[taskSegIdx]
                let requiredW = huggingWidth(segment: seg, taskContentWidth: taskAreaWidth(apps: input.apps, icons: input.theme.icons), dockWidgets: sizesBySlot, icons: input.theme.icons)
                if requiredW > segW {
                    hasTaskOverflow = true
                }
            }
            
            return ZoneLayoutInfo(id: zone.id, anchor: zone.anchor, measuredWidths: measuredWidths, sizesBySlot: sizesBySlot, naturalWidth: naturalWidth, segments: zone.segments, hasTaskOverflow: hasTaskOverflow)
        }
        
        var zonesLayout = input.theme.zones.map { measureZone(zone: $0, dockWidgets: placedInDock) }
        let hasAnyOverflow = zonesLayout.contains { $0.hasTaskOverflow }
        
        // ── 1. Re-evaluate auto rules for overflow ──────────────────────────────
        if hasAnyOverflow {
            let originalDock = placedInDock
            placedInDock = []
            for req in originalDock {
                if req.rule == .auto {
                    placedInMenuBar.append(req.id)
                } else {
                    placedInDock.append(req)
                }
            }
            zonesLayout = input.theme.zones.map { measureZone(zone: $0, dockWidgets: placedInDock) }
        }
        
        // ── 2. Zone Collision & Width Allocation ──────────────────────────────
        let screen = input.screenFrame
        let availableXMin = screen.minX + g.screenInsets.left
        let availableXMax = screen.maxX - g.screenInsets.right
        
        // Identify zones
        let leftZones = zonesLayout.filter { $0.anchor == .leadingEdge }
        let rightZones = zonesLayout.filter { $0.anchor == .trailingEdge }
        var centerZones = zonesLayout.filter { $0.anchor == .center }
        
        // We assume max 1 zone per anchor for simplicity, but handle gracefully.
        let leftWidth = leftZones.reduce(0) { $0 + $1.naturalWidth }
        let rightWidth = rightZones.reduce(0) { $0 + $1.naturalWidth }
        
        let leftMaxX = availableXMin + leftWidth
        let rightMinX = availableXMax - rightWidth
        
        var zoneFrames: [String: CGRect] = [:]
        
        if g.shape == .compact {
            let centerZoneW = centerZones.first?.naturalWidth ?? 0
            let totalW = leftWidth + centerZoneW + rightWidth
            let gap: CGFloat = 8 // small gap between zones in compact mode
            let totalWithGaps = totalW + (leftZones.isEmpty ? 0 : gap) + (rightZones.isEmpty ? 0 : gap)
            
            var startX = screen.minX + floor((screen.width - totalWithGaps) / 2)
            
            for zl in leftZones {
                zoneFrames[zl.id] = CGRect(x: startX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
                startX += zl.naturalWidth + gap
            }
            if let centerZone = centerZones.first {
                zoneFrames[centerZone.id] = CGRect(x: startX, y: screen.minY + g.screenInsets.bottom, width: centerZone.naturalWidth, height: g.height)
                startX += centerZone.naturalWidth + gap
            }
            for zl in rightZones {
                zoneFrames[zl.id] = CGRect(x: startX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
                startX += zl.naturalWidth + gap
            }
        } else {
            // Place Left & Right firmly (they don't compress per requirements)
            var curX = availableXMin
            for zl in leftZones {
                zoneFrames[zl.id] = CGRect(x: curX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
                curX += zl.naturalWidth
            }
            
            var rCurX = availableXMax
            for zl in rightZones.reversed() {
                rCurX -= zl.naturalWidth
                zoneFrames[zl.id] = CGRect(x: rCurX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
            }
            
            // Center compresses if needed
            if let centerZone = centerZones.first {
                let naturalW = centerZone.naturalWidth
                let preferredMinX = screen.minX + floor((screen.width - naturalW) / 2)
                let preferredMaxX = preferredMinX + naturalW
            
            var constrainedMinX = preferredMinX
            var constrainedMaxX = preferredMaxX
            
            // If it collides with left
            if constrainedMinX < leftMaxX {
                constrainedMinX = leftMaxX
                constrainedMaxX = constrainedMinX + naturalW
            }
            // If it collides with right
            if constrainedMaxX > rightMinX {
                constrainedMaxX = rightMinX
                constrainedMinX = max(leftMaxX, constrainedMaxX - naturalW)
            }
            
            let finalWidth = constrainedMaxX - constrainedMinX
            // If we actually compressed, we need to re-measure this zone with the constrained width.
            // But LayoutEngine needs to compress the task area specifically!
            // We'll adjust the `measuredWidths` for the task segment of the center zone.
            var adjustedWidths = centerZone.measuredWidths
            if finalWidth < naturalW {
                if let taskSegIdx = centerZone.segments.firstIndex(where: { $0.slots.contains(.taskArea) }) {
                    let oldW = adjustedWidths[taskSegIdx] ?? 0
                    let difference = naturalW - finalWidth
                    adjustedWidths[taskSegIdx] = max(0, oldW - difference)
                }
            }
            
            zoneFrames[centerZone.id] = CGRect(x: constrainedMinX, y: screen.minY + g.screenInsets.bottom, width: finalWidth, height: g.height)
            
            // Replace the center zone info with adjusted widths
            let newCenterZone = ZoneLayoutInfo(id: centerZone.id, anchor: centerZone.anchor, measuredWidths: adjustedWidths, sizesBySlot: centerZone.sizesBySlot, naturalWidth: finalWidth, segments: centerZone.segments, hasTaskOverflow: centerZone.hasTaskOverflow || finalWidth < naturalW)
            centerZones[0] = newCenterZone
            
            // Re-update zonesLayout to reflect adjusted widths
            if let idx = zonesLayout.firstIndex(where: { $0.id == centerZone.id }) {
                zonesLayout[idx] = newCenterZone
            }
        }
        } // close else block
        
        let panelFrame = CGRect(
            x: screen.minX,
            y: screen.minY + g.screenInsets.bottom,
            width: screen.width,
            height: g.height
        )
        
        // ── 3. Final positioning (PANEL-LOCAL coordinates) ─────────────────────
        // All frames must be in panel-local space so ThemeContainerView
        // (which fills the full-width, full-height panel) can apply them directly.
        // Zone frames are currently screen-absolute; we subtract panelFrame.origin.x
        // to convert. Y is already 0-based (panel bottom == 0 in its own space).
        let panelOriginX = panelFrame.origin.x
        var segmentFrames: [String: CGRect] = [:]
        var taskButtonFrames: [String: CGRect] = [:]
        var indicatorStates: [String: IndicatorState] = [:]
        var hoverRects: [String: CGRect] = [:]
        var widgetFrames: [String: CGRect] = [:]
        
        for zl in zonesLayout {
            guard let zFrame = zoneFrames[zl.id] else { continue }
            
            // Convert zone's screen-absolute minX to panel-local.
            var currentX: CGFloat = zFrame.minX - panelOriginX
            for (idx, seg) in zl.segments.enumerated() {
                let w = zl.measuredWidths[idx] ?? 0
                // segFrame is panel-local: x starts at currentX (panel-relative), y=0
                let segFrame = CGRect(x: currentX, y: 0, width: w, height: g.height)
                segmentFrames[seg.id] = segFrame
                currentX += w + (idx < zl.segments.count - 1 ? input.theme.zones.first(where: {$0.id == zl.id})?.interSegmentGap ?? 0 : 0)
                
                var slotX = seg.contentInsets.left
                for slot in seg.slots {
                    if slot == .taskArea {
                        let btnW = input.theme.icons.hitTargetSize
                        let areaWidth = taskAreaWidth(apps: input.apps, icons: input.theme.icons)
                        
                        var alignOffset: CGFloat = 0
                        if input.appAlignment == "centered" && (seg.sizing == .fill || seg.minWidth != nil) {
                            // If we have extra space in this segment, center the task area
                            // Calculate total width of all slots in this segment
                            var allSlotsW: CGFloat = 0
                            for s in seg.slots {
                                if s == .taskArea { allSlotsW += areaWidth }
                                else if let ws = zl.sizesBySlot[s] {
                                    for w in ws { allSlotsW += w.size.width + input.theme.icons.spacing }
                                }
                            }
                            let extraSpace = segFrame.width - seg.contentInsets.left - seg.contentInsets.right - allSlotsW
                            if extraSpace > 0 { alignOffset = extraSpace / 2.0 }
                        }
                        
                        slotX += alignOffset
                        
                        for app in input.apps {
                            if slotX + btnW > segFrame.width - seg.contentInsets.right + alignOffset { break } // allow overflowing visually if centered
                            
                            let bFrame = CGRect(x: segFrame.minX + slotX, y: (g.height - input.theme.icons.hitTargetSize)/2, width: btnW, height: input.theme.icons.hitTargetSize)
                            taskButtonFrames[app.id] = bFrame
                            
                            let state: IndicatorState
                            if !app.isRunning { state = .none }
                            else if app.hasMultipleWindows { state = (app.id == input.activeAppID || app.isFocused) ? .groupedFocused : .unfocused }
                            else { state = (app.id == input.activeAppID || app.isFocused) ? .focused : .unfocused }
                            indicatorStates[app.id] = state
                            
                            let inset = input.theme.hover.inset
                            hoverRects[app.id] = bFrame.insetBy(dx: inset, dy: inset)
                            
                            slotX += btnW + input.theme.icons.spacing
                        }
                    } else if let widgetsInSlot = zl.sizesBySlot[slot] {
                        for wReq in widgetsInSlot {
                            // wFrame panel-local: segFrame.minX is already panel-local
                            let wFrame = CGRect(x: segFrame.minX + slotX, y: 0, width: wReq.size.width, height: g.height)
                            widgetFrames[wReq.id] = wFrame
                            slotX += wReq.size.width + input.theme.icons.spacing
                        }
                    }
                }
            }
        }
        
        // Invariant: every taskButtonFrame and widgetFrame must fall inside
        // the panel bounds [0, panelFrame.width). Assert in debug builds.
        assert(taskButtonFrames.values.allSatisfy { $0.minX >= -0.5 && $0.maxX <= panelFrame.width + 0.5 },
               "taskButtonFrame out of panel bounds")
        assert(widgetFrames.values.allSatisfy { $0.minX >= -0.5 && $0.maxX <= panelFrame.width + 0.5 },
               "widgetFrame out of panel bounds")
        
        return ResolvedLayout(
            panelFrame: panelFrame,
            segmentFrames: segmentFrames,
            taskButtonFrames: taskButtonFrames,
            indicatorStates: indicatorStates,
            hoverRects: hoverRects,
            widgetFrames: widgetFrames,
            menuBarWidgets: placedInMenuBar,
            geometryInsets: g.screenInsets,
            hasTaskOverflow: zonesLayout.contains { $0.hasTaskOverflow }
        )
    }

// MARK: - Private Helpers

    private static func taskAreaWidth(apps: [AppItem], icons: IconStyle) -> CGFloat {
        guard !apps.isEmpty else { return 0 }
        return CGFloat(apps.count) * icons.hitTargetSize +
               CGFloat(apps.count - 1) * icons.spacing
    }

    private static func huggingWidth(
        segment: Segment,
        taskContentWidth: CGFloat,
        dockWidgets: [SlotKind: [Input.WidgetRequest]],
        icons: IconStyle
    ) -> CGFloat {
        let insets = segment.contentInsets
        var w: CGFloat = insets.left + insets.right
        for slot in segment.slots {
            switch slot {
            case .taskArea:
                w += taskContentWidth
            default:
                if let widgets = dockWidgets[slot] { for wx in widgets { w += wx.size.width + icons.spacing } }
            }
        }
        return max(0, w)
    }

    private static func indicatorState(for app: AppItem, activeID: String?) -> IndicatorState {
        guard app.isRunning else { return .none }
        let isFocused = app.id == activeID || app.isFocused
        if isFocused {
            return app.hasMultipleWindows ? .groupedFocused : .focused
        }
        return .unfocused
    }
}

    // MARK: - App List Builder
    
    public struct WindowData {
        public let bundleIdentifier: String
        public let isMinimized: Bool
        public init(bundleIdentifier: String, isMinimized: Bool) {
            self.bundleIdentifier = bundleIdentifier
            self.isMinimized = isMinimized
        }
    }
    
extension LayoutEngine {
    public static func buildAppItems(
        visibleWindows: [WindowData],
        pinnedApps: [String],
        unpinnedOrder: inout [String],
        frontmostApp: String?,
        runningApps: Set<String>
    ) -> [AppItem] {
        var groups: [String: [WindowData]] = [:]
        for w in visibleWindows {
            groups[w.bundleIdentifier, default: []].append(w)
        }
        
        var apps: [AppItem] = []
        
        // 1. Pinned apps
        for pinned in pinnedApps {
            let windows = groups[pinned] ?? []
            let isRunning = !windows.isEmpty || runningApps.contains(pinned)
            
            apps.append(AppItem(
                id: pinned,
                isRunning: isRunning,
                isFocused: pinned == frontmostApp,
                hasMultipleWindows: windows.count > 1,
                isMinimized: isRunning && !windows.isEmpty && windows.allSatisfy { $0.isMinimized }
            ))
            
            groups.removeValue(forKey: pinned)
        }
        
        // 2. Running-unpinned in stable order
        var newUnpinned: [String] = []
        for id in unpinnedOrder {
            if let windows = groups[id] {
                apps.append(AppItem(
                    id: id,
                    isRunning: true,
                    isFocused: id == frontmostApp,
                    hasMultipleWindows: windows.count > 1,
                    isMinimized: windows.allSatisfy { $0.isMinimized }
                ))
                newUnpinned.append(id)
                groups.removeValue(forKey: id)
            }
        }
        
        // Any new unpinned apps
        let sortedNewUnpinned = groups.keys.sorted()
        for id in sortedNewUnpinned {
            if let windows = groups[id] {
                apps.append(AppItem(
                    id: id,
                    isRunning: true,
                    isFocused: id == frontmostApp,
                    hasMultipleWindows: windows.count > 1,
                    isMinimized: windows.allSatisfy { $0.isMinimized }
                ))
                newUnpinned.append(id)
            }
        }
        unpinnedOrder = newUnpinned
        
        return apps
    }
}