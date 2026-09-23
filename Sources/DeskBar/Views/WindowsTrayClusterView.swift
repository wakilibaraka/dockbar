import AppKit

final class WindowsTrayClusterView: NSView {
    let stack = NSStackView()
    private let mediaTransport = MediaTransportView()
    private let chevronButton = NSButton()
    
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 32))
        
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.heightAnchor.constraint(equalTo: heightAnchor)
        ])
        
        // Chevron
        chevronButton.bezelStyle = .texturedRounded
        chevronButton.isBordered = false
        chevronButton.imagePosition = .imageOnly
        chevronButton.image = NSImage(systemSymbolName: "chevron.up", accessibilityDescription: "Show hidden icons")
        chevronButton.translatesAutoresizingMaskIntoConstraints = false
        chevronButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        stack.addArrangedSubview(chevronButton)
        stack.addArrangedSubview(mediaTransport)
        
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.2).cgColor
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func addWidget(_ view: NSView) {
        stack.addArrangedSubview(view)
    }
    
    func removeWidget(_ view: NSView) {
        stack.removeArrangedSubview(view)
        view.removeFromSuperview()
    }
    
    func baseWidth() -> CGFloat {
        // Paddings + chevron + spacing + media
        return 8 + 24 + 4 + mediaTransport.preferredContentWidth() + 8
    }
}
