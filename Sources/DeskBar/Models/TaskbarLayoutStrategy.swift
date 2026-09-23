import AppKit

protocol TaskbarLayoutStrategy {
    // Panel Chrome
    var visualEffectMaterial: NSVisualEffectView.Material { get }
    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode
    func usesCompactContentWidth(defaultUsesCompactWidth: Bool) -> Bool
    
    // Content Layout
    func dockWidgetWidths(originalWidths: [CGFloat], clusterWidth: CGFloat) -> [CGFloat]
    func applyDockWidgetOrder(zonesStackView: NSStackView, windowsTrayClusterView: NSView, viewsByID: [String: NSView], orderedIDs: [String])
    func applyModeLayout(zonesStackView: NSStackView, launcherZoneView: NSView, startButtonView: NSView, defaultZoneEdgeInsets: NSEdgeInsets)
    
    // Window Grouping
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

struct CustomTaskbarStrategy: TaskbarLayoutStrategy {
    var visualEffectMaterial: NSVisualEffectView.Material { .popover }
    
    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode {
        defaultLayoutMode
    }
    
    func usesCompactContentWidth(defaultUsesCompactWidth: Bool) -> Bool {
        defaultUsesCompactWidth
    }
    
    func dockWidgetWidths(originalWidths: [CGFloat], clusterWidth: CGFloat) -> [CGFloat] {
        originalWidths
    }
    
    func applyDockWidgetOrder(zonesStackView: NSStackView, windowsTrayClusterView: NSView, viewsByID: [String: NSView], orderedIDs: [String]) {
        windowsTrayClusterView.removeFromSuperview()
        for widgetID in orderedIDs {
            if let view = viewsByID[widgetID], view.superview == nil {
                zonesStackView.addArrangedSubview(view)
            }
        }
    }
    
    func applyModeLayout(zonesStackView: NSStackView, launcherZoneView: NSView, startButtonView: NSView, defaultZoneEdgeInsets: NSEdgeInsets) {
        zonesStackView.edgeInsets = defaultZoneEdgeInsets
        launcherZoneView.isHidden = false
        startButtonView.isHidden = true
    }
    
    func shouldGroupWindows(defaultGrouping: Bool) -> Bool {
        defaultGrouping
    }
    
    var combinesPinnedApps: Bool { false }
    var groupsSingleWindows: Bool { false }
    
    func handleGroupClick(group: AppGroup, isActive: Bool, app: NSRunningApplication, firstWindow: WindowInfo, accessibilityService: AccessibilityService, defaultHide: () -> Void) {
        if isActive {
            if group.windows.count > 1 {
                let axWindows = accessibilityService.enumerateWindows(for: app)
                if let lastWindow = axWindows.last {
                    accessibilityService.raiseAndActivate(element: lastWindow, app: app)
                }
            } else {
                defaultHide()
            }
        }
    }
    
    func mouseUp(appGroup: AppGroup, popover: GroupThumbnailPopover, activationHandler: @escaping () -> Void, showHoverPreview: @escaping () -> Void) {
        activationHandler()
    }
    
    func configureAppearance(appGroup: AppGroup, titleLabel: NSTextField, titleLeadingConstraint: NSLayoutConstraint?, titleTrailingConstraint: NSLayoutConstraint?, windowsIconCenterConstraint: NSLayoutConstraint?, maxWidthConstraint: NSLayoutConstraint?, settings: TaskbarSettings, preferredWidth: CGFloat, widthCap: CGFloat?) {
        let title = appGroup.appName
        let showsTitle = settings.showTitles && !title.isEmpty
        titleLabel.isHidden = !showsTitle
        titleLeadingConstraint?.isActive = showsTitle
        titleTrailingConstraint?.isActive = showsTitle
        windowsIconCenterConstraint?.isActive = false
        
        if showsTitle {
            let cappedWidth = widthCap.map { min(preferredWidth, max(TaskButtonView.minimumTaskWidth, $0)) } ?? preferredWidth
            maxWidthConstraint?.constant = cappedWidth
        } else {
            maxWidthConstraint?.constant = settings.taskbarHeight + 8
        }
    }
    
    func configureBackgroundColor(layer: CALayer?, windowsRunningIndicatorView: NSView, macRunningIndicatorView: NSView, isActive: Bool, needsAttention: Bool, isHovered: Bool, appGroupWindowCount: Int) {
        windowsRunningIndicatorView.isHidden = true
        macRunningIndicatorView.isHidden = true
        
        if isActive {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
        } else if needsAttention {
            layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.14).cgColor
        } else if isHovered {
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}
