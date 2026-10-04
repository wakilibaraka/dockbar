import Foundation
import Testing
@testable import DockBar

/// The menu bar used to decide visibility from six independent sinks in `AppDelegate`,
/// one per status item. These tests pin the same rules in the one place that now owns
/// them, so moving a widget between the bar and the menu bar cannot half-apply.
struct MenuBarPlanTests {
    private func plan(
        battery: WidgetLocation = .menuBar,
        isSplit: Bool = false,
        connectivity: WidgetLocation = .dock,
        calendar: WidgetLocation = .dock,
        quickSettings: WidgetLocation = .menuBar,
        systemResources: WidgetLocation = .menuBar,
        weatherEnabled: Bool = true,
        weather: WidgetLocation = .dock
    ) -> MenuBarPlan {
        MenuBarPlan.resolve(
            batteryLocation: battery,
            isSplit: isSplit,
            connectivityLocation: connectivity,
            calendarLocation: calendar,
            quickSettingsLocation: quickSettings,
            systemResourceLocation: systemResources,
            isWeatherEnabled: weatherEnabled,
            weatherLocation: weather
        )
    }

    @Test
    func unsplitShowsTheCombinedItemAndHidesTheTwoHalves() {
        let combined = plan(isSplit: false, connectivity: .menuBar, calendar: .menuBar, quickSettings: .menuBar)
        #expect(combined.isVisible(.connectivity))
        // The separate items must not appear alongside the combined one.
        #expect(!combined.isVisible(.calendar))
        #expect(!combined.isVisible(.quickSettings))
    }

    @Test
    func unsplitCombinedItemHidesWhenItIsOnTheBar() {
        let combined = plan(isSplit: false, connectivity: .dock)
        #expect(!combined.isVisible(.connectivity))
    }

    @Test
    func splitShowsEachHalfIndependently() {
        let split = plan(isSplit: true, connectivity: .menuBar, calendar: .dock, quickSettings: .menuBar)
        #expect(!split.isVisible(.connectivity))
        #expect(!split.isVisible(.calendar))
        #expect(split.isVisible(.quickSettings))
    }

    @Test
    func splitPutsBothHalvesInTheMenuBarWhenAsked() {
        let split = plan(isSplit: true, calendar: .menuBar, quickSettings: .menuBar)
        #expect(split.isVisible(.calendar))
        #expect(split.isVisible(.quickSettings))
    }

    @Test
    func thePrimaryItemIsTheBatteryAndFollowsItsPlacement() {
        #expect(plan(battery: .menuBar).isVisible(.primary))
        #expect(!plan(battery: .dock).isVisible(.primary))
    }

    @Test
    func weatherNeedsBothItsFlagAndItsPlacement() {
        #expect(plan(weatherEnabled: true, weather: .menuBar).isVisible(.weather))
        #expect(!plan(weatherEnabled: false, weather: .menuBar).isVisible(.weather))
        #expect(!plan(weatherEnabled: true, weather: .dock).isVisible(.weather))
    }

    @Test
    func systemResourcesFollowTheirOwnPlacement() {
        #expect(plan(systemResources: .menuBar).isVisible(.systemResources))
        #expect(!plan(systemResources: .dock).isVisible(.systemResources))
    }

    @Test
    func anEverythingInTheDockSetupShowsOnlyTheBattery() {
        let allOnBar = plan(
            battery: .menuBar,
            isSplit: false,
            connectivity: .dock,
            calendar: .dock,
            quickSettings: .dock,
            systemResources: .dock,
            weatherEnabled: true,
            weather: .dock
        )
        #expect(allOnBar.visible == [.primary])
    }

    @Test
    func visibleSlotsAreOrderedBySlotOrderNotByVisibilityOrder() {
        // macOS appends status items in creation order, so a stable order matters.
        let everything = MenuBarPlan(visible: [.weather, .primary, .systemResources, .quickSettings])
        #expect(everything.orderedVisibleSlots == [.primary, .quickSettings, .systemResources, .weather])
    }

    @Test
    func theDefaultConfigurationShowsEveryWidgetInTheMenuBar() {
        // Since v0.6 a fresh install puts every widget in the menu bar, so this is the plan
        // the app actually starts with. Nothing may be silently dropped along the way.
        let suiteName = "MenuBarPlanTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = TaskbarSettings(defaults: defaults)
        let defaultPlan = MenuBarPlan.resolve(
            batteryLocation: settings.batteryWidgetLocation,
            isSplit: settings.splitCalendarAndQuickSettings,
            connectivityLocation: settings.connectivityTrayLocation,
            calendarLocation: settings.calendarLocation,
            quickSettingsLocation: settings.quickSettingsLocation,
            systemResourceLocation: settings.systemResourceWidgetLocation,
            isWeatherEnabled: settings.weatherEnabled,
            weatherLocation: settings.weatherWidgetLocation
        )

        // The combined item and its two halves are mutually exclusive, so the default
        // (unsplit) shows four of the six slots, not all six.
        #expect(defaultPlan.orderedVisibleSlots == [.primary, .connectivity, .systemResources, .weather])
        #expect(!defaultPlan.isVisible(.calendar))
        #expect(!defaultPlan.isVisible(.quickSettings))

        // Splitting trades the combined item for the two halves and keeps everything else.
        var splitSettings = settings
        splitSettings.splitCalendarAndQuickSettings = true
        let splitPlan = MenuBarPlan.resolve(
            batteryLocation: splitSettings.batteryWidgetLocation,
            isSplit: splitSettings.splitCalendarAndQuickSettings,
            connectivityLocation: splitSettings.connectivityTrayLocation,
            calendarLocation: splitSettings.calendarLocation,
            quickSettingsLocation: splitSettings.quickSettingsLocation,
            systemResourceLocation: splitSettings.systemResourceWidgetLocation,
            isWeatherEnabled: splitSettings.weatherEnabled,
            weatherLocation: splitSettings.weatherWidgetLocation
        )
        #expect(splitPlan.orderedVisibleSlots == [.primary, .calendar, .quickSettings, .systemResources, .weather])
    }

    @Test
    func everySlotCanBeMadeVisibleUnderSomeConfiguration() {
        // Guards against a new slot being added to the enum but never handled by the
        // planner, which would leave a status item permanently invisible. The combined
        // item and its two halves are mutually exclusive, so they need different
        // configurations to both be reachable.
        let everythingInMenuBar = MenuBarPlan.resolve(
            batteryLocation: .menuBar,
            isSplit: false,
            connectivityLocation: .menuBar,
            calendarLocation: .menuBar,
            quickSettingsLocation: .menuBar,
            systemResourceLocation: .menuBar,
            isWeatherEnabled: true,
            weatherLocation: .menuBar
        )
        let splitInMenuBar = MenuBarPlan.resolve(
            batteryLocation: .menuBar,
            isSplit: true,
            connectivityLocation: .menuBar,
            calendarLocation: .menuBar,
            quickSettingsLocation: .menuBar,
            systemResourceLocation: .menuBar,
            isWeatherEnabled: true,
            weatherLocation: .menuBar
        )

        for slot in MenuBarSlot.allCases {
            #expect(
                everythingInMenuBar.isVisible(slot) || splitInMenuBar.isVisible(slot),
                "\(slot.rawValue) can never be visible"
            )
        }
    }
}