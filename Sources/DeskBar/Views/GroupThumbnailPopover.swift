import AppKit
import Combine

struct WindowThumbnailItem {
    let windowID: CGWindowID
    let thumbnail: NSImage
    let title: String
    let activationHandler: () -> Void
    let peekHandler: () -> Void
    let closeHandler: () -> Void
    let minimizeHandler: () -> Void
    let zoomHandler: () -> Void
}

final class GroupThumbnailPopover: NSPopover, NSPopoverDelegate {
    private let popoverEdge: NSRectEdge = .maxY
    private let thumbnailViewController: GroupThumbnailPopoverViewController
    private var cancellables = Set<AnyCancellable>()
    private var localMouseDownMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var localKeyboardMonitor: Any?
    private var globalKeyboardMonitor: Any?

    init(settings: TaskbarSettings) {
        thumbnailViewController = GroupThumbnailPopoverViewController(
            thumbnailSize: settings.thumbnailSize
        )
        super.init()
        behavior = .applicationDefined
        animates = true
        contentViewController = thumbnailViewController
        delegate = self

        settings.$thumbnailSize
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.thumbnailViewController.updateThumbnailSize(value)
            }
            .store(in: &cancellables)
    }

    deinit {
        removeDismissalMonitors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func close() {
        removeDismissalMonitors()
        super.close()
    }

    func show(items: [WindowThumbnailItem], relativeTo view: NSView) {
        guard view.window != nil else {
            return
        }
        guard !items.isEmpty else { return }

        thumbnailViewController.show(items: items) { [weak self] in
            self?.close()
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            self.contentViewController?.view.alphaValue = 0
            show(relativeTo: view.bounds, of: view, preferredEdge: popoverEdge)
            self.contentViewController?.view.animator().alphaValue = 1
        }, completionHandler: nil)
        
        installDismissalMonitors()
    }

    func popoverDidClose(_ notification: Notification) {
        removeDismissalMonitors()
    }

    private func installDismissalMonitors() {
        guard localMouseDownMonitor == nil, globalMouseDownMonitor == nil else {
            return
        }

        let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        let keyboardEventMask: NSEvent.EventTypeMask = [.keyDown, .flagsChanged]

        // If the workspace change was caused by a peek, don't close.
        // However, we don't know easily. Let's just remove the workspaceActivateObserver and appResignActiveObserver
        // because we WANT to stay open until mouse click or mouse out.
        // Actually, if we just check if the mouse is still inside the popover bounds?
        // Let's just rely on global/local mouse down and keyboard to close it!

        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.closeUnlessEventTargetsPopover(event)
            return event
        }

        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] _ in
            DispatchQueue.main.async {
                self?.close()
            }
        }

        localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: keyboardEventMask) { [weak self] event in
            self?.close()
            return event
        }

        globalKeyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: keyboardEventMask) { [weak self] _ in
            DispatchQueue.main.async {
                self?.close()
            }
        }
    }

    private func closeUnlessEventTargetsPopover(_ event: NSEvent) {
        guard isShown else { return }
        guard event.window !== contentViewController?.view.window else { return }
        close()
    }

    private func removeDismissalMonitors() {
        if let localMouseDownMonitor {
            NSEvent.removeMonitor(localMouseDownMonitor)
            self.localMouseDownMonitor = nil
        }
        if let globalMouseDownMonitor {
            NSEvent.removeMonitor(globalMouseDownMonitor)
            self.globalMouseDownMonitor = nil
        }
        if let localKeyboardMonitor {
            NSEvent.removeMonitor(localKeyboardMonitor)
            self.localKeyboardMonitor = nil
        }
        if let globalKeyboardMonitor {
            NSEvent.removeMonitor(globalKeyboardMonitor)
            self.globalKeyboardMonitor = nil
        }
    }
}

private final class GroupThumbnailPopoverViewController: NSViewController {
    private var thumbnailSize: CGFloat
    private let stackView = NSStackView()
    private var dismissHandler: (() -> Void)?

    init(thumbnailSize: CGFloat) {
        self.thumbnailSize = thumbnailSize
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 12
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        view = stackView
    }

