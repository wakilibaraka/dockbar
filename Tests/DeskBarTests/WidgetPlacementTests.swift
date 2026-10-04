import Foundation
import Testing
@testable import DockBar

@Suite("Widget placement")
struct WidgetPlacementTests {
    @Test
    func freshInstallPutsEveryWidgetInTheMenuBar() {
        let resolved = WidgetPlacement.resolve(stored: [:], isExistingInstall: false)

        for slot in WidgetPlacement.Slot.all {
            #expect(resolved[slot.key]?.location == .menuBar, "\(slot.key)")
            #expect(resolved[slot.key]?.needsWrite == true, "\(slot.key)")
        }
    }

    @Test
    func existingInstallKeepsThePreSixDefaults() {
        let resolved = WidgetPlacement.resolve(stored: [:], isExistingInstall: true)

        #expect(resolved[WidgetPlacement.Slot.connectivity.key]?.location == .dock)
        #expect(resolved[WidgetPlacement.Slot.calendar.key]?.location == .dock)
        #expect(resolved[WidgetPlacement.Slot.weather.key]?.location == .dock)
        #expect(resolved[WidgetPlacement.Slot.battery.key]?.location == .menuBar)
        #expect(resolved[WidgetPlacement.Slot.quickSettings.key]?.location == .menuBar)
        #expect(resolved[WidgetPlacement.Slot.systemResources.key]?.location == .menuBar)
    }

    @Test
    func storedValuesAlwaysWinOverDefaults() {
        let stored = [
            WidgetPlacement.Slot.connectivity.key: WidgetLocation.dock,
            WidgetPlacement.Slot.calendar.key: WidgetLocation.dock,
            WidgetPlacement.Slot.weather.key: WidgetLocation.dock,
        ]

        for isExistingInstall in [true, false] {
            let resolved = WidgetPlacement.resolve(stored: stored, isExistingInstall: isExistingInstall)

            #expect(resolved[WidgetPlacement.Slot.connectivity.key]?.location == .dock)
            #expect(resolved[WidgetPlacement.Slot.calendar.key]?.location == .dock)
            #expect(resolved[WidgetPlacement.Slot.weather.key]?.location == .dock)
            // Untouched slots still need their default pinned.
            #expect(resolved[WidgetPlacement.Slot.battery.key]?.needsWrite == true)
        }
    }

    @Test
    func aResolvedValueIsNeverWrittenBackWhenItCameFromDisk() {
        let stored = [WidgetPlacement.Slot.battery.key: WidgetLocation.dock]
        let resolved = WidgetPlacement.resolve(stored: stored, isExistingInstall: false)

        #expect(resolved[WidgetPlacement.Slot.battery.key]?.needsWrite == false)
    }

    @Test
    func everySlotIsCoveredExactlyOnce() {
        let keys = WidgetPlacement.Slot.all.map(\.key)

        #expect(keys.count == 6)
        #expect(Set(keys).count == 6)
    }

    @Test
    func onlyDockBarOwnedKeysMarkAnExistingInstall() {
        // macOS seeds a brand new domain with ~90 global keys, so the presence of *any*
        // key says nothing. Only a key DockBar owns means this install predates the change.
        #expect(WidgetPlacement.isExistingInstall(dictionaryRepresentation: [:]) == false)
        #expect(WidgetPlacement.isExistingInstall(dictionaryRepresentation: [
            "AppleLanguages": ["en"],
            "AppleLocale": "en_US",
        ]) == false)
        #expect(WidgetPlacement.isExistingInstall(dictionaryRepresentation: ["dockPosition": "bottomCenter"]) == true)
        // The stamp itself must not be mistaken for a preference, or every later launch
        // would be treated as an upgrade.
        #expect(WidgetPlacement.isExistingInstall(dictionaryRepresentation: [WidgetPlacement.stampKey: true]) == false)
    }

    @Test
    func resolvedPlacementsArePinnedToDisk() {
        let suiteName = "WidgetPlacementTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let placements = defaults.resolvedWidgetPlacements()

        #expect(placements[WidgetPlacement.Slot.connectivity.key] == .menuBar)
        #expect(defaults.object(forKey: WidgetPlacement.stampKey) != nil)
        for slot in WidgetPlacement.Slot.all {
            #expect(defaults.string(forKey: slot.key) == WidgetLocation.menuBar.rawValue, "\(slot.key)")
        }
    }
}
