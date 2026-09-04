import AppKit
import Combine

/// Tracks apps that the user quits and provides a way to relaunch the most recently quit one.
final class RecentlyQuitAppsService {
    struct QuitRecord {
        let bundleIdentifier: String
        let bundleURL: URL
        let displayName: String
    }

    private(set) var recentlyQuit: [QuitRecord] = []
    private let maxRecords = 10

    private var terminationObserver: NSObjectProtocol?
    private var shortcutMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private let settings: TaskbarSettings

    // Our own bundle ID so we never record ourselves
    private static let ownBundleID = Bundle.main.bundleIdentifier ?? "com.deskbar.app"

    init(settings: TaskbarSettings) {
        self.settings = settings
        startObserving()
        bindSettings()
    }

    deinit {
        stopShortcutMonitor()
        if let obs = terminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }

    // MARK: - Observation

    private func startObserving() {
        terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleTermination(notification)
        }
    }

    private func handleTermination(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }

        let bundleID = app.bundleIdentifier ?? ""
        // Skip ourselves and bare background agents (no bundle ID or activation policy = accessory/prohibited)
        guard !bundleID.isEmpty,
              bundleID != Self.ownBundleID,
              app.activationPolicy == .regular else { return }

        // Resolve bundle URL — prefer the running app's URL, fallback to NSWorkspace lookup
        let url = app.bundleURL
            ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)

        guard let bundleURL = url else { return }

        let displayName = app.localizedName
            ?? FileManager.default.displayName(atPath: bundleURL.path)

        let record = QuitRecord(bundleIdentifier: bundleID, bundleURL: bundleURL, displayName: displayName)

        // Deduplicate: remove any earlier entry for this same app
        recentlyQuit.removeAll { $0.bundleIdentifier == bundleID }
        recentlyQuit.insert(record, at: 0)
        if recentlyQuit.count > maxRecords {
            recentlyQuit.removeLast()
        }
    }

    // MARK: - Reopen

    /// Relaunches the most recently quit app. Pops it off the stack on success.
    func reopenLast() {
        guard settings.enableReopenLastQuit else { return }
        guard !recentlyQuit.isEmpty else {
            // Nothing to reopen — subtle feedback (bounce the Dock icon briefly is not possible from LSUIElement; use NSBeep)
            NSSound.beep()
            return
        }

        let record = recentlyQuit[0]

        // Verify the bundle still exists at the recorded URL
        let fm = FileManager.default
        if !fm.fileExists(atPath: record.bundleURL.path) {
            // Try to find the app by bundle ID via NSWorkspace
            if let freshURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: record.bundleIdentifier) {
                relaunch(url: freshURL, record: record)
            } else {
                // App has moved or been uninstalled — pop and log
                recentlyQuit.removeFirst()
                NSLog("[RecentlyQuitAppsService] Cannot reopen \(record.displayName): bundle not found at \(record.bundleURL.path)")
            }
            return
        }

        relaunch(url: record.bundleURL, record: record)
    }

    private func relaunch(url: URL, record: QuitRecord) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    NSLog("[RecentlyQuitAppsService] Failed to reopen \(record.displayName): \(error.localizedDescription)")
                } else {
                    self?.recentlyQuit.removeFirst()
                }
            }
        }
    }

    // MARK: - Global shortcut (⌥⌘T)

    private func bindSettings() {
        settings.$enableReopenLastQuit
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                if enabled {
                    self?.installShortcutMonitor()
                } else {
                    self?.stopShortcutMonitor()
                }
            }
            .store(in: &cancellables)
    }

    private func installShortcutMonitor() {
        guard shortcutMonitor == nil else { return }
        shortcutMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ⌥⌘T: keyCode 17 (t), modifiers = option + command
            guard event.keyCode == 17,
                  event.modifierFlags.intersection([.option, .command, .shift, .control]) == [.option, .command]
            else { return }
            DispatchQueue.main.async {
                self?.reopenLast()
            }
        }
    }

    private func stopShortcutMonitor() {
        if let m = shortcutMonitor {
            NSEvent.removeMonitor(m)
            shortcutMonitor = nil
        }
    }
}
