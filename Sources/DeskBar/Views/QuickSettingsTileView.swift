import AppKit
import SwiftUI

final class QuickSettingsTileView: NSView {
    private let setting: QuickSetting
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private var flyout: BorderlessFlyout?
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
        layer?.cornerRadius = 6
        layer?.cornerCurve = .continuous
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        
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
        titleLabel.alignment = .left
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.maximumNumberOfLines = 2
        titleLabel.cell?.usesSingleLineMode = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconView)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 96),
            heightAnchor.constraint(equalToConstant: 48),
            
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Accessibility
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(setting.title)
    }
    
    func refresh() {
        let on = setting.isOn
        let isAction = setting.isAction
        let emberColor = NSColor(red: 1.0, green: 0.28, blue: 0.0, alpha: 1.0)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if isAction {
            layer?.backgroundColor = NSColor(white: 0.1, alpha: 0.5).cgColor
        } else {
            layer?.backgroundColor = on
                ? emberColor.cgColor
                : NSColor(white: 0.1, alpha: 0.5).cgColor
        }
        CATransaction.commit()
        
        let fgColor: NSColor = (on && !isAction) ? .white : .labelColor
        iconView.contentTintColor = fgColor
        titleLabel.textColor = fgColor
    }
    
    override func mouseDown(with event: NSEvent) {
        if showFlyoutIfAvailable() {
            return
        }

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

    private func showFlyoutIfAvailable() -> Bool {
        let rootView: AnyView
        switch setting {
        case let speedTest as SpeedTestQuickSetting:
            rootView = AnyView(
                NetworkFlyoutView(
                    monitor: speedTest.throughputMonitor,
                    speedTest: speedTest.controller,
                    onChange: { [weak self] in
                        self?.refresh()
                        self?.onToggle?()
                    }
                )
            )
        case let keyboardLock as KeyboardLockQuickSetting:
            rootView = AnyView(
                KeyboardLockFlyoutView(
                    setting: keyboardLock,
                    onChange: { [weak self] in
                        self?.refresh()
                        self?.onToggle?()
                    }
                )
            )
        default:
            return false
        }

        if let flyout, flyout.isShown {
            flyout.performClose(nil)
            self.flyout = nil
            return true
        }

        let popover = BorderlessFlyout()
        
        popover.show(contentViewController: NSHostingController(rootView: rootView), relativeTo: bounds, of: self)
        flyout = popover
        return true
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if let url = setting.settingsURL {
            NSWorkspace.shared.open(url)
            self.onToggle?() // Close the flyout when opening settings
        }
    }
}
