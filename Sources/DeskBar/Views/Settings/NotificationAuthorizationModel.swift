import Foundation
import UserNotifications

/// Tracks whether DockBar may post notifications, so the Settings permission row can
/// report the real state instead of guessing.
///
/// `@State` is unusable on this toolchain (its macro fails to expand), so view-local
/// state is an `ObservableObject` like this one.
@MainActor
final class NotificationAuthorizationModel: ObservableObject {
    @Published var isAuthorized = false

    func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func request() async {
        _ = await withCheckedContinuation { continuation in
            NotificationManager.shared.requestAuthorization { _ in
                continuation.resume()
            }
        }
        await refresh()
    }
}