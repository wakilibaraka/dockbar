import AppKit

/// The behavioural half of a taskbar style.
///
/// Layout and appearance decisions live in `TaskbarStyleSpec`, which is pure data and
/// unit-testable. What stays here is what genuinely differs in behaviour: which view
/// hosts the widgets, what a click does, and whether a hover preview opens.
protocol TaskbarLayoutStrategy {
    var spec: TaskbarStyleSpec { get }

    // Panel Chrome
    var visualEffectMaterial: NSVisualEffectView.Material { get }
    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode
    func dockPosition(defaultPosition: DockPosition) -> DockPosition
    func usesCompactContentWidth(defaultUsesCompactWidth: Bool) -> Bool

    // Content Layout
    func dockWidgetWidths(originalWidths: [CGFloat], clusterWidth: CGFloat) -> [CGFloat]
    func container(for widgetID: String, zonesStackView: NSStackView, windowsTrayClusterView: NSView) -> NSView?
    func applyModeLayout(zonesStackView: NSStackView, launcherButtonView: NSView, launcherZoneView: NSView, defaultZoneEdgeInsets: NSEdgeInsets)
    func shouldGroupWindows(defaultGrouping: Bool) -> Bool
    var combinesPinnedApps: Bool { get }
    var groupsSingleWindows: Bool { get }

    // Click Handling
    func handleGroupClick(
        group: AppGroup,
        isActive: Bool,
        app: NSRunningApplication,
        firstWindow: WindowInfo,
        accessibilityService: AccessibilityService,
        defaultHide: () -> Void
    )

    // TaskZoneGroupButtonView Hooks
    func mouseUp(
        appGroup: AppGroup,
        popover: GroupThumbnailPopover,
        activationHandler: @escaping () -> Void,
        showHoverPreview: @escaping () -> Void
    )

    func configureAppearance(
        appGroup: AppGroup,
        titleLabel: NSTextField,
        titleLeadingConstraint: NSLayoutConstraint?,
        titleTrailingConstraint: NSLayoutConstraint?,
        windowsIconCenterConstraint: NSLayoutConstraint?,
        maxWidthConstraint: NSLayoutConstraint?,
        settings: TaskbarSettings,
        preferredWidth: CGFloat,
        widthCap: CGFloat?
    )

    func configureBackgroundColor(
        layer: CALayer?,
        windowsRunningIndicatorView: NSView,
        macRunningIndicatorView: NSView,
        isActive: Bool,
        needsAttention: Bool,
        isHovered: Bool,
        appGroupWindowCount: Int
    )
}

// MARK: - Shared behaviour

/// Implements everything a style does not need to override, in terms of `spec`.
extension TaskbarLayoutStrategy {
    var visualEffectMaterial: NSVisualEffectView.Material { spec.material }

    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode {
        spec.resolvedLayoutMode(userChoice: defaultLayoutMode)
    }

    func dockPosition(defaultPosition: DockPosition) -> DockPosition {
        spec.resolvedDockPosition(userChoice: defaultPosition)
    }

    func usesCompactContentWidth(defaultUsesCompactWidth: Bool) -> Bool {
        spec.resolvedCompactContentWidth(userChoice: defaultUsesCompactWidth)
    }

    func shouldGroupWindows(defaultGrouping: Bool) -> Bool {
        spec.resolvedGrouping(userChoice: defaultGrouping)
    }

    var combinesPinnedApps: Bool { spec.combinesPinnedApps }
    var groupsSingleWindows: Bool { spec.groupsSingleWindows }

    /// Styles that trail the window cluster after the widgets put the cluster in its own
    /// hosted view; the rest keep widgets in the main stack.
    func dockWidgetWidths(originalWidths: [CGFloat], clusterWidth: CGFloat) -> [CGFloat] {
        guard spec.windowClusterTrailsWidgets else { return originalWidths }
        return originalWidths + [clusterWidth + DesignSystem.Metrics.widgetClusterSpacing]
    }

    func container(for widgetID: String, zonesStackView: NSStackView, windowsTrayClusterView: NSView) -> NSView? {
        if spec.windowClusterTrailsWidgets {
            if windowsTrayClusterView.superview == nil {
                zonesStackView.addArrangedSubview(windowsTrayClusterView)
                zonesStackView.setCustomSpacing(4, after: windowsTrayClusterView)
            }
            return windowsTrayClusterView
        }
        windowsTrayClusterView.removeFromSuperview()
        return zonesStackView
    }

