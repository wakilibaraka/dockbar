import Foundation
import Testing
@testable import DockBar

/// These tests are the reason `SettingsCatalog` can be trusted as the single source of
/// truth. They parse `TaskbarSettings.swift` so a newly added setting cannot be
/// silently forgotten in the UI, and they prove every `reset` really does restore the
/// factory value.
struct SettingsCatalogTests {
    /// Every `@Published` property declared on `TaskbarSettings`.
    ///
    /// Read from the source rather than through `Mirror`: `@Published` stores its value
    /// in an underscored property, so reflection shows `_showTitles` and not
    /// `showTitles`. Parsing the declaration is also the stricter check — it fails if a
    /// setting is added but never catalogued, which is exactly the bug this prevents.
    private static func publishedPropertyNames() throws -> Set<String> {
        let settingsURL = try #require(settingsSourceURL(), "could not locate TaskbarSettings.swift")
        let source = try String(contentsOf: settingsURL, encoding: .utf8)
        let pattern = try NSRegularExpression(pattern: #"@Published\s+var\s+(\w+)\s*:"#)
        let range = NSRange(source.startIndex..., in: source)
        return Set(pattern.matches(in: source, range: range).compactMap { match in
            // Group 1 is the property name; group 0 is the whole declaration.
            guard let nameRange = Range(match.range(at: 1), in: source) else { return nil }
            return String(source[nameRange])
        })
    }

    @Test
    func everyPersistedPropertyIsDescribedExactlyOnce() throws {
        let catalogKeys = SettingsCatalog.all.map(\.id)
        #expect(
            Set(catalogKeys).count == catalogKeys.count,
            "duplicate ids in the catalogue: \(catalogKeys)"
        )

        let published = try Self.publishedPropertyNames()
        #expect(!published.isEmpty, "found no @Published properties; the parser needs updating")

        let catalogued = Set(catalogKeys)
        let orphaned = published.subtracting(catalogued).sorted()
        #expect(orphaned.isEmpty, "settings with no catalogue entry: \(orphaned)")

        let stale = catalogued.subtracting(published).sorted()
        #expect(stale.isEmpty, "catalogue entries with no such property: \(stale)")
    }