    func show(items: [WindowThumbnailItem], dismissHandler: @escaping () -> Void) {
        self.dismissHandler = dismissHandler
        
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        var totalWidth: CGFloat = 24 // insets
        var maxHeight: CGFloat = 0
        
        for item in items {
            let container = ClickableThumbnailView(
                item: item,
                size: thumbnailSize,
                dismissHandler: { [weak self] in self?.dismissHandler?() }
            )
            stackView.addArrangedSubview(container)
            
            totalWidth += container.fittingSize.width
            maxHeight = max(maxHeight, container.fittingSize.height)
        }
        totalWidth += CGFloat(items.count - 1) * stackView.spacing
        maxHeight += 24 // insets
        
        preferredContentSize = NSSize(width: totalWidth, height: maxHeight)
        view.setFrameSize(preferredContentSize)
    }

    func updateThumbnailSize(_ thumbnailSize: CGFloat) {
        self.thumbnailSize = thumbnailSize
        // Can optionally reload items if we keep a reference, but fine for now
    }
}

private final class ClickableThumbnailView: NSView {
    private let item: WindowThumbnailItem
    private let dismissHandler: () -> Void
    private var isHovered = false
    private var peekWorkItem: DispatchWorkItem?
    
    private let actionBar = NSVisualEffectView()
    
    init(item: WindowThumbnailItem, size: CGFloat, dismissHandler: @escaping () -> Void) {
        self.item = item
        self.dismissHandler = dismissHandler
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.cornerRadius = 6
        
        let titleLabel = NSTextField(labelWithString: item.title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.maximumNumberOfLines = 2
        titleLabel.alignment = .center
        
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.image = item.thumbnail
        
        let resolvedSize = resolvedSize(for: item.thumbnail, boundingSize: size)
        
        actionBar.material = .popover
        actionBar.blendingMode = .withinWindow
        actionBar.state = .active
        actionBar.wantsLayer = true
        actionBar.layer?.cornerRadius = 6
        actionBar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.alphaValue = 0
        
        let closeButton = NSButton(image: NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)!, target: self, action: #selector(handleClose))
        closeButton.isBordered = false
        closeButton.toolTip = "Close"
        
        let minimizeButton = NSButton(image: NSImage(systemSymbolName: "minus", accessibilityDescription: nil)!, target: self, action: #selector(handleMinimize))
        minimizeButton.isBordered = false
        minimizeButton.toolTip = "Minimize"
        
        let zoomButton = NSButton(image: NSImage(systemSymbolName: "plus", accessibilityDescription: nil)!, target: self, action: #selector(handleZoom))
        zoomButton.isBordered = false
        zoomButton.toolTip = "Zoom"
        
        let actionStack = NSStackView(views: [closeButton, minimizeButton, zoomButton])
        actionStack.orientation = .horizontal
        actionStack.spacing = 8
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        
        actionBar.addSubview(actionStack)
        
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(actionBar)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            imageView.widthAnchor.constraint(equalToConstant: resolvedSize.width),
            imageView.heightAnchor.constraint(equalToConstant: resolvedSize.height),
            widthAnchor.constraint(equalToConstant: max(resolvedSize.width + 8, 100)),
            
            actionStack.centerXAnchor.constraint(equalTo: actionBar.centerXAnchor),
            actionStack.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor),
            
            actionBar.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            actionBar.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            actionBar.widthAnchor.constraint(equalToConstant: 100),
            actionBar.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        let trackingArea = NSTrackingArea(rect: NSRect(origin: .zero, size: NSSize(width: 1000, height: 1000)), options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; actionBar.animator().alphaValue = 1 }
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.item.peekHandler()
        }
        peekWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        layer?.backgroundColor = .clear
        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; actionBar.animator().alphaValue = 0 }
        
        peekWorkItem?.cancel()
        peekWorkItem = nil
    }
    
    override func mouseDown(with event: NSEvent) {
        item.activationHandler()
        dismissHandler()
    }
    
    @objc private func handleClose() {
        item.closeHandler()
        dismissHandler()
    }
    
    @objc private func handleMinimize() {
        item.minimizeHandler()
        dismissHandler()
    }
    
    @objc private func handleZoom() {
        item.zoomHandler()
        dismissHandler()
    }
    
    private func resolvedSize(for image: NSImage, boundingSize: CGFloat) -> NSSize {
        let aspectRatio = image.size.width / max(image.size.height, 1)
        if aspectRatio >= 1 {
            return NSSize(width: boundingSize, height: boundingSize / aspectRatio)
        } else {
            return NSSize(width: boundingSize * aspectRatio, height: boundingSize)
        }
    }
}