    func applyModeLayout(
        zonesStackView: NSStackView,
        launcherButtonView: NSView,
        launcherZoneView: NSView,
        defaultZoneEdgeInsets: NSEdgeInsets
    ) {
        zonesStackView.edgeInsets = spec.zoneInsets
        // One launcher affordance, not two: the button and the zone are alternative
        // launchers, and showing both leaves a duplicate control on the bar. Every style
        // keeps the button visible, because hiding both left icons-only bars with no way
        // to open the launcher at all.
        launcherButtonView.isHidden = false
        launcherZoneView.isHidden = true
    }

    func configureAppearance(
        appGroup: AppGroup,
        titleLabel: NSTextField,
        titleLeadingConstraint: NSLayoutConstraint?,
        titleTrailingConstraint: NSLayoutConstraint?,
        windowsIconCenterConstraint: NSLayoutConstraint?,
        maxWidthConstraint: NSLayoutConstraint?,
        settings: TaskbarSettings,
        preferredWidth: CGFloat,
        widthCap: CGFloat?
    ) {
        let iconOnlyWidth = appGroup.windows.count > 1 || !settings.showTitles
            ? nil
            : settings.taskbarHeight + 8

        switch spec.taskTitle {
        case .hidden:
            titleLabel.isHidden = true
            titleLeadingConstraint?.isActive = false
            titleTrailingConstraint?.isActive = false
            windowsIconCenterConstraint?.isActive = true
            maxWidthConstraint?.constant = DesignSystem.Metrics.iconOnlyTaskWidth

        case .hiddenSizedToBar:
            titleLabel.isHidden = true
            titleLeadingConstraint?.isActive = false
            titleTrailingConstraint?.isActive = false
            windowsIconCenterConstraint?.isActive = true
            maxWidthConstraint?.constant = settings.taskbarHeight + 8

        case .whenItFits:
            let title = appGroup.appName
            let cappedWidth = widthCap
                .map { min(preferredWidth, max(TaskButtonView.minimumTaskWidth, $0)) }
                ?? preferredWidth
            let shouldShowTitle = settings.showTitles
                && !title.isEmpty
                && cappedWidth >= DesignSystem.Metrics.minimumWidthForTitle

            titleLabel.isHidden = !shouldShowTitle
            titleLeadingConstraint?.isActive = shouldShowTitle
            titleTrailingConstraint?.isActive = shouldShowTitle
            windowsIconCenterConstraint?.isActive = !shouldShowTitle
            maxWidthConstraint?.constant = shouldShowTitle ? cappedWidth : (iconOnlyWidth ?? preferredWidth)
        }
    }

    func configureBackgroundColor(
        layer: CALayer?,
        windowsRunningIndicatorView: NSView,
        macRunningIndicatorView: NSView,
        isActive: Bool,
        needsAttention: Bool,
        isHovered: Bool,
        appGroupWindowCount: Int
    ) {
        windowsRunningIndicatorView.isHidden = !spec.showsRunningIndicator(forWindowCount: appGroupWindowCount)
        macRunningIndicatorView.isHidden = spec.runningIndicator != .dot

        guard let color = spec.backgroundColor(
            isActive: isActive,
            needsAttention: needsAttention,
            isHovered: isHovered
        ) else {
            layer?.backgroundColor = NSColor.clear.cgColor
            return
        }
        layer?.backgroundColor = color.cgColor
    }
}

// MARK: - Click behaviour

extension TaskbarLayoutStrategy {
    /// Clicking the already-focused app: either cycle to its last window, or hide it.
    func cycleToLastWindowOrHide(
        group: AppGroup,
        isActive: Bool,
        app: NSRunningApplication,
        accessibilityService: AccessibilityService,
        defaultHide: () -> Void
    ) {
        guard isActive else { return }
        if group.windows.count > 1 {
            let axWindows = accessibilityService.enumerateWindows(for: app)
            if let lastWindow = axWindows.last {
                accessibilityService.raiseAndActivate(element: lastWindow, app: app)
            }
        } else {
            defaultHide()
        }
    }

    func mouseUp(
        appGroup: AppGroup,
        popover: GroupThumbnailPopover,
        activationHandler: @escaping () -> Void,
        showHoverPreview: @escaping () -> Void
    ) {
        activationHandler()
    }
}

// MARK: - The five styles

/// Fully user-controlled: the bar people can reshape into anything.
struct CustomTaskbarStrategy: TaskbarLayoutStrategy {
    let spec: TaskbarStyleSpec = .custom

