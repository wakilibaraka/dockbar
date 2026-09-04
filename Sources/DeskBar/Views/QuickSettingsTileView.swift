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
        let image = NSImage(systemSymbolName: setting.symbolName, accessibilityDescription: setting.title)
        iconView.image = image?.withSymbolConfiguration(config)
        iconView.imageScaling = .scaleProportionallyDown
        iconView.contentTintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.85)
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
            layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
        } else {
            layer?.backgroundColor = on
                ? NSColor.systemBlue.withAlphaComponent(0.45).cgColor
                : NSColor.white.withAlphaComponent(0.10).cgColor
        }
        CATransaction.commit()
        
        iconView.contentTintColor = on || isAction ? .white : NSColor.white.withAlphaComponent(0.5)
        titleLabel.textColor = on || isAction ? .white : NSColor.white.withAlphaComponent(0.5)
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
}
