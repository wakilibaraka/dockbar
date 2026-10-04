import AppKit
import Combine

/// One task button in the bar.
///
/// Owns its icon, title, status indicators, hover preview, context menu, and drag
/// source. Extracted from `TaskbarContentView.swift`, which held this class alongside
/// three other types purely because they were all private to it.


final class TaskZoneGroupButtonView: NSView, NSDraggingSource, TaskbarWidthParticipant {
    private var appGroup: AppGroup
    private var hasBadge: Bool
    private var runtimeState: AppRuntimeState
    private var showsActivityOverlay: Bool
    private let settings: TaskbarSettings
    private let activationHandler: () -> Void
    private let dragConfiguration: TaskButtonDragConfiguration?
    private let windowActivationHandler: (WindowInfo) -> Void
    private let thumbnailProvider: (CGWindowID) async -> NSImage?
    private let thumbnailService: ThumbnailService?
    private let accessibilityService = AccessibilityService()
    private let popover: GroupThumbnailPopover
    private var hoverWorkItem: DispatchWorkItem?
    private var closePopoverWorkItem: DispatchWorkItem?
    private var thumbnailRequestTask: Task<Void, Never>?
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private var titleLeadingConstraint: NSLayoutConstraint?
    private var titleTrailingConstraint: NSLayoutConstraint?
    private var windowsIconCenterConstraint: NSLayoutConstraint?
    private var maxWidthConstraint: NSLayoutConstraint?
    private var widthCap: CGFloat?
    private var usesAdaptiveWidth = false
    private let statusIndicatorView = NSView()
    private let windowsRunningIndicatorView = NSView()
    private let macRunningIndicatorView = NSView()
    private let activityBadgeView = NSVisualEffectView()
    private let activityLabel = NSTextField(labelWithString: "")
    private let badgeView = NSView()
    private let badgeLabel = NSTextField(labelWithString: "")
    private let progressTrackView = NSView()
    private let progressFillView = NSView()
    private let dropIndicatorView = NSView()
    private let dotsStackView = NSStackView()
    private var trackingAreaRef: NSTrackingArea?
    private var progressWidthConstraint: NSLayoutConstraint?
    private var dropIndicatorLeadingConstraint: NSLayoutConstraint?
    private var dropIndicatorTrailingConstraint: NSLayoutConstraint?
    private var mouseDownLocation: NSPoint?
    private var didBeginDraggingSession = false
    private var isHovered = false {
        didSet {
            updateBackgroundColor()
        }
    }

