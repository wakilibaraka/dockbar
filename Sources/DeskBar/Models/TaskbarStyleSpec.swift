import AppKit

/// Everything a taskbar style decides, expressed as data.
///
/// The five `TaskbarLayoutStrategy` implementations had grown a dozen near-identical
/// methods each, differing only by a few constants. Those constants are the interesting
/// part, so they are hoisted here into one value per style that can be read, compared and
/// tested directly.
///
/// Only genuinely behavioural differences (which view hosts the widgets, what a click
/// does, whether a preview opens) stay as code on the strategy.
struct TaskbarStyleSpec {
    // MARK: Chrome

    var material: NSVisualEffectView.Material
    /// The layout the style forces, overriding the user's layout picker.
    var layoutMode: DeskBarLayoutMode?
    /// The position the style forces. `nil` respects the user's choice.
    var dockPosition: DockPosition?
    /// The screen edge the style forces. `nil` respects the user's choice.
    var edge: BarEdge?
    /// Whether the bar hugs its contents instead of filling its layout.
    var usesCompactContentWidth: Bool
    /// Whether the bar floats clear of its edge instead of sitting flush against it.
    var floatsClearOfEdge: Bool
    /// Whether the bar's cells wrap onto more than one row. Only a vertical bar can.
    var allowsMultipleRows: Bool
    /// Padding inside the content stack.
    var zoneInsets: NSEdgeInsets

    // MARK: Windows

    /// `nil` respects the user's grouping setting; `true` and `false` force it.
    var forcesGrouping: Bool?
    var combinesPinnedApps: Bool
    /// Whether a group of one still behaves like a group (Mac dock style).
    var groupsSingleWindows: Bool

    // MARK: Task buttons

    var taskTitle: TaskTitlePresentation
    /// Alpha behind the active app's button.
    var activeFillAlpha: CGFloat
    var attentionFillAlpha: CGFloat
    var hoverFillAlpha: CGFloat
    /// Which running indicator a style draws.
    var runningIndicator: RunningIndicator
    /// Whether widgets are hosted inside the bar's own stack, or live only in the menu bar.
    var hostsWidgetsInBar: Bool
    /// Whether the window cluster trails the widgets or leads them.
    var windowClusterTrailsWidgets: Bool

    // MARK: Launcher

    /// Which launcher the bar's apps zone shows.
    var launcher: LauncherKind
    /// What the apps zone lists.
    var appsMenuSource: AppsMenuSource

    /// How a style draws a task button's title.
    enum TaskTitlePresentation: Equatable {
        /// Show the title when there is room for it.
        case whenItFits
        /// Never show the title; the button is a fixed-size icon.
        case hidden
        /// Never show the title, but size the button from the bar height.
        case hiddenSizedToBar
    }

    /// Which "this app is running" indicator a style draws.
    enum RunningIndicator: Equatable {
        case none
        /// A count shown only when the app has more than one window.
        case windowCount
        /// A dot shown whenever the app has any window.
        case dot
    }

    /// Which launcher a style puts in its apps zone.
    enum LauncherKind: Equatable {
        /// DeskBar's own anchored launcher.
        case deskBar
        /// eskele's Launchpick: a searchable panel over a ranked app list.
        case launchpick
    }

    /// Where a style's apps list comes from.
    enum AppsMenuSource: Equatable {
        case pinned
        case allApps
        case recent
    }

    // MARK: Derived

    /// `NSVisualEffectView.Material` is not `Equatable`, so equality is written out
    /// rather than synthesised. Tests use this to prove a strategy and its spec agree.
    static func == (lhs: TaskbarStyleSpec, rhs: TaskbarStyleSpec) -> Bool {
        lhs.material.rawValue == rhs.material.rawValue
            && lhs.layoutMode == rhs.layoutMode
            && lhs.dockPosition == rhs.dockPosition
            && lhs.edge == rhs.edge
            && lhs.usesCompactContentWidth == rhs.usesCompactContentWidth
            && lhs.floatsClearOfEdge == rhs.floatsClearOfEdge
            && lhs.allowsMultipleRows == rhs.allowsMultipleRows
            && lhs.zoneInsets.top == rhs.zoneInsets.top
            && lhs.zoneInsets.left == rhs.zoneInsets.left
            && lhs.zoneInsets.bottom == rhs.zoneInsets.bottom
            && lhs.zoneInsets.right == rhs.zoneInsets.right
            && lhs.forcesGrouping == rhs.forcesGrouping
            && lhs.combinesPinnedApps == rhs.combinesPinnedApps
            && lhs.groupsSingleWindows == rhs.groupsSingleWindows
            && lhs.taskTitle == rhs.taskTitle
            && lhs.activeFillAlpha == rhs.activeFillAlpha
            && lhs.attentionFillAlpha == rhs.attentionFillAlpha
            && lhs.hoverFillAlpha == rhs.hoverFillAlpha
            && lhs.runningIndicator == rhs.runningIndicator
            && lhs.hostsWidgetsInBar == rhs.hostsWidgetsInBar
            && lhs.windowClusterTrailsWidgets == rhs.windowClusterTrailsWidgets
            && lhs.launcher == rhs.launcher
            && lhs.appsMenuSource == rhs.appsMenuSource
    }

