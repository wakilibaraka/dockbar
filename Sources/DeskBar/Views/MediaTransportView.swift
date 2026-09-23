import AppKit

final class MediaTransportView: NSView {
    private let prevButton = NSButton()
    private let playPauseButton = NSButton()
    private let nextButton = NSButton()
    
    private static let fixedWidth: CGFloat = 88 // 24*3 + 8*2

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Self.fixedWidth, height: 22))
        
        let stack = NSStackView(views: [prevButton, playPauseButton, nextButton])
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        setupButton(prevButton, icon: "backward.fill", action: #selector(prevTapped))
        setupButton(playPauseButton, icon: "playpause.fill", action: #selector(playPauseTapped))
        setupButton(nextButton, icon: "forward.fill", action: #selector(nextTapped))
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func preferredContentWidth() -> CGFloat { Self.fixedWidth }
    
    private func setupButton(_ button: NSButton, icon: String, action: Selector) {
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        button.target = self
        button.action = action
    }
    
    @objc private func playPauseTapped() { sendMediaKey(16) } // NX_KEYTYPE_PLAY
    @objc private func nextTapped() { sendMediaKey(17) }      // NX_KEYTYPE_NEXT
    @objc private func prevTapped() { sendMediaKey(18) }      // NX_KEYTYPE_PREVIOUS
    
    private func sendMediaKey(_ key: Int32) {
        let loc = NSPoint(x: 0, y: 0)
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: false) else { return }
        
        // Media keys use a different event type and flags
        keyDown.type = CGEventType(rawValue: 14)!
        keyDown.flags = CGEventFlags(rawValue: CGEventFlags.maskNonCoalesced.rawValue)
        let data1 = (key << 16) | (0xA << 8)
        keyDown.setIntegerValueField(.eventSourceUserData, value: Int64(data1))
        keyDown.post(tap: .cghidEventTap)

        keyUp.type = CGEventType(rawValue: 14)!
        keyUp.flags = CGEventFlags(rawValue: CGEventFlags.maskNonCoalesced.rawValue)
        let data2 = (key << 16) | (0xB << 8)
        keyUp.setIntegerValueField(.eventSourceUserData, value: Int64(data2))
        keyUp.post(tap: .cghidEventTap)
    }
}
