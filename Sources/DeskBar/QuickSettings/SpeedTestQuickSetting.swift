import AppKit

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
        }
    }
}