    /// The layout to use, given what the user picked.
    func resolvedLayoutMode(userChoice: DeskBarLayoutMode) -> DeskBarLayoutMode {
        layoutMode ?? userChoice
    }

    func resolvedDockPosition(userChoice: DockPosition) -> DockPosition {
        dockPosition ?? userChoice
    }

    /// The edge the bar sits on, given what the user picked.
    func resolvedEdge(userChoice: BarEdge) -> BarEdge {
        edge ?? userChoice
    }

    /// Whether the bar spans the edge or only fills what it needs.
    ///
    /// A style that forces an edge has an opinion here too: a vertical bar hugs its
    /// contents, because a full-height bar down the side of the screen is a different
    /// product from the eskele pill it is imitating.
    func resolvedSpan(userChoice: BarSpan) -> BarSpan {
        edge == nil ? userChoice : (usesCompactContentWidth ? .hugContents : .fullSpan)
    }

    /// The number of rows of cells the bar stacks its buttons into.
    func resolvedRowCount(userChoice: Int, edge: BarEdge) -> Int {
        guard edge.isVertical else { return 1 }
        return allowsMultipleRows ? max(1, userChoice) : 1
    }

    /// Whether windows are grouped, given what the user picked.
    func resolvedGrouping(userChoice: Bool) -> Bool {
        forcesGrouping ?? userChoice
    }

    func resolvedCompactContentWidth(userChoice: Bool) -> Bool {
        // A style that only pins the layout still has an opinion about hugging content.
        layoutMode == nil ? userChoice : usesCompactContentWidth
    }

    /// The alpha behind a task button in a given state.
    func fillAlpha(isActive: Bool, needsAttention: Bool, isHovered: Bool) -> CGFloat {
        if isActive { return activeFillAlpha }
        if needsAttention { return attentionFillAlpha }
        if isHovered { return hoverFillAlpha }
        return 0
    }

    func showsRunningIndicator(forWindowCount count: Int) -> Bool {
        switch runningIndicator {
        case .none: return false
        case .windowCount: return count > 0
        case .dot: return count > 0
        }
    }

    /// The fill behind a task button in a given state, or `nil` for a transparent one.
    ///
    /// Pure, so it can be asserted without any views. The mac dock style draws no active
    /// fill at all, because its running dot already says which app is focused.
    func backgroundColor(isActive: Bool, needsAttention: Bool, isHovered: Bool) -> NSColor? {
        if isActive, activeFillAlpha > 0 {
            return NSColor.controlAccentColor.withAlphaComponent(activeFillAlpha)
        }
        if needsAttention, attentionFillAlpha > 0 {
            return DesignSystem.State.attention.withAlphaComponent(attentionFillAlpha)
        }
        if isHovered, hoverFillAlpha > 0 {
            return DesignSystem.State.hoverFill(alpha: hoverFillAlpha)
        }
        return nil
    }
}

// MARK: - The five styles

