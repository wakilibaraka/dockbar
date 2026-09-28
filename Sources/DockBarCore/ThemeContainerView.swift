import AppKit
import Combine

/// The new thin container that consumes ResolvedLayout and positions dumb views.
/// Contains ZERO layout math — all math lives in LayoutEngine.
/// LINT: no `layoutMode ==` allowed in this file.
public final class ThemeContainerView: NSView {
    // MARK: - Configuration (injected, never computed here)
    private var theme: TaskbarTheme
    private var layout: LayoutEngine.ResolvedLayout?

    // MARK: - Child views (keyed so they can be reused across re-layouts)
    private var segmentViews: [String: SegmentView] = [:]
    private var taskButtonViews: [String: TaskButtonEngineView] = [:]
    private var widgetViews: [String: NSView] = [:]

    // MARK: - App icon cache (injected by caller)
    public var iconProvider: ((String) -> NSImage?)? // appID → icon

    // MARK: - Action callbacks (injected by the coordinator)
        public var onAppActivate: ((String) -> Void)? // appID → activate
    public var onAppRightClick: ((String) -> NSMenu?)? // appID → menu

    public init(theme: TaskbarTheme) {
        self.theme = theme
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public API

    /// Update the theme and re-render. Safe to call on every settings change.
    public func applyTheme(_ newTheme: TaskbarTheme) {
        self.theme = newTheme
    }

    /// Apply a freshly-resolved layout. Call this whenever apps/widgets/screen change.
    public func applyLayout(_ resolved: LayoutEngine.ResolvedLayout) {
        self.layout = resolved
        syncSegmentViews()
        syncTaskButtonViews()
        syncWidgetViews()
        

        
        // Invariant: no phantom slots allowed.
        for id in resolved.widgetFrames.keys {
            assert(widgetViews[id] != nil, "Phantom slot detected: Widget '\(id)' reserved a slot in LayoutEngine but has no corresponding view mounted in ThemeContainerView.")
        }
    }

    public func setWidgetView(_ view: NSView, for id: String) {
        if let existing = widgetViews[id] {
            existing.removeFromSuperview()
        }
        widgetViews[id] = view
        addSubview(view)
        syncWidgetViews()
    }
    
    private func syncWidgetViews() {
        guard let layout else { return }
        for (id, view) in widgetViews {
            if let frame = layout.widgetFrames[id] {
                view.frame = frame
                view.isHidden = false
            } else {
                view.isHidden = true
            }
        }
    }

    // MARK: - Segment sync

    private func syncSegmentViews() {
        guard let layout else { return }

        var liveIDs = Set<String>()
        for segment in theme.zones.flatMap({ $0.segments }) {
            liveIDs.insert(segment.id)
            guard let frame = layout.segmentFrames[segment.id] else { continue }

            let sv: SegmentView
            if let existing = segmentViews[segment.id] {
                sv = existing
                sv.updateSegment(segment)
            } else {
                sv = SegmentView(segment: segment)
                // Insert segments at the bottom (z-index 0) so they don't cover widgets/buttons
                addSubview(sv, positioned: .below, relativeTo: nil)
                segmentViews[segment.id] = sv
            }
            sv.frame = frame
        }

        // Remove stale segments
        for id in segmentViews.keys where !liveIDs.contains(id) {
            segmentViews[id]?.removeFromSuperview()
            segmentViews.removeValue(forKey: id)
        }
    }

    // MARK: - Task button sync

    private func syncTaskButtonViews() {
        guard let layout else { return }

        var liveIDs = Set<String>()
        for (appID, btnFrame) in layout.taskButtonFrames {
            liveIDs.insert(appID)

            let tbv: TaskButtonEngineView
            if let existing = taskButtonViews[appID] {
                tbv = existing
            } else {
                tbv = TaskButtonEngineView(
                    style: theme.indicator,
                    hoverStyle: theme.hover,
                    iconStyle: theme.icons
                )
                                tbv.onActivate = { [weak self] in self?.onAppActivate?(appID) }
                tbv.rightClickMenuProvider = { [weak self] in self?.onAppRightClick?(appID) }
                // task buttons go inside the task segment
                addSubview(tbv)
                taskButtonViews[appID] = tbv
            }

            tbv.frame = btnFrame

            let indState = layout.indicatorStates[appID] ?? .none
            let hoverRect = layout.hoverRects[appID] ?? btnFrame
            let opacity: CGFloat = indState == .none ? 1.0 : 1.0 // Add minimized check from model state if needed

            tbv.configure(
                icon: iconProvider?(appID),
                indicatorState: indState,
                hoverRect: hoverRect,
                iconOpacity: opacity
            )
        }

        // Remove stale buttons
        for id in taskButtonViews.keys where !liveIDs.contains(id) {
            taskButtonViews[id]?.removeFromSuperview()
            taskButtonViews.removeValue(forKey: id)
        }
    }
}
