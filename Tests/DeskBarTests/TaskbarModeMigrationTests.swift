import Foundation
import Testing
@testable import DockBar

/// The `deskBar` style was renamed to `classic`. Upgrading installs must keep the bar
/// they chose, so the legacy raw value has to keep resolving.
struct TaskbarModeMigrationTests {
    @Test
    func legacyDeskBarRawValueMigratesToClassic() throws {
        #expect(TaskbarMode(persistedRawValue: "deskBar") == .classic)
        #expect(TaskbarMode.classic.rawValue == "classic")
    }

    @Test
    func currentRawValuesResolveUnchanged() {
        for mode in TaskbarMode.allCases {
            #expect(TaskbarMode(persistedRawValue: mode.rawValue) == mode)
        }
    }

    @Test
    func unknownRawValueStillRejects() {
        #expect(TaskbarMode(persistedRawValue: "not-a-style") == nil)
    }

    @Test
    func upgradingInstallKeepsTheClassicBar() throws {
        let suiteName = "TaskbarModeMigrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set("deskBar", forKey: "dockMode_system")
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = TaskbarSettings(defaults: defaults)
        #expect(settings.taskbarMode == .classic)

        // And it is written back under the new name, so the next launch is a plain read.
        settings.taskbarMode = settings.taskbarMode
        #expect(defaults.string(forKey: "dockMode_system") == "classic")
    }

    @Test
    func everyStyleHasDistinctPresentationMetadata() {
        let names = TaskbarMode.allCases.map(\.displayName)
        #expect(Set(names).count == names.count, "two styles share a display name")

        let subtitles = TaskbarMode.allCases.map(\.subtitle)
        #expect(Set(subtitles).count == subtitles.count, "two styles share a subtitle")

        let symbols = TaskbarMode.allCases.map(\.symbolName)
        #expect(Set(symbols).count == symbols.count, "two styles share an SF Symbol")
    }

    @Test
    func theHybridIsANewModeNotARenameOfAnOldOne() {
        // The hybrid was added in v0.6, so nothing should map onto it. If a future rename
        // reuses its raw value this test is the one that should catch it.
        #expect(TaskbarMode(persistedRawValue: "hybrid") == .hybrid)
        #expect(TaskbarMode(persistedRawValue: "eskele") == .eskele)
    }
}