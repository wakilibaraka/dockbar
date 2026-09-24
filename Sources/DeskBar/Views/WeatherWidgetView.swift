import AppKit
import Combine
import SwiftUI

@MainActor
final class WeatherWidgetView: NSView {
    private static let fixedWidth: CGFloat = 92
    private let service: WeatherService
    private let settings: TaskbarSettings
    private let button = NSButton()
    private var flyout: BorderlessFlyout?
    private var cancellables = Set<AnyCancellable>()

    init(service: WeatherService, settings: TaskbarSettings) {
        self.service = service
        self.settings = settings
        super.init(frame: NSRect(x: 0, y: 0, width: Self.fixedWidth, height: 22))

        button.isBordered = false
        button.imagePosition = .imageLeading
        button.alignment = .left
        button.target = self
        button.action = #selector(togglePopover)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        service.$conditions
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateAppearance() }
            .store(in: &cancellables)
        settings.$weatherUnit
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateAppearance() }
            .store(in: &cancellables)
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat { Self.fixedWidth }

    @objc private func togglePopover() {
        if let currentFlyout = flyout, currentFlyout.isShown {
            currentFlyout.performClose(nil)
            return
        }
        let newPopover = BorderlessFlyout()
        newPopover.onDismiss = { [weak self] in
            self?.flyout = nil
        }
        
        let vc = NSHostingController(
            rootView: WeatherFlyoutView(service: service, settings: settings)
        )
        newPopover.show(contentViewController: vc, relativeTo: button.bounds, of: button)
        flyout = newPopover
    }

    private func updateAppearance() {
        let conditions = service.conditions
        button.image = NSImage(systemSymbolName: conditions.symbolName, accessibilityDescription: "Weather")
        if case .available = conditions.state, let temperature = conditions.temperature {
            button.title = " \(WeatherService.displayTemperature(temperature, unit: settings.weatherUnit))"
        } else {
            button.title = " --"
        }
    }
}