    @Test
    func everySectionHasUserVisibleContent() {
        for section in SettingsSection.allCases {
            #expect(
                !SettingsCatalog.userVisibleItems(in: section).isEmpty,
                "section \(section.rawValue) is empty"
            )
        }
    }

    @Test
    func searchRanksTitleMatchesAboveHelpMatches() throws {
        let results = SettingsCatalog.search("battery")
        #expect(!results.isEmpty)
        #expect(results.contains { $0.id == "showBatteryPercentage" })

        // An exact title match must outrank a title that merely contains the query.
        let first = try #require(SettingsCatalog.search("battery percentage").first)
        #expect(first.id == "showBatteryPercentage")

        // Help text alone is still searchable.
        #expect(SettingsCatalog.search("translucent").contains { $0.id == "layoutMode" })
        // Keywords are searchable too.
        #expect(SettingsCatalog.search("alt tab").contains { $0.id == "enableWindowSwitcher" })

        // Nonsense matches nothing rather than returning everything.
        #expect(SettingsCatalog.search("zzzzz-not-a-setting").isEmpty)
        #expect(SettingsCatalog.search("").isEmpty)
        #expect(SettingsCatalog.search("   ").isEmpty)
    }

    @Test
    func internalSettingsAreHiddenFromSearch() {
        #expect(!SettingsCatalog.search("onboarding").contains { $0.id == "hasCompletedOnboarding" })
        #expect(SettingsCatalog.descriptor(for: "hasCompletedOnboarding")?.isUserVisible == false)
    }

    @Test
    func everyEntryHasAHelpStringAndAReadableValue() {
        let settings = TaskbarSettings(defaults: makeDefaults())
        for entry in SettingsCatalog.all where entry.isUserVisible {
            #expect(!entry.title.isEmpty, "\(entry.id) has no title")
            #expect(!entry.help.isEmpty, "\(entry.id) has no help text")
            #expect(!entry.read(settings).isEmpty, "\(entry.id) renders no value")
        }
    }

    @Test
    func revertingASectionRestoresOnlyThatSection() {
        let settings = TaskbarSettings(defaults: makeDefaults())

        settings.taskbarHeight = 80
        settings.taskbarMode = .eskele
        settings.startAtLogin = true
        settings.fuzzySearch = false

        SettingsCatalog.revert(settings, sections: [.taskbar])

        #expect(settings.taskbarHeight == TaskbarSettings.defaultTaskbarHeight)
        #expect(settings.taskbarMode == .custom)
        // Untouched sections keep their values.
        #expect(settings.startAtLogin == true)
        #expect(settings.fuzzySearch == false)
    }

    /// The strongest guarantee the catalogue can offer: after reverting everything, every
    /// setting must read back exactly as a freshly constructed object does.
    @Test
    func revertingEverythingRestoresEveryFactoryValue() {
        let defaults = makeDefaults()
        let settings = TaskbarSettings(defaults: defaults)

        // Perturb every value the catalogue can reach.
        settings.taskbarMode = .mac
        settings.layoutMode = .fullWidth
        settings.dockPosition = .floatingCenter
        settings.appTheme = .dark
        settings.taskbarHeight = 72
        settings.iconOnlySize = 48
        settings.dragReorder = false
        settings.middleClickCloses = false
        settings.flashAttentionIndicators = false
        settings.showProgressIndicators = false
        settings.enableActivityMode = false
        settings.hoverDelay = 1.2
        settings.showTitles = false
        settings.taskTitleSource = .appName
        settings.taskTruncationStyle = .middle
        settings.titleFontSize = 18
        settings.maxTaskWidth = 380
        settings.thumbnailSize = 320
        settings.groupingMode = .never
        settings.groupedClickAction = .showPopover
        settings.frontmostClickAction = .minimize
        settings.showWindowCountBadges = false
        settings.enableWindowSwitcher = false
        settings.enableHoldToQuit = false
        settings.holdToQuitDuration = 4.5
        settings.holdToQuitCmdW = true
        settings.screenMode = .focusedScreen
        settings.nativeDockBehavior = .hidden
        settings.showOverFullScreenApps = true
        settings.enableBareCommandLauncher = false
        settings.appsLauncherShortcut = .optionSpace
        settings.launcherStyle = .floating
        settings.fuzzySearch = false
        settings.autoOpenSingleSearchResult = true
        settings.connectivityTrayLocation = .menuBar
        settings.splitCalendarAndQuickSettings = true
        settings.calendarLocation = .menuBar
        settings.quickSettingsLocation = .dock
        settings.batteryWidgetLocation = .dock
        settings.showBatteryPercentage = false
        settings.showPercentageInsideIcon = true
        settings.batteryIconStyle = .verticalBars
        settings.batteryIconSize = .small
        settings.systemResourceWidgetLocation = .dock
        settings.showSystemResourceWidget = false
        settings.resourceDisplayStyle = .graph
        settings.weatherEnabled = false
        settings.weatherWidgetLocation = .menuBar
        settings.weatherUnit = .fahrenheit
        settings.weatherPollingInterval = 3600
        settings.weatherLocationMode = .manual
        settings.weatherManualLatitude = 51.5
        settings.weatherManualLongitude = -0.12
        settings.dockWidgetOrder = ["weather"]
        settings.enabledQuickSettings = ["wifi"]
        settings.showConnections = true
        settings.notifyBluetoothConnect = true
        settings.notifyBluetoothLowBattery = true
        settings.notifyWiFiChange = false
        settings.notifyWiFiWeak = true
        settings.startAtLogin = true
        settings.enableSessionManagerPlugin = false
        settings.showSessionManagerAgentTitles = false
        settings.showSessionManagerActivityIndicators = false
        settings.animateSessionManagerActivity = true
        settings.showSessionManagerTokenUsage = false
        settings.enableSessionManagerTerminalActions = false
        settings.showSessionManagerActionButton = false
        settings.hasCompletedOnboarding = true

        // Confirm the perturbations actually took, so the assertion below cannot pass
        // trivially by never having changed anything.
        let perturbed = SettingsCatalog.all.filter { $0.id != "hasCompletedOnboarding" && $0.id != "dockWidgetOrder" }
        let beforeRevert = perturbed.filter { $0.read(settings) == $0.read(pristine()) }
        #expect(
            beforeRevert.isEmpty,
            "these settings did not actually change: \(beforeRevert.map(\.id))"
        )

        SettingsCatalog.revert(settings, sections: Set(SettingsSection.allCases))

        let expected = pristine()
        for entry in SettingsCatalog.all {
            let actual = entry.read(settings)
            let wanted = entry.read(expected)
            #expect(actual == wanted, "\(entry.id) was not restored: \(actual) != \(wanted)")
        }
    }

    /// A settings object built from a brand new suite: the reference for "factory".
    private func pristine() -> TaskbarSettings {
        TaskbarSettings(defaults: makeDefaults())
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "SettingsCatalogTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Walks up from this test file to the package root and then to the settings model.
    private static func settingsSourceURL() -> URL? {
        let testFile = URL(fileURLWithPath: #filePath)
        let packageRoot = testFile
            .deletingLastPathComponent() // DeskBarTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // package root
        let candidate = packageRoot
            .appendingPathComponent("Sources/DeskBar/Models/TaskbarSettings.swift")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }
}