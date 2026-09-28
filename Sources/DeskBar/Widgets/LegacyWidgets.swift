import AppKit
import SwiftUI
import DockBarCore

struct ClockWidgetDescriptor: WidgetDescriptor {
    let id = "clock"
    let preferredSize = CGSize(width: 80, height: 44)
    let defaultRule: WidgetLocation = .dock
    func makeView(context: WidgetContext) -> NSView {
        return DockClockWidgetView()
    }
}

struct WeatherWidgetDescriptor: WidgetDescriptor {
    let id = "weather"
    let preferredSize = CGSize(width: 80, height: 44)
    let defaultRule: WidgetLocation = .auto
    func makeView(context: WidgetContext) -> NSView {
        return DockWeatherWidgetView(weatherService: WidgetEngine.shared.weatherService, settings: context.settings)
    }
}

struct ConnectivityWidgetDescriptor: WidgetDescriptor {
    let id = "connectivity"
    let preferredSize = CGSize(width: 60, height: 44)
    let defaultRule: WidgetLocation = .auto
    func makeView(context: WidgetContext) -> NSView {
        return ConnectivityTrayView(settings: context.settings)
    }
}

struct QuickSettingsWidgetDescriptor: WidgetDescriptor {
    let id = "quickSettings"
    let preferredSize = CGSize(width: 44, height: 44)
    let defaultRule: WidgetLocation = .dock
    func makeView(context: WidgetContext) -> NSView {
        return QuickSettingsWidgetView(settings: context.settings)
    }
}

struct StartButtonWidgetDescriptor: WidgetDescriptor {
    let id = "startButton"
    let preferredSize = CGSize(width: 44, height: 44)
    let defaultRule: WidgetLocation = .dock
    func makeView(context: WidgetContext) -> NSView {
        return AppsLauncherButtonView()
    }
}

struct LiveEventsWidgetDescriptor: WidgetDescriptor {
    let id = "liveEvents"
    let preferredSize = CGSize(width: 80, height: 44)
    let defaultRule: WidgetLocation = .dock
    func makeView(context: WidgetContext) -> NSView {
        return LiveEventsWidgetView(weatherService: WidgetEngine.shared.weatherService, settings: context.settings)
    }
}

struct WidgetsBoardWidgetDescriptor: WidgetDescriptor {
    let id = "widgetsBoard"
    let preferredSize = CGSize(width: 44, height: 44)
    let defaultRule: WidgetLocation = .dock
    func makeView(context: WidgetContext) -> NSView {
        let v = NSButton(image: NSImage(systemSymbolName: "rectangle.3.offgrid", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
        v.bezelStyle = .texturedRounded
        v.isBordered = false
        return v
    }
}

struct TrashWidgetDescriptor: WidgetDescriptor {
    let id = "trash"
    let preferredSize = CGSize(width: 44, height: 44)
    let defaultRule: WidgetLocation = .dock
    func makeView(context: WidgetContext) -> NSView {
        let v = NSButton(image: NSImage(systemSymbolName: "trash", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
        v.bezelStyle = .texturedRounded
        v.isBordered = false
        v.target = TrashActionHandler.shared
        v.action = #selector(TrashActionHandler.shared.openTrash)
        
        let menu = NSMenu()
        let emptyItem = NSMenuItem(title: "Empty Trash", action: #selector(TrashActionHandler.shared.emptyTrash), keyEquivalent: "")
        emptyItem.target = TrashActionHandler.shared
        menu.addItem(emptyItem)
        v.menu = menu
        
        return v
    }
}

struct DownloadsWidgetDescriptor: WidgetDescriptor {
    let id = "downloads"
    let preferredSize = CGSize(width: 44, height: 44)
    let defaultRule: WidgetLocation = .dock
    func makeView(context: WidgetContext) -> NSView {
        let v = DownloadsWidgetView(frame: .zero)
        DownloadsActionHandler.shared.widgetView = v
        DownloadsActionHandler.shared.settings = context.settings
        v.target = DownloadsActionHandler.shared
        v.action = #selector(DownloadsActionHandler.shared.openDownloads)
        
        DownloadsMonitor.shared.$activeDownloads
            .receive(on: DispatchQueue.main)
            .sink { actives in
            v.isDownloading = !actives.isEmpty
            if let first = actives.first {
                v.progress = first.progress
            }
        }.store(in: &DownloadsActionHandler.shared.cancellables)
        
        return v
    }
}
