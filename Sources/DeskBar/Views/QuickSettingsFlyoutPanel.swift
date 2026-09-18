import Foundation
import CoreGraphics

class DisplayBrightnessService {
    static let shared = DisplayBrightnessService()
    private var setLinearBrightness: @convention(c) (CGDirectDisplayID, Float) -> Int32
    private var getLinearBrightness: @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    
    private init?() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW) else { return nil }
        guard let setSym = dlsym(handle, "DisplayServicesSetLinearBrightness") else { return nil }
        guard let getSym = dlsym(handle, "DisplayServicesGetLinearBrightness") else { return nil }
        
        self.setLinearBrightness = unsafeBitCast(setSym, to: (@convention(c) (CGDirectDisplayID, Float) -> Int32).self)
        self.getLinearBrightness = unsafeBitCast(getSym, to: (@convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32).self)
    }
    
    func getBrightness(for display: CGDirectDisplayID) -> Float? {
        var brightness: Float = 0.0
        let result = getLinearBrightness(display, &brightness)
        return result == 0 ? brightness : nil
    }
    
    func setBrightness(_ brightness: Float, for display: CGDirectDisplayID) {
        _ = setLinearBrightness(display, brightness)
    }
}

import AppKit
import SwiftUI
import CoreAudio

final class QuickSettingsViewController: NSViewController {
    private let settings: TaskbarSettings
    private let manager: QuickSettingsManager
    private let blurView = NSView() // Popover provides its own background/blur
    private var tileViews: [QuickSettingsTileView] = []
    private var volSlider: NSSlider?

    init(settings: TaskbarSettings, manager: QuickSettingsManager) {
        self.settings = settings
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        self.view = blurView
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        refreshOnOpen()
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

        // Tile grid — 3 columns
        let enabledSettings = manager.enabledSettings(for: settings.enabledQuickSettings)
        let columns = 3
        var rows: [[NSView]] = []
        var row: [NSView] = []

        for setting in enabledSettings {
            let tile = QuickSettingsTileView(setting: setting)
            tile.onToggle = { [weak self] in
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
                    spacer.widthAnchor.constraint(equalToConstant: 96),
                    spacer.heightAnchor.constraint(equalToConstant: 48),
                ])
                row.append(spacer)
            }
            rows.append(row)
        }

        if !rows.isEmpty {
            let grid = NSGridView(views: rows)
            grid.rowSpacing = 8
            grid.columnSpacing = 12
            outer.addArrangedSubview(grid)
        }

        // Separator
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        outer.addArrangedSubview(sep)
        sep.widthAnchor.constraint(equalTo: outer.widthAnchor).isActive = true

                // Brightness slider
        if let _ = DisplayBrightnessService.shared {
            let brightRow = makeSliderRow(
                symbol: "sun.max.fill",
                slider: makeBrightnessSlider()
            )
            outer.addArrangedSubview(brightRow)
            brightRow.widthAnchor.constraint(equalTo: outer.widthAnchor).isActive = true
        }

        // Volume slider
        let sliderRow = makeSliderRow(
            symbol: "speaker.wave.2.fill",
            slider: makeVolumeSlider()
        )
        outer.addArrangedSubview(sliderRow)
        sliderRow.widthAnchor.constraint(equalTo: outer.widthAnchor).isActive = true

        // Pin everything
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 14),
            outer.bottomAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -14),
            outer.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: 14),
            outer.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -14),
        ])

        outer.layoutSubtreeIfNeeded()
        let fit = outer.fittingSize
        let popoverW = fit.width + 28
        let popoverH = fit.height + 28
        self.preferredContentSize = NSSize(width: popoverW, height: popoverH)
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

    private func makeBrightnessSlider() -> NSSlider {
        let current = DisplayBrightnessService.shared?.getBrightness(for: CGMainDisplayID()) ?? 0.5
        let slider = NSSlider(value: Double(current * 100), minValue: 0, maxValue: 100,
                              target: self, action: #selector(brightnessChanged(_:)))
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }

    @objc private func brightnessChanged(_ sender: NSSlider) {
        let val = Float(sender.doubleValue / 100.0)
        DisplayBrightnessService.shared?.setBrightness(val, for: CGMainDisplayID())
    }

    private func makeVolumeSlider() -> NSSlider {
        let slider = NSSlider(value: Double(currentVolume() * 100), minValue: 0, maxValue: 100,
                              target: self, action: #selector(volumeChanged(_:)))
        slider.translatesAutoresizingMaskIntoConstraints = false
        volSlider = slider
        return slider
    }

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
