import AppKit
import Combine

struct BatteryState {
    var percentage: Int
    var isCharging: Bool
}
struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState) -> NSImage {
        let image = NSImage(size: NSSize(width: 28, height: 14))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 28, height: 14).fill()
        image.unlockFocus()
        return image
    }
}
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var cancellables = Set<AnyCancellable>()
    @Published var state = BatteryState(percentage: 95, isCharging: false)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        $state
            .receive(on: DispatchQueue.main)
            .sink { [weak statusItem] state in
                print("Sink executed! statusItem exists? \(statusItem != nil)")
                if let button = statusItem?.button {
                    button.image = BatteryStatusRenderer.renderImage(for: state)
                    button.title = " \(state.percentage)%"
                    button.imagePosition = .imageLeft
                    print("Button title set to \(button.title)")
                }
            }
            .store(in: &cancellables)

        self.statusItem = statusItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("Status Item Title: \(self.statusItem?.button?.title ?? "nil")")
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
