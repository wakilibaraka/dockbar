import AppKit
import Combine

final class QuickSettingsButtonView: NSView {
    private let settings: TaskbarSettings
    private let manager: QuickSettingsManager
    private let button = NSButton()
    private var flyout: QuickSettingsFlyoutPanel?
    private var outsideClickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(settings: TaskbarSettings, manager: QuickSettingsManager) {
        self.settings = settings
        self.manager = manager
        super.init(frame: .zero)
        setupUI()
        bindSettings()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    deinit {
        if let m = outsideClickMonitor { NSEvent.removeMonitor(m); outsideClickMonitor = nil }
    }
    
    private func setupUI() {
        button.isBordered = false
        button.bezelStyle = .regularSquare
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        button.image = NSImage(systemSymbolName: "switch.2", accessibilityDescription: "Quick Settings")?.withSymbolConfiguration(config)
        button.contentTintColor = NSColor.white.withAlphaComponent(0.8)
        button.target = self
        button.action = #selector(buttonClicked)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAccessibilityLabel("Quick Settings")
        
        addSubview(button)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28),
            widthAnchor.constraint(equalToConstant: 32),
        ])
    }
    
    private func bindSettings() {
        settings.$showQuickSettings
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.isHidden = !show
            }
            .store(in: &cancellables)
    }
    
    @objc private func buttonClicked() {
        if flyout != nil {
            dismissFlyout()
            return
        }
        
        let panel = QuickSettingsFlyoutPanel(settings: settings, manager: manager)
        flyout = panel
        panel.refreshOnOpen()
        
        FlyoutAnchorHelper.position(flyout: panel, relativeTo: self)
        
        panel.makeKeyAndOrderFront(nil)
        
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.dismissFlyout()
            }
        }
    }
    
    private func dismissFlyout() {
        flyout?.close()
        flyout = nil
        if let m = outsideClickMonitor { NSEvent.removeMonitor(m); outsideClickMonitor = nil }
    }
}
