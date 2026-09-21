import Foundation

@MainActor
final class QuickSettingsManager {
    nonisolated(unsafe) static let shared = QuickSettingsManager()
    
    /// All available quick settings, indexed by id
    let allSettings: [QuickSetting] = [
        WiFiQuickSetting(),
        BluetoothQuickSetting(),
        DarkModeQuickSetting(),
        TrueToneQuickSetting(),
        MuteAudioQuickSetting(),
        MuteMicQuickSetting(),
        KeepAwakeQuickSetting(),
        AutohideDockQuickSetting(),
        AutohideMenuBarQuickSetting(),
        HiddenFilesQuickSetting(),
        ShowFinderPathBarQuickSetting(),
        ShowExtensionsQuickSetting(),
        ShowUserLibraryQuickSetting(),
        DockRecentAppsQuickSetting(),
        ScreenshotQuickSetting(),
        RestartFinderQuickSetting(),
        EmptyTrashQuickSetting(),
        EmptyPasteboardQuickSetting(),
        EjectDiscsQuickSetting(),
        ScreenSaverQuickSetting(),
        HideDesktopQuickSetting(),
        SmallLaunchpadQuickSetting(),
        XcodeCacheQuickSetting(),
        PomodoroQuickSetting(),
        KeyboardLockQuickSetting(),
        SpeedTestQuickSetting(),
    ]
    
    private let settingsMap: [String: QuickSetting]
    
    private init() {
        settingsMap = Dictionary(uniqueKeysWithValues: allSettings.map { ($0.id, $0) })
    }
    
    func enabledSettings(for ids: [String]) -> [QuickSetting] {
        ids.compactMap { settingsMap[$0] }
    }
    
    func refreshAll() {
        allSettings.forEach { $0.refreshState() }
    }
}
