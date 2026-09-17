import AppKit
import Combine

struct BatteryState {
    var percentage: Int
    var isCharging: Bool
}

class BatteryMonitor {
    static let shared = BatteryMonitor()
    @Published var state = BatteryState(percentage: 100, isCharging: false)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        BatteryMonitor.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak statusItem] state in
                if let button = statusItem?.button {
                    print("Updating button!")
                    button.title = " \(state.percentage)%"
                } else {
                    print("button is nil!")
                }
            }
            .store(in: &cancellables)

        self.statusItem = statusItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("Status item title is: \(self.statusItem?.button?.title ?? "nil")")
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
