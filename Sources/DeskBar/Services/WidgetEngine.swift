import SwiftUI
import AppKit
import DockBarCore

struct WidgetContext {
    let settings: TaskbarSettings
    let openFlyout: (AnyView) -> Void
}

protocol WidgetDescriptor {
    var id: String { get }
    var preferredSize: CGSize { get }
    var defaultRule: WidgetLocation { get }
     func makeView(context: WidgetContext) -> NSView
}


final class WidgetEngine: ObservableObject {
    static let shared = WidgetEngine()
    
    var weatherService: WeatherService!
    var systemResourceMonitor: SystemResourceMonitor!
    
    private var descriptors: [String: any WidgetDescriptor] = [:]
    
    private init() {
        register(BatteryWidgetDescriptor())
        register(SystemStatsWidgetDescriptor())
        register(ClockWidgetDescriptor())
        register(WeatherWidgetDescriptor())
        register(ConnectivityWidgetDescriptor())
        register(QuickSettingsWidgetDescriptor())
        register(StartButtonWidgetDescriptor())
        register(LiveEventsWidgetDescriptor())
        register(WidgetsBoardWidgetDescriptor())
        register(TrashWidgetDescriptor())
        register(DownloadsWidgetDescriptor())
    }
    
    private func register(_ descriptor: any WidgetDescriptor) {
        descriptors[descriptor.id] = descriptor
    }
    
    func descriptor(for id: String) -> (any WidgetDescriptor)? {
        return descriptors[id]
    }
    
    var flyoutHandler: ((String, AnyView) -> Void)?

    func makeView(for id: String, settings: TaskbarSettings) -> NSView? {
        guard let descriptor = descriptors[id] else { return nil }
        let context = WidgetContext(
            settings: settings,
            openFlyout: { [weak self] content in
                self?.flyoutHandler?(id, content)
            }
        )
        return descriptor.makeView(context: context)
    }
}
