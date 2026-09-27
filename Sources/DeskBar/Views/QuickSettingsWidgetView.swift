import AppKit

final class QuickSettingsWidgetView: TrayIconButton {
    private let settings: TaskbarSettings
    private let manager = QuickSettingsManager.shared
    private var flyout: BorderlessFlyout?

    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init(symbolName: "switch.2", accessibilityLabel: "Control Center")
        button.target = self
        button.action = #selector(toggle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func toggle() {
        if let popover = flyout, popover.isShown {
            popover.performClose(nil)
            return
        }
        
        let newPopover = BorderlessFlyout()
        newPopover.onDismiss = { [weak self] in
            self?.flyout = nil
        }
        let vc = QuickSettingsViewController(settings: settings, manager: manager)
        newPopover.show(contentViewController: vc, relativeTo: button.bounds, of: button)
        self.flyout = newPopover
    }
}
