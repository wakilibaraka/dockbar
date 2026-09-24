import AppKit
import Combine

final class ThumbnailPopover: BorderlessFlyout {
    private let popoverEdge: NSRectEdge = .maxY
    private let thumbnailViewController: ThumbnailPopoverViewController
    private var cancellables = Set<AnyCancellable>()
    private var localMouseDownMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var localKeyboardMonitor: Any?
    private var globalKeyboardMonitor: Any?
    private var appResignActiveObserver: NSObjectProtocol?
    private var workspaceActivateObserver: NSObjectProtocol?

    init(settings: TaskbarSettings) {
        thumbnailViewController = ThumbnailPopoverViewController(
            thumbnailSize: settings.thumbnailSize
        )
        super.init()
                        contentViewController = thumbnailViewController
        

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

    func show(thumbnail: NSImage, relativeTo view: NSView, title: String) {
        guard view.window != nil else {
            return
        }

        thumbnailViewController.show(thumbnail: thumbnail, title: title)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            self.contentViewController?.view.alphaValue = 0
            super.show(contentViewController: self.contentViewController!, relativeTo: view.bounds, of: view)
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

        appResignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            self?.close()
        }

        workspaceActivateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.close()
        }
    }

    private func closeUnlessEventTargetsPopover(_ event: NSEvent) {
        guard isShown else {
            return
        }

        guard event.window !== contentViewController?.view.window else {
            return
        }

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

        if let appResignActiveObserver {
            NotificationCenter.default.removeObserver(appResignActiveObserver)
            self.appResignActiveObserver = nil
        }

        if let workspaceActivateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceActivateObserver)
            self.workspaceActivateObserver = nil
        }
    }
}

private final class ThumbnailPopoverViewController: NSViewController {
    private var thumbnailSize: CGFloat
    private let imageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")

    init(thumbnailSize: CGFloat) {
        self.thumbnailSize = thumbnailSize
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let containerView = NSView(frame: NSRect(origin: .zero, size: squareSize))
        containerView.wantsLayer = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.maximumNumberOfLines = 2
        titleLabel.alignment = .center

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter

        containerView.addSubview(titleLabel)
        containerView.addSubview(imageView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        view = containerView
        preferredContentSize = squareSize
    }

    func show(thumbnail: NSImage, title: String) {
        imageView.image = thumbnail
        titleLabel.stringValue = title
        
        var size = resolvedSize(for: thumbnail)
        size.height += 24 // Add space for title
        
        preferredContentSize = size
        view.setFrameSize(preferredContentSize)
    }

    func updateThumbnailSize(_ thumbnailSize: CGFloat) {
        self.thumbnailSize = thumbnailSize

        if let image = imageView.image {
            var size = resolvedSize(for: image)
            size.height += 24
            preferredContentSize = size
        } else {
            preferredContentSize = squareSize
        }
        view.setFrameSize(preferredContentSize)
    }

    private var squareSize: NSSize {
        NSSize(width: thumbnailSize, height: thumbnailSize)
    }

    private func resolvedSize(for image: NSImage) -> NSSize {
        let aspectRatio = image.size.width / max(image.size.height, 1)
        if aspectRatio >= 1 {
            return NSSize(width: thumbnailSize, height: thumbnailSize / aspectRatio)
        } else {
            return NSSize(width: thumbnailSize * aspectRatio, height: thumbnailSize)
        }
    }
}
