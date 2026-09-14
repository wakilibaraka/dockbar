import AppKit
import CoreWLAN

final class WiFiQuickSetting: QuickSetting {
    let id = "wifi"
    let title = "Wi-Fi"
    var symbolName: String { isOn ? "wifi" : "wifi.slash" }
    var settingsURL: URL? { URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") }
    var isOn: Bool = false

    init() { refreshState() }

    func refreshState() {
        isOn = CWWiFiClient.shared().interface()?.powerOn() ?? false
    }

    func toggle() {
        guard let iface = CWWiFiClient.shared().interface() else { return }
        do {
            try iface.setPower(!isOn)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshState()
            }
        } catch {
            print("Wi-Fi toggle failed: \(error)")
        }
    }
}
