import AppKit

final class QuickSettingsTileView: NSView {
    private let setting: QuickSetting
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    var onToggle: (() -> Void)?
    
    init(setting: QuickSetting) {
        self.setting = setting
        super.init(frame: .zero)
        setupUI()
        refresh()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.cornerCurve = .continuous
        
        // Icon
        let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        if let custom = setting.customImage {
            iconView.image = custom
        } else {
            let image = NSImage(systemSymbolName: setting.symbolName, accessibilityDescription: setting.title)
            iconView.image = image?.withSymbolConfiguration(config)
        }
        iconView.imageScaling = .scaleProportionallyDown
        iconView.contentTintColor = .labelColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.stringValue = setting.title
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconView)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 72),
            heightAnchor.constraint(equalToConstant: 64),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
        
        // Accessibility
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(setting.title)
    }
    
    func refresh() {
        let on = setting.isOn
        let isAction = setting.isAction
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if isAction {
            layer?.backgroundColor = NSColor.controlTextColor.withAlphaComponent(0.08).cgColor
        } else {
            layer?.backgroundColor = on
                ? NSColor.controlAccentColor.cgColor
                : NSColor.controlTextColor.withAlphaComponent(0.08).cgColor
        }
        CATransaction.commit()
        
        let fgColor: NSColor = (on && !isAction) ? .white : .labelColor
        iconView.contentTintColor = fgColor
        titleLabel.textColor = fgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            layer?.opacity = 0.7
        } completionHandler: {
            self.layer?.opacity = 1.0
            self.setting.toggle()
            self.setting.refreshState()
            self.refresh()
            self.onToggle?()
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if let url = setting.settingsURL {
            NSWorkspace.shared.open(url)
            self.onToggle?() // Close the flyout when opening settings
        }
    }
}
