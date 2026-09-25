import AppKit
import SwiftUI
import Combine


struct WeatherFlyoutView: View {
    let service: WeatherService
    var body: some View {
        WeatherHeroView(service: service)
            .padding(16)
            .frame(width: 320)
    }
}

struct SmallWeatherView: View {
    @ObservedObject var service: WeatherService
    @EnvironmentObject var settings: TaskbarSettings
    
    var body: some View {
        let conditions = service.conditions
        
        HStack(spacing: 6) {
            Image(systemName: conditions.symbolName)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(conditions.temperature.map { WeatherService.displayTemperature($0, unit: settings.weatherUnit) } ?? "--")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Text(conditions.conditionText)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 110, alignment: .leading)
        .padding(.horizontal, 8)
    }
}

final class DockWeatherWidgetView: NSView {
    private let hostingView: NSHostingView<AnyView>
    private let fixedWidth: CGFloat = 110 + 16
    private var cancellables = Set<AnyCancellable>()
    private let service: WeatherService
    private let settings: TaskbarSettings
    
    private var flyout: BorderlessFlyout?

    init(weatherService: WeatherService, settings: TaskbarSettings) {
        self.service = weatherService
        self.settings = settings

        let view = SmallWeatherView(service: weatherService).environmentObject(settings)
        hostingView = NSHostingView(rootView: AnyView(view))
        super.init(frame: .zero)
        
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            widthAnchor.constraint(equalToConstant: fixedWidth)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func preferredContentWidth() -> CGFloat {
        return fixedWidth
    }

    override func mouseDown(with event: NSEvent) {
        if let current = flyout, current.isShown {
            current.performClose(nil)
            return
        }
        let popover = BorderlessFlyout()
        popover.onDismiss = { [weak self] in
            self?.flyout = nil
        }
        let view = WeatherFlyoutView(service: service).environmentObject(settings)
        let hc = NSHostingController(rootView: view)
        popover.show(contentViewController: hc, relativeTo: bounds, of: self)
        flyout = popover
    }

    override func isAccessibilityElement() -> Bool { return true }
    override func accessibilityLabel() -> String? { return "WeatherWidget" }
    override func accessibilityRole() -> NSAccessibility.Role? { return .button }
}
