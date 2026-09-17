import AppKit

final class ConnectivityTrayView: NSStackView {
    private let quickSettingsButton = CalendarTrayButton()
    private let settings: TaskbarSettings
    private let manager = QuickSettingsManager.shared
    
    private var popover: NSPopover?

    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init(frame: .zero)
        orientation = .horizontal
        alignment = .centerY
        spacing = 4

        quickSettingsButton.target = self
        quickSettingsButton.action = #selector(toggleQuickSettings)
        quickSettingsButton.toolTip = "Quick Settings"

        addArrangedSubview(quickSettingsButton)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat {
        return quickSettingsButton.fittingSize.width + 8
    }

    @objc private func toggleQuickSettings() {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }
        
        let newPopover = NSPopover()
        newPopover.behavior = .transient
        newPopover.contentViewController = QuickSettingsViewController(settings: settings, manager: manager)
        newPopover.show(relativeTo: quickSettingsButton.bounds, of: quickSettingsButton, preferredEdge: .maxY)
        self.popover = newPopover
    }
}
