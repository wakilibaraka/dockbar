import Foundation

/// Where each widget lives, resolved once at launch.
///
/// DockBar v0.6 flips every widget's default to the menu bar so a fresh install starts
/// with a clean bar: the taskbar shows windows, the menu bar shows status. That default
/// must *not* reach installs that already exist, or every widget would jump out of the
/// user's bar on upgrade without them asking. So the table below carries both the
/// shipping default and the one from the previous release, and the resolver picks per
/// install:
///
/// * a key in `UserDefaults` always wins — that is the user's own choice;
/// * an install that predates the stamp keeps the v0.5 default, which is then written out
///   so the choice is pinned from then on;
/// * a fresh install takes the v0.6 default.
///
/// The resolver is pure so all three cases are testable without touching a real
/// defaults domain.
enum WidgetPlacement {
    /// One widget's placement row.
    struct Slot: Equatable {
        /// `UserDefaults` key this placement is persisted under.
        let key: String
        /// Where the widget lived before v0.6.
        let legacyDefault: WidgetLocation
        /// Where the widget lives for a fresh install.
        var shippingDefault: WidgetLocation { .menuBar }

        static let connectivity = Slot(key: "connectivityTrayLocation", legacyDefault: .dock)
        static let calendar = Slot(key: "calendarLocation", legacyDefault: .dock)
        static let quickSettings = Slot(key: "quickSettingsLocation", legacyDefault: .menuBar)
        static let systemResources = Slot(key: "systemResourceWidgetLocation", legacyDefault: .menuBar)
        static let battery = Slot(key: "batteryWidgetLocation", legacyDefault: .menuBar)
        static let weather = Slot(key: "weatherWidgetLocation", legacyDefault: .dock)

        static let all: [Slot] = [.connectivity, .calendar, .quickSettings, .systemResources, .battery, .weather]
    }

    /// Written the first time a resolved placement is pinned to disk. Its presence is what
    /// tells a later launch that the defaults have already been decided for this install.
    static let stampKey = "widgetPlacementDefaultsPinned"

    /// A placement decided at launch: where the widget goes, and whether that value still
    /// needs writing because it came from a default rather than from disk.
    struct Resolution: Equatable {
        var location: WidgetLocation
        /// `true` when `location` came from a default and should be persisted now.
        var needsWrite: Bool
    }

    /// Resolves every slot.
    ///
    /// - Parameters:
    ///   - stored: the raw strings found under each slot's key in `UserDefaults`.
    ///   - isExistingInstall: `true` for installs created before v0.6.
    static func resolve(stored: [String: WidgetLocation], isExistingInstall: Bool) -> [String: Resolution] {
        var result: [String: Resolution] = [:]
        for slot in Slot.all {
            if let storedValue = stored[slot.key] {
                result[slot.key] = Resolution(location: storedValue, needsWrite: false)
            } else {
                let fallback = isExistingInstall ? slot.legacyDefault : slot.shippingDefault
                result[slot.key] = Resolution(location: fallback, needsWrite: true)
            }
        }
        return result
    }

    /// Decides whether the defaults domain belongs to an install that predates v0.6.
    ///
    /// "The domain is empty" is *not* a usable test: macOS seeds every domain it creates
    /// with roughly ninety global keys (`AppleLanguages`, `AppleLocale`, …), so a brand new
    /// install looks populated too. The signal that actually separates the two cases is
    /// whether the domain holds a key DockBar itself owns, and `SettingsCatalog` is exactly
    /// the list of those keys.
    ///
    /// An install that predates v0.6 but never had a setting changed has no DockBar key
    /// either, and is treated as fresh. That is the right answer anyway: it had no
    /// placement of its own to preserve, so it gets the new defaults like everyone else.
    static func isExistingInstall(dictionaryRepresentation: [String: Any]) -> Bool {
        let ownedKeys = Set(SettingsCatalog.all.map(\.id))
        return dictionaryRepresentation.keys.contains { ownedKeys.contains($0) }
    }
}

extension UserDefaults {
    /// Reads the widget placements and pins the resolved defaults back to disk.
    ///
    /// Returns the placements keyed by slot key, ready for the settings initialiser to
    /// unpack. Safe to call on every launch: once the stamp is present the upgrade path
    /// never runs again.
    func resolvedWidgetPlacements() -> [String: WidgetLocation] {
        let stored: [String: WidgetLocation] = Dictionary(
            uniqueKeysWithValues: WidgetPlacement.Slot.all.compactMap { slot -> (String, WidgetLocation)? in
                guard let raw = string(forKey: slot.key),
                      let location = WidgetLocation(rawValue: raw) else { return nil }
                return (slot.key, location)
            }
        )

        let isExistingInstall = object(forKey: WidgetPlacement.stampKey) == nil
            && WidgetPlacement.isExistingInstall(dictionaryRepresentation: dictionaryRepresentation())

        let resolved = WidgetPlacement.resolve(stored: stored, isExistingInstall: isExistingInstall)
        for (key, resolution) in resolved where resolution.needsWrite {
            set(resolution.location.rawValue, forKey: key)
        }
        if object(forKey: WidgetPlacement.stampKey) == nil {
            set(true, forKey: WidgetPlacement.stampKey)
        }

        return resolved.reduce(into: [String: WidgetLocation]()) { $0[$1.key] = $1.value.location }
    }
}
