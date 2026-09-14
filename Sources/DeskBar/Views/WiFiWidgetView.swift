import AppKit
import CoreWLAN

final class WiFiWidgetView: TrayIconButton {
    private var wifiTimer: Timer?

    init() {
        super.init(symbolName: "wifi", accessibilityLabel: "Wi-Fi")
        button.target = self
        button.action = #selector(handleClick)
        updateState()
        wifiTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.updateState() }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleClick() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func rssiQuality(_ rssi: Int) -> String {
        if rssi >= -50 { return "Excellent" }
        if rssi >= -65 { return "Good" }
        if rssi >= -75 { return "Fair" }
        return "Weak"
    }

    private func updateState() {
        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let client = CWWiFiClient.shared()
        guard let interface = client.interface() else {
            button.image = NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "Wi-Fi Unavailable")?
                .withSymbolConfiguration(cfg)
            toolTip = "Wi-Fi: Unavailable"
            return
        }
        if interface.powerOn() {
            if let ssid = interface.ssid(), !ssid.isEmpty {
                button.image = NSImage(systemSymbolName: "wifi", accessibilityDescription: "Wi-Fi")?
                    .withSymbolConfiguration(cfg)
                let quality = rssiQuality(interface.rssiValue())
                toolTip = "Wi-Fi: \(ssid) (\(quality))"
            } else {
                button.image = NSImage(systemSymbolName: "wifi.exclamationmark", accessibilityDescription: "No Network")?
                    .withSymbolConfiguration(cfg)
                toolTip = "Wi-Fi: Not Connected"
            }
        } else {
            button.image = NSImage(systemSymbolName: "wifi.slash", accessibilityDescription: "Wi-Fi Off")?
                .withSymbolConfiguration(cfg)
            toolTip = "Wi-Fi: Off"
        }
    }
}
