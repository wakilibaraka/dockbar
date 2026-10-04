import Foundation
import Testing
@testable import DockBar

struct TaskbarSettingsTests {
    @Test
    func defaultSettingsOnFreshInstall() {
        let suiteName = "TaskbarSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let settings = TaskbarSettings(defaults: defaults)

        // These mirror the fallbacks in TaskbarSettings.init: a fresh install gets the
        // compact glass bar, window grouping, and the right-Command double-tap launcher.
        #expect(settings.screenMode == .allScreens)
        #expect(settings.groupingMode == .always)
        #expect(settings.flashAttentionIndicators)
        #expect(settings.showProgressIndicators)
        #expect(settings.enableActivityMode)
        #expect(settings.showSystemResourceWidget)
        #expect(settings.layoutMode == .compactGlass)
        #expect(settings.enableWindowSwitcher == true)
        #expect(settings.enableBareCommandLauncher == true)
        #expect(settings.appsLauncherShortcut == .rightCommandTap)
        #expect(settings.animateSessionManagerActivity == false)
    }

    @Test
    func widgetLocationsUseNewDefaultsOnFreshInstall() {
        let suiteName = "TaskbarSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = TaskbarSettings(defaults: defaults)

        #expect(settings.splitCalendarAndQuickSettings == false)
        #expect(settings.connectivityTrayLocation == .dock)
        #expect(settings.calendarLocation == .dock)
        #expect(settings.quickSettingsLocation == .menuBar)
        #expect(settings.systemResourceWidgetLocation == .menuBar)
        #expect(settings.batteryWidgetLocation == .menuBar)
    }

    @Test
    func widgetLocationMigrationPreservesExistingValues() {
        let suiteName = "TaskbarSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(WidgetLocation.menuBar.rawValue, forKey: "connectivityTrayLocation")
        defaults.set(WidgetLocation.dock.rawValue, forKey: "systemResourceWidgetLocation")
        defaults.set(WidgetLocation.dock.rawValue, forKey: "batteryWidgetLocation")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = TaskbarSettings(defaults: defaults)

        #expect(settings.connectivityTrayLocation == .menuBar)
        #expect(settings.systemResourceWidgetLocation == .dock)
        #expect(settings.batteryWidgetLocation == .dock)
    }

    @Test
    func migratesLegacyGroupByAppSetting() {
        let suiteName = "TaskbarSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: "groupByApp")
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let settings = TaskbarSettings(defaults: defaults)

        #expect(settings.groupingMode == .always)
    }

    @Test
    func persistsLayoutAndShortcutSettings() {
        let suiteName = "TaskbarSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        var settings = TaskbarSettings(defaults: defaults)
        settings.layoutMode = .fullWidthGlass
        settings.enableWindowSwitcher = false
        settings.enableBareCommandLauncher = false
        settings.appsLauncherShortcut = .optionSpace
        settings.showSystemResourceWidget = false

        settings = TaskbarSettings(defaults: defaults)

        #expect(settings.layoutMode == .fullWidthGlass)
        #expect(settings.enableWindowSwitcher == false)
        #expect(settings.enableBareCommandLauncher == false)
        #expect(settings.appsLauncherShortcut == .optionSpace)
        #expect(settings.showSystemResourceWidget == false)
    }

    @Test
    func resetAppearanceSlidersRestoresDefaults() {
        let suiteName = "TaskbarSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        var settings = TaskbarSettings(defaults: defaults)
        settings.taskbarHeight = 60
        settings.titleFontSize = 18
        settings.maxTaskWidth = 400
        settings.thumbnailSize = 400

        settings.resetAppearanceSlidersToDefaults()

        #expect(settings.taskbarHeight == TaskbarSettings.defaultTaskbarHeight)
        #expect(settings.titleFontSize == TaskbarSettings.defaultTitleFontSize)
        #expect(settings.maxTaskWidth == TaskbarSettings.defaultMaxTaskWidth)
        #expect(settings.thumbnailSize == TaskbarSettings.defaultThumbnailSize)

        settings = TaskbarSettings(defaults: defaults)

        #expect(settings.taskbarHeight == TaskbarSettings.defaultTaskbarHeight)
        #expect(settings.titleFontSize == TaskbarSettings.defaultTitleFontSize)
        #expect(settings.maxTaskWidth == TaskbarSettings.defaultMaxTaskWidth)
        #expect(settings.thumbnailSize == TaskbarSettings.defaultThumbnailSize)
    }
}
