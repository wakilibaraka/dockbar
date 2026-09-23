import QuartzCore
import AppKit
import Combine

struct WindowThumbnailItem {
    let windowID: CGWindowID
    let thumbnail: NSImage?
    let title: String
    let activationHandler: () -> Void
    let peekHandler: () -> Void
    let closeHandler: () -> Void
    let minimizeHandler: () -> Void
    let zoomHandler: () -> Void
}

final class GroupThumbnailPopover: BorderlessFlyout {
    private let popoverEdge: NSRectEdge = .maxY
    private let thumbnailViewController: GroupThumbnailPopoverViewController
    private var cancellables = Set<AnyCancellable>()
    
    init(settings: TaskbarSettings) {
        thumbnailViewController = GroupThumbnailPopoverViewController(
            thumbnailSize: settings.thumbnailSize
        )
        super.init()

        settings.$thumbnailSize
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.thumbnailViewController.updateThumbnailSize(value)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(items: [WindowThumbnailItem], screenRecordingMissing: Bool = false, relativeTo view: NSView) {
        guard view.window != nil else {
            return
        }
        guard !items.isEmpty else { return }

        thumbnailViewController.show(items: items, screenRecordingMissing: screenRecordingMissing) { [weak self] in
            self?.performClose(nil)
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)
            self.contentViewController?.view.alphaValue = 0
            show(contentViewController: thumbnailViewController, relativeTo: view.bounds, of: view)
            self.contentViewController?.view.animator().alphaValue = 1
        }, completionHandler: nil)
        
    }

}

private final class GroupThumbnailPopoverViewController: NSViewController {
    private var thumbnailSize: CGFloat
    private let stackView = NSStackView()
    private let thumbnailStack = NSStackView()
    private let permissionButton = NSButton()
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
        stackView.orientation = .vertical
        stackView.alignment = .centerY
        stackView.spacing = 12
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        thumbnailStack.orientation = .horizontal
        thumbnailStack.alignment = .centerY
        thumbnailStack.spacing = 12

        permissionButton.title = "Enable Screen Recording to see previews"
        permissionButton.isBordered = false
        permissionButton.contentTintColor = .secondaryLabelColor
        permissionButton.isHidden = true
        permissionButton.target = self
        permissionButton.action = #selector(openScreenRecordingSettings)
        stackView.addArrangedSubview(permissionButton)
        stackView.addArrangedSubview(thumbnailStack)
        view = stackView
    }

    func show(items: [WindowThumbnailItem], screenRecordingMissing: Bool, dismissHandler: @escaping () -> Void) {
        self.dismissHandler = dismissHandler
        permissionButton.isHidden = !screenRecordingMissing
        
        thumbnailStack.arrangedSubviews.forEach { view in
            thumbnailStack.removeArrangedSubview(view)
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
            thumbnailStack.addArrangedSubview(container)
            
            totalWidth += container.fittingSize.width
            maxHeight = max(maxHeight, container.fittingSize.height)
        }
        totalWidth += CGFloat(items.count - 1) * thumbnailStack.spacing
        maxHeight += 24 // insets
        if screenRecordingMissing {
            maxHeight += permissionButton.fittingSize.height + stackView.spacing
        }
        
        preferredContentSize = NSSize(width: totalWidth, height: maxHeight)
        view.setFrameSize(preferredContentSize)
    }

    @objc private func openScreenRecordingSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
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
    
    private let actionBar = NSView()
    
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

        let resolvedSize = item.thumbnail.map { resolvedSize(for: $0, boundingSize: size) } ?? .zero
        
        actionBar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.wantsLayer = true
        actionBar.alphaValue = 0
        
        func makeTrafficLight(color: NSColor, icon: String, action: Selector) -> NSButton {
            let btn = NSButton(title: "", target: self, action: action)
            btn.isBordered = false
            btn.wantsLayer = true
            btn.layer?.cornerRadius = 6
            btn.layer?.backgroundColor = color.cgColor
            
            let config = NSImage.SymbolConfiguration(pointSize: 7, weight: .bold)
            if let img = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
                // We'll just set it directly to show the dark icon over the color
                let tintImg = NSImage(size: img.size)
                tintImg.lockFocus()
                img.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 0.5)
                tintImg.unlockFocus()
                btn.image = tintImg
            }
            btn.imagePosition = .imageOnly
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 12),
                btn.heightAnchor.constraint(equalToConstant: 12)
            ])
            return btn
        }
        
        let closeButton = makeTrafficLight(color: NSColor(red: 1.0, green: 0.37, blue: 0.34, alpha: 1.0), icon: "xmark", action: #selector(handleClose))
        let minimizeButton = makeTrafficLight(color: NSColor(red: 1.0, green: 0.78, blue: 0.2, alpha: 1.0), icon: "minus", action: #selector(handleMinimize))
        let zoomButton = makeTrafficLight(color: NSColor(red: 0.15, green: 0.79, blue: 0.31, alpha: 1.0), icon: "plus", action: #selector(handleZoom))
        
        let actionStack = NSStackView(views: [closeButton, minimizeButton, zoomButton])
        actionStack.orientation = .horizontal
        actionStack.spacing = 8
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        actionBar.addSubview(actionStack)
        
        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(actionBar)
        
        var constraints: [NSLayoutConstraint] = [
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            widthAnchor.constraint(equalToConstant: max(resolvedSize.width + 8, 100)),
            
            actionStack.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor),
            actionStack.topAnchor.constraint(equalTo: actionBar.topAnchor),
            actionStack.bottomAnchor.constraint(equalTo: actionBar.bottomAnchor),
            actionStack.trailingAnchor.constraint(equalTo: actionBar.trailingAnchor),
            
            actionBar.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            actionBar.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8)
        ]
        if item.thumbnail != nil {
            constraints += [
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
                imageView.widthAnchor.constraint(equalToConstant: resolvedSize.width),
                imageView.heightAnchor.constraint(equalToConstant: resolvedSize.height)
            ]
        } else {
            imageView.isHidden = true
            constraints += [
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
            ]
        }
        NSLayoutConstraint.activate(constraints)
        
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
