import AppKit
import UserNotifications
import Combine

@MainActor
final class SpeedTestQuickSetting: QuickSetting {
    let id = "speedTest"
    var title: String {
        if controller.isRunning {
            return "Testing..."
        }
        if let last = controller.last {
            return "\(Int(last.down)) Mbps ↓"
        }
        return "Speed Test"
    }
    var symbolName: String {
        return "network"
    }
    var isOn: Bool {
        return controller.isRunning
    }

    let controller: SpeedTestController
    private var observer: Any?

    init() {
        controller = SpeedTestController()
        observer = controller.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshState()
                // Force UI update somehow
                QuickSettingsManager.shared.refreshAll()
            }
        }
    }

    func refreshState() {

    }

    func toggle() {
        if !controller.isRunning {
            controller.run()

            // Wait for it to finish and show notification
            Task {
                while controller.isRunning {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }

                let content = UNMutableNotificationContent()
                if let last = controller.last, !controller.failed {
                    content.title = "Speed Test Complete"
                    content.body = "↓ \(Int(last.down)) Mbps  ↑ \(Int(last.up)) Mbps"
                } else {
                    content.title = "Speed Test Failed"
                    content.body = "Could not complete the network speed test."
                }
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request) { _ in }
            }
        }
    }
}
