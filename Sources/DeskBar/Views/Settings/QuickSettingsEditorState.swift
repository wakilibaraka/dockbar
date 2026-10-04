import SwiftUI

/// Backing state for the reorderable Quick Settings toggle editor in Settings.
///
/// Kept out of the view so the editor can be driven from more than one place without
/// re-reading `UserDefaults` each time it appears.
final class QuickSettingsEditorState: ObservableObject {
    @Published var items: [QuickSettingItem] = []

    struct QuickSettingItem: Identifiable, Equatable {
        let id: String
        let title: String
        let symbol: String
        var isEnabled: Bool
    }

    /// Rebuilds the list from the manager's catalogue, honouring the user's saved order
    /// and then the set of toggles they had enabled.
    func load(settings: TaskbarSettings) {
        let enabled = Set(settings.enabledQuickSettings)
        let savedOrder = UserDefaults.standard.stringArray(forKey: "quickSettingsOrder") ?? []
        var byID: [String: QuickSettingItem] = [:]
        for setting in QuickSettingsManager.shared.allSettings {
            byID[setting.id] = QuickSettingItem(
                id: setting.id,
                title: setting.title,
                symbol: setting.symbolName,
                isEnabled: enabled.contains(setting.id)
            )
        }
        var ordered = savedOrder.compactMap { byID.removeValue(forKey: $0) }
        ordered.append(contentsOf: byID.values.sorted { $0.title < $1.title })
        items = ordered
    }

    func persist(into settings: TaskbarSettings) {
        UserDefaults.standard.set(items.map(\.id), forKey: "quickSettingsOrder")
        settings.enabledQuickSettings = items.filter(\.isEnabled).map(\.id)
    }
}