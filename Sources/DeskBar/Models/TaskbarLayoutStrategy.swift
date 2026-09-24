import AppKit

protocol TaskbarLayoutStrategy {
    // Panel Chrome
    var visualEffectMaterial: NSVisualEffectView.Material { get }
    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode
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

struct CustomTaskbarStrategy: TaskbarLayoutStrategy {
    var visualEffectMaterial: NSVisualEffectView.Material { .popover }
    
    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode {
        defaultLayoutMode
    }
    
    func usesCompactContentWidth(defaultUsesCompactWidth: Bool) -> Bool {
        true
    }
    
    func dockWidgetWidths(originalWidths: [CGFloat], clusterWidth: CGFloat) -> [CGFloat] {
        originalWidths
    }
    
    func container(for widgetID: String, zonesStackView: NSStackView, windowsTrayClusterView: NSView) -> NSView? {
        windowsTrayClusterView.removeFromSuperview()
        return zonesStackView
    }
    
    func applyModeLayout(zonesStackView: NSStackView, launcherButtonView: NSView, launcherZoneView: NSView, defaultZoneEdgeInsets: NSEdgeInsets) {
        zonesStackView.edgeInsets = defaultZoneEdgeInsets
        launcherButtonView.isHidden = false
        launcherZoneView.isHidden = false
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

struct WindowsTaskbarStrategy: TaskbarLayoutStrategy {
    var visualEffectMaterial: NSVisualEffectView.Material { .sidebar }
    
    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode {
        .fullWidthGlass
    }
    
    func usesCompactContentWidth(defaultUsesCompactWidth: Bool) -> Bool {
        false
    }
    
    func dockWidgetWidths(originalWidths: [CGFloat], clusterWidth: CGFloat) -> [CGFloat] {
        originalWidths + [clusterWidth + 12]
    }
    
    func container(for widgetID: String, zonesStackView: NSStackView, windowsTrayClusterView: NSView) -> NSView? {
        if windowsTrayClusterView.superview == nil {
            zonesStackView.addArrangedSubview(windowsTrayClusterView)
            zonesStackView.setCustomSpacing(4, after: windowsTrayClusterView)
        }
        return windowsTrayClusterView
    }
    
    func applyModeLayout(zonesStackView: NSStackView, launcherButtonView: NSView, launcherZoneView: NSView, defaultZoneEdgeInsets: NSEdgeInsets) {
        zonesStackView.edgeInsets = NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        launcherButtonView.isHidden = false
        launcherZoneView.isHidden = true
    }
    
    func shouldGroupWindows(defaultGrouping: Bool) -> Bool {
        true
    }
    
    var combinesPinnedApps: Bool { true }
    var groupsSingleWindows: Bool { false }
    
    func handleGroupClick(group: AppGroup, isActive: Bool, app: NSRunningApplication, firstWindow: WindowInfo, accessibilityService: AccessibilityService, defaultHide: () -> Void) {
        if isActive {
            if group.windows.count > 1 {
                let axWindows = accessibilityService.enumerateWindows(for: app)
                if let lastWindow = axWindows.last {
                    accessibilityService.raiseAndActivate(element: lastWindow, app: app)
                }
            } else {
                if let axWindow = TaskButtonView.resolveWindowElement(for: firstWindow, application: app, accessibilityService: accessibilityService) {
                    accessibilityService.minimize(element: axWindow)
                } else {
                    defaultHide()
                }
            }
        }
    }
    
    func mouseUp(appGroup: AppGroup, popover: GroupThumbnailPopover, activationHandler: @escaping () -> Void, showHoverPreview: @escaping () -> Void) {
        if appGroup.windows.count > 1 {
            activationHandler()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showHoverPreview()
            }
        } else {
            activationHandler()
        }
    }
    
    func configureAppearance(appGroup: AppGroup, titleLabel: NSTextField, titleLeadingConstraint: NSLayoutConstraint?, titleTrailingConstraint: NSLayoutConstraint?, windowsIconCenterConstraint: NSLayoutConstraint?, maxWidthConstraint: NSLayoutConstraint?, settings: TaskbarSettings, preferredWidth: CGFloat, widthCap: CGFloat?) {
        let title = appGroup.appName
        let showsTitle = settings.showTitles && !title.isEmpty
        titleLabel.isHidden = !showsTitle
        titleLeadingConstraint?.isActive = showsTitle
        titleTrailingConstraint?.isActive = showsTitle
        windowsIconCenterConstraint?.isActive = !showsTitle
        
        if showsTitle {
            let cappedWidth = widthCap.map { min(preferredWidth, max(TaskButtonView.minimumTaskWidth, $0)) } ?? preferredWidth
            maxWidthConstraint?.constant = cappedWidth
        } else {
            maxWidthConstraint?.constant = 48
        }
    }
    
    func configureBackgroundColor(layer: CALayer?, windowsRunningIndicatorView: NSView, macRunningIndicatorView: NSView, isActive: Bool, needsAttention: Bool, isHovered: Bool, appGroupWindowCount: Int) {
        windowsRunningIndicatorView.isHidden = appGroupWindowCount == 0
        macRunningIndicatorView.isHidden = true
        
        if isActive {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
        } else if needsAttention {
            layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.14).cgColor
        } else if isHovered {
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}



struct MacTaskbarStrategy: TaskbarLayoutStrategy {
    var visualEffectMaterial: NSVisualEffectView.Material { .popover }
    
    func layoutMode(defaultLayoutMode: DeskBarLayoutMode) -> DeskBarLayoutMode {
        .compactGlass
    }
    
    func usesCompactContentWidth(defaultUsesCompactWidth: Bool) -> Bool {
        true
    }
    
    func dockWidgetWidths(originalWidths: [CGFloat], clusterWidth: CGFloat) -> [CGFloat] {
        []
    }
    
    func container(for widgetID: String, zonesStackView: NSStackView, windowsTrayClusterView: NSView) -> NSView? {
        windowsTrayClusterView.removeFromSuperview()
        return nil // Mac mode uses NSStatusItems managed by AppDelegate, so no dock container
    }
    
    func applyModeLayout(zonesStackView: NSStackView, launcherButtonView: NSView, launcherZoneView: NSView, defaultZoneEdgeInsets: NSEdgeInsets) {
        zonesStackView.edgeInsets = NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        launcherButtonView.isHidden = true
        launcherZoneView.isHidden = true
    }
    
    func shouldGroupWindows(defaultGrouping: Bool) -> Bool {
        true
    }
    
    var combinesPinnedApps: Bool { true }
    var groupsSingleWindows: Bool { true }
    
    func handleGroupClick(group: AppGroup, isActive: Bool, app: NSRunningApplication, firstWindow: WindowInfo, accessibilityService: AccessibilityService, defaultHide: () -> Void) {
        if isActive {
            // Mac dock does not minimize or hide on click.
        }
    }
    
    func mouseUp(appGroup: AppGroup, popover: GroupThumbnailPopover, activationHandler: @escaping () -> Void, showHoverPreview: @escaping () -> Void) {
        activationHandler()
        if appGroup.windows.count > 1 {
            if !popover.isShown {
                showHoverPreview()
            }
        }
    }
    
    func configureAppearance(appGroup: AppGroup, titleLabel: NSTextField, titleLeadingConstraint: NSLayoutConstraint?, titleTrailingConstraint: NSLayoutConstraint?, windowsIconCenterConstraint: NSLayoutConstraint?, maxWidthConstraint: NSLayoutConstraint?, settings: TaskbarSettings, preferredWidth: CGFloat, widthCap: CGFloat?) {
        titleLabel.isHidden = true
        titleLeadingConstraint?.isActive = false
        titleTrailingConstraint?.isActive = false
        windowsIconCenterConstraint?.isActive = true
        
        maxWidthConstraint?.constant = 48
    }
    
    func configureBackgroundColor(layer: CALayer?, windowsRunningIndicatorView: NSView, macRunningIndicatorView: NSView, isActive: Bool, needsAttention: Bool, isHovered: Bool, appGroupWindowCount: Int) {
        windowsRunningIndicatorView.isHidden = true
        macRunningIndicatorView.isHidden = appGroupWindowCount == 0
        
        if isHovered {
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}

extension TaskbarMode {
    var strategy: TaskbarLayoutStrategy {
        switch self {
        case .custom: return CustomTaskbarStrategy()
        case .windows: return WindowsTaskbarStrategy()
        case .mac: return MacTaskbarStrategy()
        }
    }
}
