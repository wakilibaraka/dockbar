import AppKit
import Combine

/// One DockBar presence in the menu bar.
///
/// `primary` is the battery-plus-menu item that also opens Settings; the rest are the
/// status widgets. Enumerating the slots keeps "which items exist" separate from "which
/// of them should be visible right now", which is what made the old code hard to follow:
/// six items, each with its own sink, each deciding its own visibility.
enum MenuBarSlot: String, CaseIterable, Hashable {
    case primary
    case connectivity
    case calendar
    case quickSettings
    case systemResources
    case weather
}

/// Which menu bar items should currently be on screen.
///
/// Pure, so the rules can be tested without a status bar. The rules are:
/// * the combined calendar and quick settings item shows when it is *not* split and is
///   placed in the menu bar;
/// * when split, the calendar and quick settings items show independently;
/// * every other widget shows when its own placement says menu bar;
/// * weather additionally honours its enabled flag.
struct MenuBarPlan: Equatable {
    var visible: Set<MenuBarSlot>

    static func resolve(
        batteryLocation: WidgetLocation,
        isSplit: Bool,
        connectivityLocation: WidgetLocation,
        calendarLocation: WidgetLocation,
        quickSettingsLocation: WidgetLocation,
        systemResourceLocation: WidgetLocation,
        isWeatherEnabled: Bool,
        weatherLocation: WidgetLocation
    ) -> MenuBarPlan {
        var visible: Set<MenuBarSlot> = []

        // The primary item *is* the battery, so it follows the battery's placement.
        if batteryLocation == .menuBar {
            visible.insert(.primary)
        }

        if isSplit {
            if calendarLocation == .menuBar { visible.insert(.calendar) }
            if quickSettingsLocation == .menuBar { visible.insert(.quickSettings) }
        } else if connectivityLocation == .menuBar {
            visible.insert(.connectivity)
        }

        if systemResourceLocation == .menuBar { visible.insert(.systemResources) }
        if isWeatherEnabled, weatherLocation == .menuBar { visible.insert(.weather) }

        return MenuBarPlan(visible: visible)
    }

    func isVisible(_ slot: MenuBarSlot) -> Bool {
        visible.contains(slot)
    }

    /// The slots, in the order they should read left to right. Stable ordering matters
    /// because macOS appends status items in creation order.
    var orderedVisibleSlots: [MenuBarSlot] {
        MenuBarSlot.allCases.filter { visible.contains($0) }
    }
}

/// Owns every `NSStatusItem` DockBar creates, and keeps their visibility in step with
/// the settings.
///
/// The items are created once at launch and reused forever; only `isVisible` and
/// `length` change. That matters for the weather and system-resource widgets, which
/// self-update and would otherwise be torn down and rebuilt whenever the user moved one
/// between the bar and the menu bar.
@MainActor
final class MenuBarController {
    /// Creating the controller touches no AppKit, so it can be built from a property
    /// initialiser even though everything it does is main-actor bound.
    nonisolated init() {}

    private var items: [MenuBarSlot: NSStatusItem] = [:]
    private var cancellables = Set<AnyCancellable>()

    /// The widths each slot's view wants, refreshed whenever the view changes size.
    private var preferredWidths: [MenuBarSlot: CGFloat] = [:]

    /// Creates all six status items up front so their relative order never shifts.
    func installItems() {
        guard items.isEmpty else { return }
        for slot in MenuBarSlot.allCases {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.isVisible = false
            items[slot] = item
        }
    }

    func item(for slot: MenuBarSlot) -> NSStatusItem? {
        items[slot]
    }

    /// Attaches a widget view to a slot's button and remembers how wide it wants to be.
    func attach(_ view: NSView, to slot: MenuBarSlot, preferredWidth: CGFloat) {
        guard let button = items[slot]?.button else { return }
        view.frame = NSRect(x: 0, y: 0, width: preferredWidth, height: DesignSystem.Metrics.menuBarItemHeight)
        button.addSubview(view)
        setPreferredWidth(preferredWidth, for: slot)
    }

    func setPreferredWidth(_ width: CGFloat, for slot: MenuBarSlot) {
        preferredWidths[slot] = width
    }

    /// Applies a plan: shows and hides items, and resizes the visible ones.
    func apply(_ plan: MenuBarPlan) {
        for (slot, item) in items {
            let shouldShow = plan.isVisible(slot)
            item.isVisible = shouldShow
            if shouldShow, let width = preferredWidths[slot] {
                item.length = width
            }
        }
    }

    /// Subscribes to the settings that decide visibility and applies the plan.
    func bind(to settings: TaskbarSettings) {
        Publishers.CombineLatest4(
            settings.$batteryWidgetLocation,
            settings.$splitCalendarAndQuickSettings,
            settings.$connectivityTrayLocation,
            settings.$weatherEnabled
        )
        .combineLatest(
            Publishers.CombineLatest4(
                settings.$calendarLocation,
                settings.$quickSettingsLocation,
                settings.$systemResourceWidgetLocation,
                settings.$weatherWidgetLocation
            )
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] head, tail in
            let (batteryLocation, isSplit, connectivityLocation, isWeatherEnabled) = head
            let (calendarLocation, quickSettingsLocation, systemResourceLocation, weatherLocation) = tail
            self?.apply(
                MenuBarPlan.resolve(
                    batteryLocation: batteryLocation,
                    isSplit: isSplit,
                    connectivityLocation: connectivityLocation,
                    calendarLocation: calendarLocation,
                    quickSettingsLocation: quickSettingsLocation,
                    systemResourceLocation: systemResourceLocation,
                    isWeatherEnabled: isWeatherEnabled,
                    weatherLocation: weatherLocation
                )
            )
        }
        .store(in: &cancellables)
    }

    /// Re-applies the current plan, e.g. after a widget changes its own width.
    func refreshLengths() {
        for (slot, item) in items where item.isVisible {
            if let width = preferredWidths[slot] {
                item.length = width
            }
        }
    }

    /// Removes every item. Used on termination and in tests.
    func tearDown() {
        for item in items.values {
            NSStatusBar.system.removeStatusItem(item)
        }
        items.removeAll()
        preferredWidths.removeAll()
        cancellables.removeAll()
    }
}