import AppKit

final class CalendarWidgetView: NSView {
    private let calendarButton = CalendarTrayButton()

    init() {
        super.init(frame: .zero)
        addSubview(calendarButton)
        calendarButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendarButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarButton.topAnchor.constraint(equalTo: topAnchor),
            calendarButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat {
        calendarButton.fittingSize.width + 8
    }
}

final class QuickSettingsWidgetView: NSView {
    private let button = NSButton()
    private let settings: TaskbarSettings
    private let manager = QuickSettingsManager.shared
    private var popover: NSPopover?

    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init(frame: .zero)

        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.image = NSImage(systemSymbolName: "switch.2", accessibilityDescription: "Quick Settings")
        button.imagePosition = .imageOnly
        button.toolTip = "Quick Settings"
        button.target = self
        button.action = #selector(toggleQuickSettings)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat {
        max(button.fittingSize.width, 24) + 8
    }

    @objc private func toggleQuickSettings() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }

        let newPopover = NSPopover()
        newPopover.behavior = .transient
        newPopover.contentViewController = QuickSettingsViewController(settings: settings, manager: manager)
        newPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        popover = newPopover
    }
}