extension TaskbarStyleSpec {
    /// Fully user-controlled: this is the bar people can reshape into anything.
    static let custom = TaskbarStyleSpec(
        material: .popover,
        layoutMode: nil,
        dockPosition: nil,
        edge: nil,
        usesCompactContentWidth: true,
        floatsClearOfEdge: false,
        allowsMultipleRows: true,
        zoneInsets: NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8),
        forcesGrouping: nil,
        combinesPinnedApps: false,
        groupsSingleWindows: false,
        taskTitle: .whenItFits,
        activeFillAlpha: 0.30,
        attentionFillAlpha: 0.14,
        hoverFillAlpha: 0.10,
        runningIndicator: .none,
        hostsWidgetsInBar: true,
        windowClusterTrailsWidgets: false,
        launcher: .deskBar,
        appsMenuSource: .pinned,
    )

    /// A Windows 11 taskbar: full width, Start-style launcher, grouped windows, a run
    /// count on each button, and widgets pinned to the far right.
    static let windows = TaskbarStyleSpec(
        material: .sidebar,
        layoutMode: .fullWidthGlass,
        dockPosition: .bottomCenter,
        edge: .bottom,
        usesCompactContentWidth: false,
        floatsClearOfEdge: false,
        allowsMultipleRows: false,
        zoneInsets: NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12),
        forcesGrouping: true,
        combinesPinnedApps: true,
        groupsSingleWindows: false,
        taskTitle: .hidden,
        activeFillAlpha: 0.30,
        attentionFillAlpha: 0.14,
        hoverFillAlpha: 0.08,
        runningIndicator: .windowCount,
        hostsWidgetsInBar: true,
        windowClusterTrailsWidgets: true,
        launcher: .deskBar,
        appsMenuSource: .pinned,
    )

    /// A macOS-style floating dock: compact, always grouped, icons only, running dot,
    /// and no widgets in the bar at all.
    static let mac = TaskbarStyleSpec(
        material: .popover,
        layoutMode: .compactGlass,
        dockPosition: .floatingCenter,
        edge: .bottom,
        usesCompactContentWidth: true,
        floatsClearOfEdge: true,
        allowsMultipleRows: false,
        zoneInsets: NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12),
        forcesGrouping: true,
        combinesPinnedApps: true,
        groupsSingleWindows: true,
        taskTitle: .hidden,
        activeFillAlpha: 0.0,
        attentionFillAlpha: 0.0,
        hoverFillAlpha: 0.08,
        runningIndicator: .dot,
        hostsWidgetsInBar: false,
        windowClusterTrailsWidgets: false,
        launcher: .deskBar,
        appsMenuSource: .pinned,
    )

    /// The original solid bar: edge to edge, one button per window, no grouping.
    static let classic = TaskbarStyleSpec(
        material: .contentBackground,
        layoutMode: .fullWidth,
        dockPosition: .bottomCenter,
        edge: .bottom,
        usesCompactContentWidth: false,
        floatsClearOfEdge: false,
        allowsMultipleRows: false,
        zoneInsets: NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12),
        forcesGrouping: false,
        combinesPinnedApps: false,
        groupsSingleWindows: false,
        taskTitle: .whenItFits,
        activeFillAlpha: 0.30,
        attentionFillAlpha: 0.14,
        hoverFillAlpha: 0.10,
        runningIndicator: .none,
        hostsWidgetsInBar: true,
        windowClusterTrailsWidgets: true,
        launcher: .deskBar,
        appsMenuSource: .pinned,
    )

    /// Eskele's pill, rebuilt on DockBar's bar: a vertical strip down the left edge that
    /// hugs its contents, icons only, one button per window, and eskele's launcher and
    /// apps menu in place of the bar's own zones.
    static let eskele = TaskbarStyleSpec(
        material: .hudWindow,
        layoutMode: .compactGlass,
        dockPosition: .floatingCenter,
        edge: .left,
        usesCompactContentWidth: true,
        floatsClearOfEdge: true,
        allowsMultipleRows: true,
        zoneInsets: NSEdgeInsets(top: 6, left: 8, bottom: 6, right: 8),
        forcesGrouping: false,
        combinesPinnedApps: false,
        groupsSingleWindows: false,
        taskTitle: .hiddenSizedToBar,
        activeFillAlpha: 0.35,
        attentionFillAlpha: 0.18,
        hoverFillAlpha: 0.12,
        runningIndicator: .none,
        hostsWidgetsInBar: true,
        windowClusterTrailsWidgets: false,
        launcher: .launchpick,
        appsMenuSource: .allApps,
    )

    /// The hybrid: DeskBar's solid edge-to-edge bar, but with eskele's launcher and apps
    /// menu. The bar itself is the Classic one — full width, flush against the bottom
    /// edge, widgets trailing — so this mode changes what the bar *does* rather than what
    /// it looks like.
    static let hybrid = TaskbarStyleSpec(
        material: .contentBackground,
        layoutMode: .fullWidth,
        dockPosition: .bottomCenter,
        edge: .bottom,
        usesCompactContentWidth: false,
        floatsClearOfEdge: false,
        allowsMultipleRows: false,
        zoneInsets: NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12),
        forcesGrouping: false,
        combinesPinnedApps: false,
        groupsSingleWindows: false,
        taskTitle: .whenItFits,
        activeFillAlpha: 0.30,
        attentionFillAlpha: 0.14,
        hoverFillAlpha: 0.10,
        runningIndicator: .none,
        hostsWidgetsInBar: true,
        windowClusterTrailsWidgets: true,
        launcher: .launchpick,
        appsMenuSource: .allApps,
    )
}

extension TaskbarMode {
    /// The declarative half of this style.
    var spec: TaskbarStyleSpec {
        switch self {
        case .custom: return .custom
        case .windows: return .windows
        case .mac: return .mac
        case .classic: return .classic
        case .eskele: return .eskele
        case .hybrid: return .hybrid
        }
    }
}