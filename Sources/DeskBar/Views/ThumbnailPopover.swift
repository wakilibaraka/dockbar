import AppKit
import Combine

final class ThumbnailPopover: BorderlessFlyout {
    private let popoverEdge: NSRectEdge = .maxY
    private let thumbnailViewController: ThumbnailPopoverViewController
    private var cancellables = Set<AnyCancellable>()
    private var appResignActiveObserver: NSObjectProtocol?
    private var workspaceActivateObserver: NSObjectProtocol?

    init(settings: TaskbarSettings) {
        thumbnailViewController = ThumbnailPopoverViewController(
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

    deinit {
        
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func close() {
        
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
            show(contentViewController: thumbnailViewController, relativeTo: view.bounds, of: view)
            self.contentViewController?.view.animator().alphaValue = 1
        }, completionHandler: nil)
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