    func handleGroupClick(
        group: AppGroup,
        isActive: Bool,
        app: NSRunningApplication,
        firstWindow: WindowInfo,
        accessibilityService: AccessibilityService,
        defaultHide: () -> Void
    ) {
        cycleToLastWindowOrHide(
            group: group,
            isActive: isActive,
            app: app,
            accessibilityService: accessibilityService,
            defaultHide: defaultHide
        )
    }
}

/// A Windows 11 taskbar: grouped windows and a run count on each button.
struct WindowsTaskbarStrategy: TaskbarLayoutStrategy {
    let spec: TaskbarStyleSpec = .windows

    func handleGroupClick(
        group: AppGroup,
        isActive: Bool,
        app: NSRunningApplication,
        firstWindow: WindowInfo,
        accessibilityService: AccessibilityService,
        defaultHide: () -> Void
    ) {
        guard isActive else { return }
        if group.windows.count > 1 {
            cycleToLastWindowOrHide(
                group: group,
                isActive: isActive,
                app: app,
                accessibilityService: accessibilityService,
                defaultHide: defaultHide
            )
        } else if let axWindow = TaskButtonView.resolveWindowElement(
            for: firstWindow,
            application: app,
            accessibilityService: accessibilityService
        ) {
            accessibilityService.minimize(element: axWindow)
        } else {
            defaultHide()
        }
    }

    /// A short delay before the window picker opens, so the click that raised the window
    /// is not immediately swallowed by the picker.
    func mouseUp(
        appGroup: AppGroup,
        popover: GroupThumbnailPopover,
        activationHandler: @escaping () -> Void,
        showHoverPreview: @escaping () -> Void
    ) {
        activationHandler()
        guard appGroup.windows.count > 1 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Motion.groupedPreviewDelay) {
            showHoverPreview()
        }
    }
}

/// A macOS-style floating dock: always grouped, icons only, and no widgets in the bar.
struct MacTaskbarStrategy: TaskbarLayoutStrategy {
    let spec: TaskbarStyleSpec = .mac

    /// The Mac style puts widgets in the menu bar only, so anything still parented to the
    /// tray cluster has to be detached: switching away would otherwise strand those
    /// widgets inside a detached view and they would silently disappear.
    func container(for widgetID: String, zonesStackView: NSStackView, windowsTrayClusterView: NSView) -> NSView? {
        for widget in windowsTrayClusterView.subviews {
            widget.removeFromSuperview()
        }
        windowsTrayClusterView.removeFromSuperview()
        return nil
    }

    /// The Mac dock neither minimises nor hides on click, so there is nothing to do.
    func handleGroupClick(
        group: AppGroup,
        isActive: Bool,
        app: NSRunningApplication,
        firstWindow: WindowInfo,
        accessibilityService: AccessibilityService,
        defaultHide: () -> Void
    ) {}

    func mouseUp(
        appGroup: AppGroup,
        popover: GroupThumbnailPopover,
        activationHandler: @escaping () -> Void,
        showHoverPreview: @escaping () -> Void
    ) {
        activationHandler()
        if appGroup.windows.count > 1, !popover.isShown {
            showHoverPreview()
        }
    }
}

/// The original solid bar: edge to edge, one button per window, no grouping.
struct ClassicTaskbarStrategy: TaskbarLayoutStrategy {
    let spec: TaskbarStyleSpec = .classic

    func handleGroupClick(
        group: AppGroup,
        isActive: Bool,
        app: NSRunningApplication,
        firstWindow: WindowInfo,
        accessibilityService: AccessibilityService,
        defaultHide: () -> Void
    ) {
        cycleToLastWindowOrHide(
            group: group,
            isActive: isActive,
            app: app,
            accessibilityService: accessibilityService,
            defaultHide: defaultHide
        )
    }
}

/// Eskele's pill: fits its contents, icons only, one button per window.
struct EskeleTaskbarStrategy: TaskbarLayoutStrategy {
    let spec: TaskbarStyleSpec = .eskele

    func handleGroupClick(
        group: AppGroup,
        isActive: Bool,
        app: NSRunningApplication,
        firstWindow: WindowInfo,
        accessibilityService: AccessibilityService,
        defaultHide: () -> Void
    ) {
        cycleToLastWindowOrHide(
            group: group,
            isActive: isActive,
            app: app,
            accessibilityService: accessibilityService,
            defaultHide: defaultHide
        )
    }
}

extension TaskbarMode {
    var strategy: TaskbarLayoutStrategy {
        switch self {
        case .custom: return CustomTaskbarStrategy()
        case .windows: return WindowsTaskbarStrategy()
        case .mac: return MacTaskbarStrategy()
        case .classic: return ClassicTaskbarStrategy()
        case .eskele: return EskeleTaskbarStrategy()
        }
    }
}