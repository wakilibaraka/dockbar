import AppKit
import SwiftUI
import Combine

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
    
    init(weatherService: WeatherService, settings: TaskbarSettings) {
        self.service = weatherService
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
}
