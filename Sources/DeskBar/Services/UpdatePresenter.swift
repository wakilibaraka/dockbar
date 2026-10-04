import AppKit

/// Runs an update check and presents the result.
///
/// The bar's context menu and the Settings window both call this, so the wording and
/// the buttons cannot drift apart.
enum UpdatePresenter {
    @MainActor
    static func checkAndPresent() async {
        let result = await UpdateService().check()
        present(result)
    }

    @MainActor
    static func present(_ result: UpdateCheckResult) {
        switch result {
        case let .upToDate(_, latest):
            showAlert(
                title: "DockBar is up to date",
                message: "You are running the latest version (\(latest)).",
                releaseURL: nil
            )
        case let .updateAvailable(current, latest, releaseURL):
            showAlert(
                title: "DockBar \(latest) is available",
                message: "You are running \(current). Open the release page to download it?",
                releaseURL: releaseURL
            )
        case let .failed(message):
            showAlert(
                title: "Could not check for updates",
                message: message,
                releaseURL: nil
            )
        }
    }

    @MainActor
    private static func showAlert(title: String, message: String, releaseURL: URL?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message

        guard let releaseURL else {
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        alert.addButton(withTitle: "Open Release Page")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(releaseURL)
        }
    }
}