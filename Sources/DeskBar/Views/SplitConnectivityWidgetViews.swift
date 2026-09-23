import AppKit
import SwiftUI
import Combine

final class BatteryWidgetView: NSView {
    private static let fixedWidth: CGFloat = 72
    private let button = NSButton()
    private let settings: TaskbarSettings
    private var cancellables = Set<AnyCancellable>()
    private var popover: BorderlessFlyout?

    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init(frame: .zero)
        button.isBordered = false
        button.bezelStyle = .texturedRounded
        button.imagePosition = .imageLeft
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        button.target = self
        button.action = #selector(toggleBattery)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            widthAnchor.constraint(equalToConstant: Self.fixedWidth),
            heightAnchor.constraint(equalToConstant: 24)
        ])
        BatteryMonitor.shared.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in self?.update(state) }
            .store(in: &cancellables)
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.update(BatteryMonitor.shared.state)
            }
            .store(in: &cancellables)
        update(BatteryMonitor.shared.state)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat { Self.fixedWidth }

    private func update(_ state: BatteryState) {
        button.image = BatteryStatusRenderer.renderImage(
            for: state,
            style: settings.batteryIconStyle,
            size: settings.batteryIconSize,
            showTextInside: settings.showPercentageInsideIcon
        )
        button.title = settings.showBatteryPercentage ? " \(state.percentage)%" : ""
    }

    @objc private func toggleBattery() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }
        let popover = BorderlessFlyout()
        popover.show(contentViewController: NSHostingController(
            rootView: BatteryFlyoutView().environmentObject(settings)
        ), relativeTo: button.bounds, of: button)
        self.popover = popover
    }
}

final class CalendarWidgetView: NSView {
    private static let fixedWidth: CGFloat = 80
    private let calendarButton = CalendarTrayButton()
    private var popover: BorderlessFlyout?

    init() {
        super.init(frame: .zero)
        calendarButton.target = self
        calendarButton.action = #selector(toggleCalendar)
        addSubview(calendarButton)
        calendarButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendarButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarButton.topAnchor.constraint(equalTo: topAnchor),
            calendarButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            widthAnchor.constraint(equalToConstant: Self.fixedWidth)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat { Self.fixedWidth }

    @objc private func toggleCalendar() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }

        let newPopover = BorderlessFlyout()
        newPopover.show(contentViewController: NSHostingController(rootView: CalendarView()), relativeTo: calendarButton.bounds, of: calendarButton)
        popover = newPopover
    }
}

final class QuickSettingsWidgetView: NSView {
    /// Fixed width for the gear icon button — never varies with content.
    private static let fixedWidth: CGFloat = 32
    private let button = NSButton()
    private let settings: TaskbarSettings
    private let manager = QuickSettingsManager.shared
    private var popover: BorderlessFlyout?

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
            heightAnchor.constraint(equalToConstant: 24),
            widthAnchor.constraint(equalToConstant: Self.fixedWidth)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat { Self.fixedWidth }

    @objc private func toggleQuickSettings() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }

        let newPopover = BorderlessFlyout()
        newPopover.show(contentViewController: QuickSettingsViewController(settings: settings, manager: manager), relativeTo: button.bounds, of: button)
        popover = newPopover
    }
}
