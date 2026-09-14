import AppKit

final class ConnectivityTrayView: NSStackView {
    private let quickSettingsButton = TrayIconButton(
        symbolName: "slider.horizontal.3",
        accessibilityLabel: "Quick Settings"
    )
    private let settings: TaskbarSettings
    private let manager = QuickSettingsManager.shared
    private lazy var quickSettingsPanel = QuickSettingsFlyoutPanel(settings: settings, manager: manager)

    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init(frame: .zero)
        orientation = .horizontal
        alignment = .centerY
        spacing = 4

        quickSettingsButton.button.target = self
        quickSettingsButton.button.action = #selector(toggleQuickSettings)
        quickSettingsButton.toolTip = "Quick Settings"

        addArrangedSubview(quickSettingsButton)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat {
        return 24 + 8
    }

    @objc private func toggleQuickSettings() {
        if quickSettingsPanel.isVisible {
            quickSettingsPanel.close()
            return
        }
        guard let window = quickSettingsButton.window else { return }
        let btnScreenRect = window.convertToScreen(
            quickSettingsButton.convert(quickSettingsButton.bounds, to: nil)
        )
        let panelSize = quickSettingsPanel.frame.size
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let visibleFrame = screen.visibleFrame

        var originX = btnScreenRect.maxX - panelSize.width
        let originY = btnScreenRect.maxY + 8
        originX = max(visibleFrame.minX + 8, min(originX, visibleFrame.maxX - panelSize.width - 8))

        quickSettingsPanel.setFrameOrigin(NSPoint(x: originX, y: originY))
        quickSettingsPanel.refreshOnOpen()
        quickSettingsPanel.makeKeyAndOrderFront(nil)
    }
}
