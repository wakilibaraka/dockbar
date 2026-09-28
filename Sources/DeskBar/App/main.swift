import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = assumeOnMainActor()
app.delegate = delegate
app.run()

func assumeOnMainActor() -> AppDelegate {
    if #available(macOS 10.15, *) {
        return MainActor.assumeIsolated {
            return AppDelegate()
        }
    } else {
        fatalError()
    }
}