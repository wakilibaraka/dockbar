import AppKit
import IOBluetooth

final class BluetoothWidgetView: NSView {
    private let iconView = NSImageView()
    private var timer: Timer?
    private var trackingArea: NSTrackingArea?

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.cornerCurve = .continuous

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.symbolConfiguration = symbolConfig
        iconView.contentTintColor = .labelColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 15),
            iconView.heightAnchor.constraint(equalToConstant: 15),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: 24),
            heightAnchor.constraint(equalToConstant: 24),
        ])

        updateState()

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateState()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea { removeTrackingArea(existing) }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
        }
    }

    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    @objc private func handleClick() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings-extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func connectedDeviceNames() -> [String] {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return [] }
        return devices
            .filter { $0.isConnected() }
            .compactMap { $0.name }
    }

    private func updateState() {
        guard let controller = IOBluetoothHostController.default() else {
            iconView.image = NSImage(systemSymbolName: "bluetooth.slash", accessibilityDescription: "Bluetooth Unavailable")
            toolTip = "Bluetooth: Unavailable"
            return
        }

        let isPowerOn = controller.powerState == kBluetoothHCIPowerStateON
        if isPowerOn {
            iconView.image = NSImage(systemSymbolName: "bluetooth", accessibilityDescription: "Bluetooth On")
                ?? NSImage(named: NSImage.bluetoothTemplateName)
            let connected = connectedDeviceNames()
            if connected.isEmpty {
                toolTip = "Bluetooth: On (no devices connected)"
            } else {
                toolTip = "Bluetooth: \(connected.joined(separator: ", "))"
            }
        } else {
            iconView.image = NSImage(systemSymbolName: "bluetooth.slash", accessibilityDescription: "Bluetooth Off")
            toolTip = "Bluetooth: Off"
        }
    }
}
