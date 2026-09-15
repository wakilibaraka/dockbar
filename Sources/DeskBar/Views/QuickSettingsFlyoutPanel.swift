import AppKit
import SwiftUI
import CoreAudio

final class QuickSettingsFlyoutPanel: NSPanel {
    private let settings: TaskbarSettings
    private let manager: QuickSettingsManager
    private let blurView = NSVisualEffectView()
    private var tileViews: [QuickSettingsTileView] = []
    private var volSlider: NSSlider?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(settings: TaskbarSettings, manager: QuickSettingsManager) {
        self.settings = settings
        self.manager = manager
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .transient]

        setupUI()

        // Close on Escape or click outside
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.close(); return nil }
            return event
        }
    }

    // MARK: - Lifecycle
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        setupMonitors()
    }
    
    override func close() {
        super.close()
        removeMonitors()
    }
    
    private func setupMonitors() {
        guard localMonitor == nil else { return }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible else { return event }
            let location = event.locationInWindow
            if self.contentView?.frame.contains(location) == false {
                self.close()
            }
            return event
        }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }
    
    private func removeMonitors() {
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
            localMonitor = nil
        }
        if let global = globalMonitor {
            NSEvent.removeMonitor(global)
            globalMonitor = nil
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        blurView.material = .popover
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 14
        blurView.layer?.cornerCurve = .continuous
        blurView.layer?.masksToBounds = true
        contentView = blurView
    }

    func refreshOnOpen() {
        manager.refreshAll()
        rebuildContent()
    }

    // MARK: - Content

    private func rebuildContent() {
        blurView.subviews.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()

        let outer = NSStackView()
        outer.orientation = .vertical
        outer.alignment = .leading
        outer.spacing = 12
        outer.translatesAutoresizingMaskIntoConstraints = false
        blurView.addSubview(outer)

        let hostingView = NSHostingView(rootView: CalendarView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.widthAnchor.constraint(equalToConstant: 312).isActive = true
        hostingView.heightAnchor.constraint(equalToConstant: 360).isActive = true
        outer.addArrangedSubview(hostingView)

        let sep2 = NSBox()
        sep2.boxType = .separator
        sep2.translatesAutoresizingMaskIntoConstraints = false
        outer.addArrangedSubview(sep2)
        sep2.widthAnchor.constraint(equalTo: outer.widthAnchor).isActive = true

        // Header
        let header = NSTextField(labelWithString: "Quick Settings")
        header.font = .systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .labelColor
        outer.addArrangedSubview(header)

        // Tile grid — 4 columns
        let enabledSettings = manager.enabledSettings(for: settings.enabledQuickSettings)
        let columns = 4
        var rows: [[NSView]] = []
        var row: [NSView] = []

        for setting in enabledSettings {
            let tile = QuickSettingsTileView(setting: setting)
            tile.onToggle = { [weak self] in
                // refresh all tiles after any toggle for inter-dependent states
                self?.tileViews.forEach { $0.refresh() }
            }
            tileViews.append(tile)
            row.append(tile)
            if row.count == columns {
                rows.append(row); row = []
            }
        }
        if !row.isEmpty {
            while row.count < columns {
                let spacer = NSView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    spacer.widthAnchor.constraint(equalToConstant: 72),
                    spacer.heightAnchor.constraint(equalToConstant: 64),
                ])
                row.append(spacer)
            }
            rows.append(row)
        }

        if !rows.isEmpty {
            let grid = NSGridView(views: rows)
            grid.rowSpacing = 8
            grid.columnSpacing = 8
            outer.addArrangedSubview(grid)
        }

        // Separator
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        outer.addArrangedSubview(sep)
        sep.widthAnchor.constraint(equalTo: outer.widthAnchor).isActive = true

        // Volume slider
        outer.addArrangedSubview(makeSliderRow(
            symbol: "speaker.wave.2.fill",
            slider: makeVolumeSlider()
        ))

        // Pin everything
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 14),
            outer.bottomAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -14),
            outer.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: 14),
            outer.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -14),
        ])

        // Compute size then clamp to screen
        outer.layoutSubtreeIfNeeded()
        let fit = outer.fittingSize
        let panelW = fit.width + 28
        let panelH = fit.height + 28

        // keep current origin but clamp
        let origin = self.frame.origin
        var newFrame = NSRect(x: origin.x, y: origin.y, width: panelW, height: panelH)
        if let screen = self.screen ?? NSScreen.main {
            let vis = screen.visibleFrame
            if newFrame.maxX > vis.maxX - 8 { newFrame.origin.x = vis.maxX - newFrame.width - 8 }
            if newFrame.minX < vis.minX + 8  { newFrame.origin.x = vis.minX + 8 }
            if newFrame.maxY > vis.maxY - 8  { newFrame.origin.y = vis.maxY - newFrame.height - 8 }
            if newFrame.minY < vis.minY + 8  { newFrame.origin.y = vis.minY + 8 }
        }
        setFrame(newFrame, display: false)
    }

    // MARK: - Helpers

    private func makeSliderRow(symbol: String, slider: NSSlider) -> NSStackView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false

        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
        icon.contentTintColor = .labelColor
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
        ])
        row.addArrangedSubview(icon)
        row.addArrangedSubview(slider)
        return row
    }

    private func makeVolumeSlider() -> NSSlider {
        let slider = NSSlider(value: Double(currentVolume() * 100), minValue: 0, maxValue: 100,
                              target: self, action: #selector(volumeChanged(_:)))
        slider.translatesAutoresizingMaskIntoConstraints = false
        volSlider = slider
        return slider
    }

    // MARK: - Volume via CoreAudio

    private func defaultOutputDeviceID() -> AudioObjectID {
        var devID = AudioObjectID(kAudioObjectUnknown)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &devID)
        return devID
    }

    private func currentVolume() -> Float {
        let devID = defaultOutputDeviceID()
        guard devID != kAudioObjectUnknown else { return 0.5 }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 1) // channel 1 (master)
        var vol: Float32 = 0.5
        var size = UInt32(MemoryLayout<Float32>.size)
        AudioObjectGetPropertyData(devID, &addr, 0, nil, &size, &vol)
        return vol
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        let devID = defaultOutputDeviceID()
        guard devID != kAudioObjectUnknown else { return }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 1)
        var vol = Float32(sender.doubleValue / 100.0)
        let size = UInt32(MemoryLayout<Float32>.size)
        AudioObjectSetPropertyData(devID, &addr, 0, nil, size, &vol)
    }
}
