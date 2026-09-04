import AppKit

final class SearchButtonView: NSView {
    private let iconView = NSImageView()
    private var trackingAreaRef: NSTrackingArea?
    private var isHovered = false {
        didSet {
            updateBackgroundColor()
        }
    }

    init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 8
        toolTip = "Search (Spotlight)"

        configureSubviews()
        updateBackgroundColor()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 36, height: 32)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingAreaRef = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingAreaRef)
        self.trackingAreaRef = trackingAreaRef
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        IconClickFeedback.show(on: iconView)
        openSpotlight()
    }

    private func configureSubviews() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.wantsLayer = true
        iconView.imageScaling = .scaleProportionallyUpOrDown
        
        let image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Search")
        image?.isTemplate = true
        iconView.image = image

        addSubview(iconView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 36),
            heightAnchor.constraint(equalToConstant: 32),

            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18), // Slightly smaller than apps icon
            iconView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func openSpotlight() {
        StartMenuWindowController.shared.toggle(mode: .search, triggerView: self)
    }

    private func updateBackgroundColor() {
        layer?.backgroundColor = (
            isHovered
                ? NSColor.white.withAlphaComponent(0.1)
                : NSColor.clear
        ).cgColor
    }
}
