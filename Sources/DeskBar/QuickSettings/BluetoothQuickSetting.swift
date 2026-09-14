import AppKit

final class BluetoothQuickSetting: QuickSetting {
    let id = "bluetooth"
    let title = "Bluetooth"
    let symbolName = "" // Not used
    var customImage: NSImage? { NSImage.bluetoothIcon() }
    var settingsURL: URL? { URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") }
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = UserDefaults(suiteName: "com.apple.Bluetooth")?.bool(forKey: "ControllerPowerState") ?? false
    }
    
    func toggle() {
        let newValue = !isOn
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        proc.arguments = ["write", "com.apple.Bluetooth", "ControllerPowerState", "-int", newValue ? "1" : "0"]
        try? proc.run()
        proc.waitUntilExit()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshState()
        }
    }
}
