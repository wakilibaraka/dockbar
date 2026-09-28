import AppKit
import SwiftUI
import Combine

enum LiveEventState {
    case weather
    case calendar
}

class LiveEventsState: ObservableObject {
    @Published var currentState: LiveEventState = .weather
}

final class LiveEventsWidgetView: NSView {
    let state = LiveEventsState()
    private let hostingView: NSHostingView<AnyView>
    private let fixedWidth: CGFloat = 130
    private var cancellables = Set<AnyCancellable>()
    private let weatherService: WeatherService
    private let calendarService = CalendarEventService.shared
    private let settings: TaskbarSettings
    
    private var flyout: BorderlessFlyout?
    
    init(weatherService: WeatherService, settings: TaskbarSettings) {
        self.weatherService = weatherService
        self.settings = settings
        
        let view = LiveEventsSwiftUIView(
            weatherService: weatherService,
            calendarService: calendarService,
            settings: settings,
            liveState: state
        )
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
        
        Timer.publish(every: 15, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                let hasUpcoming = self.calendarService.events.contains {
                    $0.startDate > Date() && $0.startDate.timeIntervalSinceNow < 3600 * 24
                }
                
                if hasUpcoming {
                    self.state.currentState = (self.state.currentState == .weather) ? .calendar : .weather
                } else {
                    self.state.currentState = .weather
                }
            }
            .store(in: &cancellables)
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
        
        let view: AnyView
        if state.currentState == .weather {
            view = AnyView(WeatherFlyoutView(service: weatherService).environmentObject(settings))
        } else {
            view = AnyView(CalendarView()) 
        }
        
        let hc = NSHostingController(rootView: view)
        popover.show(contentViewController: hc, relativeTo: bounds, of: self)
        flyout = popover
    }
}

struct LiveEventsSwiftUIView: View {
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var calendarService: CalendarEventService
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var liveState: LiveEventsState
    
    var body: some View {
        Group {
            if liveState.currentState == .weather {
                SmallWeatherView(service: weatherService)
                    .environmentObject(settings)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                if let nextEvent = nextEvent() {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(nextEvent.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(timeUntil(nextEvent.startDate))
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: 130, alignment: .leading)
                    .padding(.horizontal, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    SmallWeatherView(service: weatherService)
                        .environmentObject(settings)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: liveState.currentState)
    }
    
    private func nextEvent() -> CalendarEvent? {
        let now = Date()
        return calendarService.events.first { $0.startDate > now && $0.startDate.timeIntervalSince(now) < 3600 * 24 }
    }
    
    private func timeUntil(_ date: Date) -> String {
        let diff = Int(date.timeIntervalSinceNow)
        if diff < 60 { return "In < 1 min" }
        if diff < 3600 { return "In \\(diff / 60) min" }
        let hours = diff / 3600
        let mins = (diff % 3600) / 60
        if hours < 12 { return "In \\(hours)h \\(mins)m" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