    var isActive: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    init(
        appGroup: AppGroup,
        hasBadge: Bool,
        runtimeState: AppRuntimeState,
        showsActivityOverlay: Bool,
        isActive: Bool,
        settings: TaskbarSettings,
        dragConfiguration: TaskButtonDragConfiguration?,
        activationHandler: @escaping () -> Void,
        windowActivationHandler: @escaping (WindowInfo) -> Void,
        thumbnailProvider: @escaping (CGWindowID) async -> NSImage?, thumbnailService: ThumbnailService?
    ) {
        self.appGroup = appGroup
        self.hasBadge = hasBadge
        self.runtimeState = runtimeState
        self.showsActivityOverlay = showsActivityOverlay
        self.isActive = isActive
        self.settings = settings
        self.dragConfiguration = dragConfiguration
        self.activationHandler = activationHandler
        self.windowActivationHandler = windowActivationHandler
        self.thumbnailProvider = thumbnailProvider
        self.thumbnailService = thumbnailService
        self.popover = GroupThumbnailPopover(settings: settings)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true

        configureSubviews()
        updateAppearance()

        if dragConfiguration != nil {
            registerForDraggedTypes([TaskButtonView.dragPasteboardType])
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        if showsActivityOverlay, runtimeState.activitySummary != nil {
            return NSSize(width: 140, height: 32)
        }

        return NSSize(width: 40, height: 32)
    }

    override func layout() {
        super.layout()
        updateProgressWidth()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingAreaRef = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingAreaRef)
        self.trackingAreaRef = trackingAreaRef
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        let hoverDelay = settings.hoverDelay
        let workItem = DispatchWorkItem { [weak self] in
            self?.showHoverPreview()
        }
        hoverWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + hoverDelay, execute: workItem)
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        cancelHoverPreview()
        updateDropIndicator(nil)
    }

    private func showHoverPreview() {
        guard !appGroup.windows.isEmpty else { return }
        
        closePopoverWorkItem?.cancel()
        closePopoverWorkItem = nil

        thumbnailRequestTask?.cancel()
        thumbnailRequestTask = Task { @MainActor [weak self] in
            guard let self else { return }
            guard !Task.isCancelled else { return }

            let thumbnailSize = self.settings.thumbnailSize
            let windows = self.appGroup.windows

            var items: [WindowThumbnailItem] = []
            for window in windows {
                if let cgWindowID = window.cgWindowID {
                    let thumbnail = await self.thumbnailProvider(cgWindowID)
                    let title = !window.title.isEmpty ? window.title : window.appName

                    items.append(WindowThumbnailItem(
                        windowID: cgWindowID,
                        thumbnail: thumbnail,
                        title: title,
                        activationHandler: { [weak self] in
                            self?.windowActivationHandler(window)
                        },
                        peekHandler: { [weak self] in
                            self?.windowActivationHandler(window)
                        },
                        closeHandler: { [weak self] in
                            guard let self = self,
                                  let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == window.pid }),
                                  let elem = TaskButtonView.resolveWindowElement(for: window, application: app, accessibilityService: self.accessibilityService) else { return }
                            self.accessibilityService.close(element: elem)
                        },
                        minimizeHandler: { [weak self] in
                            guard let self = self,
                                  let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == window.pid }),
                                  let elem = TaskButtonView.resolveWindowElement(for: window, application: app, accessibilityService: self.accessibilityService) else { return }
                            self.accessibilityService.minimize(element: elem)
                        },
                        zoomHandler: { [weak self] in
                            guard let self = self,
                                  let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == window.pid }),
                                  let elem = TaskButtonView.resolveWindowElement(for: window, application: app, accessibilityService: self.accessibilityService) else { return }
                            self.accessibilityService.toggleFullScreen(element: elem)
                        }
                    ))
                }
            }

            if !Task.isCancelled && !items.isEmpty {
                self.popover.show(
                    items: items,
                    screenRecordingMissing: self.thumbnailService?.isScreenRecordingGranted == false,
                    relativeTo: self
                )
            }
        }
    }

    private func cancelHoverPreview() {
        hoverWorkItem?.cancel()
        hoverWorkItem = nil
        thumbnailRequestTask?.cancel()
        thumbnailRequestTask = nil
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let popoverWindow = self.popover.contentViewController?.view.window,
               NSMouseInRect(NSEvent.mouseLocation, popoverWindow.frame, false) {
                // Mouse moved into the popover, keep it open and start monitoring!
                self.monitorMouseLeavingPopover()
            } else {
                self.popover.close()
            }
        }
        closePopoverWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    private func monitorMouseLeavingPopover() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard self.popover.isShown else { return }
            
            if let popoverWindow = self.popover.contentViewController?.view.window {
                let mouseLoc = NSEvent.mouseLocation
                let buttonScreenRect = self.window?.convertToScreen(self.convert(self.bounds, to: nil)) ?? NSRect.zero
                
                let inPopover = NSMouseInRect(mouseLoc, popoverWindow.frame, false)
                let inButton = NSMouseInRect(mouseLoc, buttonScreenRect, false)
                
                if !inPopover && !inButton {
                    self.popover.close()
                } else {
                    self.monitorMouseLeavingPopover()
                }
            }
        }
        closePopoverWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = makeContextMenu()
        let localLocation = convert(event.locationInWindow, from: nil)
        let point = NSPoint(x: localLocation.x, y: bounds.maxY + 4)
        menu.popUp(positioning: nil, at: point, in: self)
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier

        for window in appGroup.windows {
            let title = !window.title.isEmpty ? window.title : window.appName
            let item = NSMenuItem(title: title, action: #selector(activateGroupWindow(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = window
            item.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
            item.image?.size = NSSize(width: 14, height: 14)
            menu.addItem(item)
        }

        if !appGroup.windows.isEmpty {
            menu.addItem(.separator())
        }

        let newWindowItem = NSMenuItem(title: "New Window", action: #selector(openGroupNewWindow(_:)), keyEquivalent: "")
        newWindowItem.target = self
        menu.addItem(newWindowItem)
        
        menu.addItem(.separator())

        let closeAllItem = NSMenuItem(title: "Close All", action: #selector(closeGroupWindows(_:)), keyEquivalent: "")
        closeAllItem.target = self
        menu.addItem(closeAllItem)
        
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitGroupApplication(_:)), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func activateGroupWindow(_ sender: NSMenuItem) {
        guard let window = sender.representedObject as? WindowInfo else { return }
        windowActivationHandler(window)
    }

    @objc private func openGroupNewWindow(_ sender: NSMenuItem) {
        guard let pid = appGroup.windows.first?.pid,
              let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }),
              let url = app.bundleURL else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
    }

    @objc private func closeGroupWindows(_ sender: NSMenuItem) {
        guard let pid = appGroup.windows.first?.pid,
              let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) else { return }
              
        for window in appGroup.windows {
            if let elem = TaskButtonView.resolveWindowElement(for: window, application: app, accessibilityService: accessibilityService) {
                accessibilityService.close(element: elem)
            }
        }
    }

    @objc private func quitGroupApplication(_ sender: NSMenuItem) {
        guard let pid = appGroup.windows.first?.pid,
              let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) else { return }
        app.terminate()
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = convert(event.locationInWindow, from: nil)
        didBeginDraggingSession = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard settings.dragReorder, let dragConfiguration, let mouseDownLocation else {
            return
        }

        let currentLocation = convert(event.locationInWindow, from: nil)
        let distance = hypot(currentLocation.x - mouseDownLocation.x, currentLocation.y - mouseDownLocation.y)
        guard distance >= 3,
              let pasteboardItem = TaskButtonView.makePasteboardItem(for: dragConfiguration.payload) else {
            return
        }

        didBeginDraggingSession = true
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(bounds, contents: draggingPreviewImage())
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            mouseDownLocation = nil
            didBeginDraggingSession = false
        }

        guard !didBeginDraggingSession else {
            return
        }

        settings.taskbarMode.strategy.mouseUp(
            appGroup: appGroup,
            popover: popover,
            activationHandler: activationHandler,
            showHoverPreview: showHoverPreview
        )
    }

    private func configureSubviews() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.drawsBackground = false
        titleLabel.usesSingleLineMode = true
        titleLabel.maximumNumberOfLines = 1
        titleLabel.cell?.truncatesLastVisibleLine = true
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.lineBreakMode = .byTruncatingTail

        statusIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        statusIndicatorView.wantsLayer = true
        statusIndicatorView.layer?.cornerRadius = 1.5
        statusIndicatorView.isHidden = true

        windowsRunningIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        windowsRunningIndicatorView.wantsLayer = true
        windowsRunningIndicatorView.layer?.cornerRadius = 1.5
        windowsRunningIndicatorView.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        windowsRunningIndicatorView.isHidden = true

        activityBadgeView.translatesAutoresizingMaskIntoConstraints = false
        activityBadgeView.material = .toolTip
        activityBadgeView.blendingMode = .withinWindow
        activityBadgeView.state = .active
        activityBadgeView.wantsLayer = true
        activityBadgeView.layer?.cornerRadius = 5
        activityBadgeView.layer?.masksToBounds = true
        activityBadgeView.isHidden = true

        activityLabel.translatesAutoresizingMaskIntoConstraints = false
        activityLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .semibold)
        activityLabel.textColor = .secondaryLabelColor

        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.wantsLayer = true
        badgeView.layer?.backgroundColor = NSColor.systemRed.cgColor
        badgeView.layer?.cornerRadius = 8

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        badgeLabel.textColor = .white
        badgeLabel.alignment = .center

        progressTrackView.translatesAutoresizingMaskIntoConstraints = false
        progressTrackView.wantsLayer = true
        progressTrackView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        progressTrackView.layer?.cornerRadius = 1
        progressTrackView.isHidden = true

        progressFillView.translatesAutoresizingMaskIntoConstraints = false
        progressFillView.wantsLayer = true
        progressFillView.layer?.backgroundColor = NSColor.systemGreen.cgColor
        progressFillView.layer?.cornerRadius = 1

        dropIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        dropIndicatorView.wantsLayer = true
        dropIndicatorView.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        dropIndicatorView.layer?.cornerRadius = 1
        dropIndicatorView.isHidden = true
        
        macRunningIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        macRunningIndicatorView.wantsLayer = true
        macRunningIndicatorView.layer?.cornerRadius = 2
        macRunningIndicatorView.isHidden = true

        addSubview(statusIndicatorView)
        addSubview(windowsRunningIndicatorView)
        addSubview(macRunningIndicatorView)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(activityBadgeView)
        activityBadgeView.addSubview(activityLabel)
        addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        addSubview(progressTrackView)
        progressTrackView.addSubview(progressFillView)
        addSubview(dropIndicatorView)
        addSubview(dotsStackView)
        dotsStackView.translatesAutoresizingMaskIntoConstraints = false
        dotsStackView.orientation = .horizontal
        dotsStackView.spacing = 2
        dotsStackView.alignment = .centerY
        
        for _ in 0..<3 {
            let dot = NSView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.wantsLayer = true
            dot.layer?.backgroundColor = NSColor.labelColor.cgColor
            dot.layer?.cornerRadius = 2
            dot.isHidden = true
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 4),
                dot.heightAnchor.constraint(equalToConstant: 4)
            ])
            dotsStackView.addArrangedSubview(dot)
        }

        let progressWidthConstraint = progressFillView.widthAnchor.constraint(equalToConstant: 0)
        self.progressWidthConstraint = progressWidthConstraint
        let dropIndicatorLeadingConstraint = dropIndicatorView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let dropIndicatorTrailingConstraint = dropIndicatorView.trailingAnchor.constraint(equalTo: trailingAnchor)
        self.dropIndicatorLeadingConstraint = dropIndicatorLeadingConstraint
        self.dropIndicatorTrailingConstraint = dropIndicatorTrailingConstraint

        let titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8)
        let titleTrailingConstraint = titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        self.titleLeadingConstraint = titleLeadingConstraint
        self.titleTrailingConstraint = titleTrailingConstraint
        let windowsIconCenterConstraint = iconView.centerXAnchor.constraint(equalTo: centerXAnchor)
        windowsIconCenterConstraint.priority = .defaultHigh
        self.windowsIconCenterConstraint = windowsIconCenterConstraint

        let maxWidthConstraint = widthAnchor.constraint(equalToConstant: 40)
        self.maxWidthConstraint = maxWidthConstraint

        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            maxWidthConstraint,
            dotsStackView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            dotsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            heightAnchor.constraint(equalToConstant: 32),

            statusIndicatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            statusIndicatorView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            statusIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            statusIndicatorView.widthAnchor.constraint(equalToConstant: 3),
            windowsRunningIndicatorView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            windowsRunningIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            windowsRunningIndicatorView.widthAnchor.constraint(equalToConstant: 12),
            windowsRunningIndicatorView.heightAnchor.constraint(equalToConstant: 3),
            
            macRunningIndicatorView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            macRunningIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            macRunningIndicatorView.widthAnchor.constraint(equalToConstant: 4),
            macRunningIndicatorView.heightAnchor.constraint(equalToConstant: 4),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLeadingConstraint,
            titleTrailingConstraint,
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            activityBadgeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            activityBadgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            activityBadgeView.topAnchor.constraint(equalTo: topAnchor, constant: 4),

            activityLabel.leadingAnchor.constraint(equalTo: activityBadgeView.leadingAnchor, constant: 5),
            activityLabel.trailingAnchor.constraint(equalTo: activityBadgeView.trailingAnchor, constant: -5),
            activityLabel.topAnchor.constraint(equalTo: activityBadgeView.topAnchor, constant: 2),
            activityLabel.bottomAnchor.constraint(equalTo: activityBadgeView.bottomAnchor, constant: -2),

            badgeView.centerYAnchor.constraint(equalTo: iconView.topAnchor, constant: 4),
            badgeView.centerXAnchor.constraint(equalTo: iconView.trailingAnchor, constant: -4),
            badgeView.heightAnchor.constraint(equalToConstant: 16),
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),

            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 4),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -4),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            progressTrackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            progressTrackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            progressTrackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            progressTrackView.heightAnchor.constraint(equalToConstant: 2),

            progressFillView.leadingAnchor.constraint(equalTo: progressTrackView.leadingAnchor),
            progressFillView.topAnchor.constraint(equalTo: progressTrackView.topAnchor),
            progressFillView.bottomAnchor.constraint(equalTo: progressTrackView.bottomAnchor),
            progressWidthConstraint,

            dropIndicatorView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            dropIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            dropIndicatorView.widthAnchor.constraint(equalToConstant: 3)
        ])
    }

    func widthPlanItem(usesAdaptiveWidth: Bool) -> TaskbarWidthPlanItem {
        let preferred = min(TaskButtonView.maximumTaskButtonWidth, TaskButtonView.preferredWidth(
            title: appGroup.appName,
            font: titleLabel.font ?? NSFont.systemFont(ofSize: settings.titleFontSize),
            maxWidth: settings.maxTaskWidth,
            taskbarHeight: settings.taskbarHeight,
            showsTitles: settings.showTitles,
            showsPluginActionButton: false,
            isAgentWindow: false
        ))
        return TaskbarWidthPlanItem(
            preferredWidth: usesAdaptiveWidth ? preferred : preferred,
            minimumWidth: settings.showTitles ? TaskButtonView.minimumTaskWidth : settings.taskbarHeight + 8
        )
    }

    func setWidthMode(usesAdaptiveWidth: Bool, widthCap: CGFloat?) {
        self.usesAdaptiveWidth = usesAdaptiveWidth
        self.widthCap = widthCap
        updateAppearance()
    }

    private func updateAppearance() {
        if let icon = appGroup.icon {
            iconView.image = hasBadge ? icon.withBadgeDot() : icon
        } else {
            iconView.image = nil
        }
        badgeLabel.stringValue = "\(appGroup.windowCount)"
        badgeView.isHidden = appGroup.windowCount <= 1 || !settings.showWindowCountBadges
        toolTip = resolvedToolTip()
        
        let title = appGroup.appName
        titleLabel.stringValue = title
        titleLabel.textColor = isActive ? .controlAccentColor : .labelColor
        titleLabel.font = NSFont.systemFont(ofSize: settings.titleFontSize)
        
        let preferred = min(TaskButtonView.maximumTaskButtonWidth, TaskButtonView.preferredWidth(
            title: title,
            font: titleLabel.font ?? NSFont.systemFont(ofSize: settings.titleFontSize),
            maxWidth: settings.maxTaskWidth,
            taskbarHeight: settings.taskbarHeight,
            showsTitles: true,
            showsPluginActionButton: false,
            isAgentWindow: false
        ))
        
        settings.taskbarMode.strategy.configureAppearance(
            appGroup: appGroup, 
            titleLabel: titleLabel, 
            titleLeadingConstraint: titleLeadingConstraint, 
            titleTrailingConstraint: titleTrailingConstraint, 
            windowsIconCenterConstraint: windowsIconCenterConstraint, 
            maxWidthConstraint: maxWidthConstraint, 
            settings: settings, 
            preferredWidth: preferred, 
            widthCap: widthCap
        )
        
        updateStatusIndicator()
        updateActivityBadge()
        updateProgressIndicator()
        updateDots()
        updateBackgroundColor()
    }

    func update(
        appGroup: AppGroup,
        hasBadge: Bool,
        runtimeState: AppRuntimeState,
        showsActivityOverlay: Bool,
        isActive: Bool
    ) {
        self.appGroup = appGroup
        self.hasBadge = hasBadge
        self.runtimeState = runtimeState
        self.showsActivityOverlay = showsActivityOverlay
        self.isActive = isActive
        updateAppearance()
        invalidateIntrinsicContentSize()
    }

    private func updateBackgroundColor() {
        windowsRunningIndicatorView.layer?.backgroundColor = (isActive ? NSColor.controlAccentColor : NSColor.secondaryLabelColor).cgColor
        windowsRunningIndicatorView.layer?.setAffineTransform(
            CGAffineTransform(scaleX: isActive ? 1.8 : 1, y: 1)
        )
        macRunningIndicatorView.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.8).cgColor
        
        settings.taskbarMode.strategy.configureBackgroundColor(
            layer: layer, 
            windowsRunningIndicatorView: windowsRunningIndicatorView, 
            macRunningIndicatorView: macRunningIndicatorView, 
            isActive: isActive, 
            needsAttention: runtimeState.needsAttention, 
            isHovered: isHovered, 
            appGroupWindowCount: appGroup.windowCount
        )
    }

    private func draggingPreviewImage() -> NSImage {
        let fallback = NSImage(size: bounds.size)

        guard
            bounds.width > 0,
            bounds.height > 0,
            let bitmap = bitmapImageRepForCachingDisplay(in: bounds)
        else {
            return fallback
        }

        cacheDisplay(in: bounds, to: bitmap)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmap)
        return image
    }

    private func draggingEdge(for draggingInfo: NSDraggingInfo) -> DeskBarDropEdge {
        let location = convert(draggingInfo.draggingLocation, from: nil)
        return location.x < bounds.midX ? .leading : .trailing
    }

    private func updateDropIndicator(_ edge: DeskBarDropEdge?) {
        guard let edge else {
            dropIndicatorView.isHidden = true
            dropIndicatorLeadingConstraint?.isActive = false
            dropIndicatorTrailingConstraint?.isActive = false
            return
        }

        dropIndicatorLeadingConstraint?.isActive = edge == .leading
        dropIndicatorTrailingConstraint?.isActive = edge == .trailing
        dropIndicatorView.isHidden = false
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        settings.dragReorder && dragConfiguration != nil ? .move : []
    }

    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        true
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        mouseDownLocation = nil
        didBeginDraggingSession = false
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        draggingUpdated(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard
            settings.dragReorder,
            let dragConfiguration,
            let payload = TaskButtonView.decodeDragPayload(from: sender.draggingPasteboard)
        else {
            updateDropIndicator(nil)
            return []
        }

        let edge = draggingEdge(for: sender)
        guard dragConfiguration.validateDrop(payload, edge) else {
            updateDropIndicator(nil)
            return []
        }

        updateDropIndicator(edge)
        return .move
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        updateDropIndicator(nil)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        settings.dragReorder && dragConfiguration != nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer {
            updateDropIndicator(nil)
        }

        guard
            settings.dragReorder,
            let dragConfiguration,
            let payload = TaskButtonView.decodeDragPayload(from: sender.draggingPasteboard)
        else {
            return false
        }

        let edge = draggingEdge(for: sender)
        guard dragConfiguration.validateDrop(payload, edge) else {
            return false
        }

        return dragConfiguration.acceptDrop(payload, edge)
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        updateDropIndicator(nil)
    }

    private func resolvedToolTip() -> String {
        var lines = ["\(appGroup.appName) (\(appGroup.windowCount) windows)"]

        if runtimeState.isLaunching {
            lines.append("Launching")
        }

        if let progressFraction = runtimeState.normalizedProgressFraction {
            lines.append("Progress: \(Int((progressFraction * 100).rounded()))%")
        }

        if let activitySummary = runtimeState.activitySummary {
            lines.append(activitySummary)
        }

        return lines.joined(separator: "\n")
    }

    private func updateStatusIndicator() {
        let isVisible = runtimeState.needsAttention || runtimeState.isLaunching
        statusIndicatorView.isHidden = !isVisible

        guard isVisible else {
            statusIndicatorView.layer?.removeAnimation(forKey: "deskbar.attention")
            return
        }

        let color = runtimeState.needsAttention ? NSColor.systemOrange : NSColor.systemBlue
        statusIndicatorView.layer?.backgroundColor = color.cgColor

        if runtimeState.needsAttention {
            if statusIndicatorView.layer?.animation(forKey: "deskbar.attention") == nil {
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 1
                animation.toValue = 0.25
                animation.duration = 0.55
                animation.autoreverses = true
                animation.repeatCount = .infinity
                statusIndicatorView.layer?.add(animation, forKey: "deskbar.attention")
            }
        } else {
            statusIndicatorView.layer?.removeAnimation(forKey: "deskbar.attention")
        }
    }

    private func updateActivityBadge() {
        guard showsActivityOverlay, let activitySummary = runtimeState.activitySummary else {
            activityBadgeView.isHidden = true
            return
        }

        activityLabel.stringValue = activitySummary
        activityBadgeView.isHidden = false
    }

    private func updateProgressIndicator() {
        guard let progressFraction = runtimeState.normalizedProgressFraction else {
            progressTrackView.isHidden = true
            return
        }

        progressTrackView.isHidden = false
        progressFillView.layer?.backgroundColor = progressFraction >= 1 ? NSColor.systemBlue.cgColor : NSColor.systemGreen.cgColor
        updateProgressWidth()
    }
    
    private func updateDots() {
        let count = min(appGroup.windowCount, 3)
        for (index, dot) in dotsStackView.arrangedSubviews.enumerated() {
            dot.isHidden = index >= count
        }
    }

    private func updateProgressWidth() {
        guard let progressFraction = runtimeState.normalizedProgressFraction else {
            progressWidthConstraint?.constant = 0
            return
        }

        let trackWidth = max(progressTrackView.bounds.width, bounds.width - 12)
        progressWidthConstraint?.constant = max(2, trackWidth * progressFraction)
    }
}
