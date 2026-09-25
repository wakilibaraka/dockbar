import AppKit
import Combine

final class ConnectivityTrayView: NSStackView {
    private let quickSettingsButton = CalendarTrayButton()
    private let settings: TaskbarSettings
    private let manager = QuickSettingsManager.shared
    
    private var flyout: BorderlessFlyout?
    private var win11Constraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()


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
        
        win11Constraint = quickSettingsButton.widthAnchor.constraint(equalToConstant: 32)
        win11Constraint?.isActive = settings.layoutMode == .windows11

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        
        settings.$layoutMode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.win11Constraint?.isActive = mode == .windows11
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }


    func preferredContentWidth() -> CGFloat {
        if settings.layoutMode == .windows11 {
            return 32
        }
        return quickSettingsButton.fittingSize.width
    }


    @objc private func toggleQuickSettings() {
        if let popover = flyout, popover.isShown {
            popover.performClose(nil)
            // flyout = nil is handled by onDismiss
            return
        }
        
        let newPopover = BorderlessFlyout()
        newPopover.onDismiss = { [weak self] in
            self?.flyout = nil
        }
        let vc = QuickSettingsViewController(settings: settings, manager: manager)
        newPopover.show(contentViewController: vc, relativeTo: quickSettingsButton.bounds, of: quickSettingsButton)
        self.flyout = newPopover
    }
}
