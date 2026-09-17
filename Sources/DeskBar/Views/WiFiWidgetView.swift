import AppKit
import CoreWLAN
import Combine

final class WiFiWidgetView: TrayIconButton {
    private var cancellables = Set<Combine.AnyCancellable>()

    init() {
        super.init(symbolName: "wifi", accessibilityLabel: "Wi-Fi")
        button.target = self
        button.action = #selector(handleClick)
        
        rightAction = {
            if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
                NSWorkspace.shared.open(url)
            }
        }
        
        updateState()
        SharedTimer.shared.tick5s
            .sink { [weak self] _ in
                self?.updateState()
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleClick() {
        guard let interface = CWWiFiClient.shared().interface() else { return }
        do {
            try interface.setPower(!interface.powerOn())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.updateState()
            }
        } catch {
            print("Failed to toggle Wi-Fi: \(error)")
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
