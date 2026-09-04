import AppKit
import Combine

final class QuickSettingsFlyoutPanel: NSPanel {
    private let settings: TaskbarSettings
    private let manager: QuickSettingsManager
    private let contentView2 = NSVisualEffectView()
    private var tileViews: [QuickSettingsTileView] = []
    
    init(settings: TaskbarSettings, manager: QuickSettingsManager) {
        self.settings = settings
        self.manager = manager
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
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
        rebuildTiles()
        
        // Escape key
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.close()
                return nil
            }
            return event
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView2.material = .popover
        contentView2.blendingMode = .behindWindow
        contentView2.state = .active
        contentView2.wantsLayer = true
        contentView2.layer?.cornerRadius = 16
        contentView2.layer?.cornerCurve = .continuous
        contentView2.layer?.masksToBounds = true
        contentView = contentView2
    }
    
    func refreshOnOpen() {
        manager.refreshAll()
        rebuildTiles()
    }
    
    private func rebuildTiles() {
        contentView2.subviews.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()
        
        let enabledSettings = manager.enabledSettings(for: settings.enabledQuickSettings)
        
        let vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.alignment = .leading
        vStack.spacing = 16
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        let header = NSTextField(labelWithString: "Quick Settings")
        header.font = .systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .white
        vStack.addArrangedSubview(header)
        
        let columns = 4
        var rows: [[NSView]] = []
        var currentRow: [NSView] = []
        
        for setting in enabledSettings {
            let tile = QuickSettingsTileView(setting: setting)
            tileViews.append(tile)
            currentRow.append(tile)
            
            if currentRow.count == columns {
                rows.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            while currentRow.count < columns {
                let spacer = NSView()
                spacer.widthAnchor.constraint(equalToConstant: 72).isActive = true
                spacer.heightAnchor.constraint(equalToConstant: 64).isActive = true
                currentRow.append(spacer)
            }
            rows.append(currentRow)
        }
        
        let grid = NSGridView(views: rows)
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        vStack.addArrangedSubview(grid)
        
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        vStack.addArrangedSubview(separator)
        separator.widthAnchor.constraint(equalTo: vStack.widthAnchor).isActive = true
        
        // Volume Slider
        let volStack = NSStackView()
        volStack.orientation = .horizontal
        let volImage = NSImage(systemSymbolName: "speaker.wave.3", accessibilityDescription: nil)!
        volImage.isTemplate = true
        let volIcon = NSImageView(image: volImage)
        volIcon.contentTintColor = .white
        let volSlider = NSSlider(value: 50, minValue: 0, maxValue: 100, target: self, action: #selector(volumeChanged(_:)))
        volStack.addArrangedSubview(volIcon)
        volStack.addArrangedSubview(volSlider)
        volStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.addArrangedSubview(volStack)
        volStack.widthAnchor.constraint(equalTo: vStack.widthAnchor).isActive = true
        
        // Brightness Slider
        let brightStack = NSStackView()
        brightStack.orientation = .horizontal
        let brightImage = NSImage(systemSymbolName: "sun.max", accessibilityDescription: nil)!
        brightImage.isTemplate = true
        let brightIcon = NSImageView(image: brightImage)
        brightIcon.contentTintColor = .white
        let brightSlider = NSSlider(value: 50, minValue: 0, maxValue: 100, target: self, action: #selector(brightnessChanged(_:)))
        brightStack.addArrangedSubview(brightIcon)
        brightStack.addArrangedSubview(brightSlider)
        brightStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.addArrangedSubview(brightStack)
        brightStack.widthAnchor.constraint(equalTo: vStack.widthAnchor).isActive = true
        
        contentView2.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: contentView2.topAnchor, constant: 14),
            vStack.bottomAnchor.constraint(equalTo: contentView2.bottomAnchor, constant: -14),
            vStack.leadingAnchor.constraint(equalTo: contentView2.leadingAnchor, constant: 14),
            vStack.trailingAnchor.constraint(equalTo: contentView2.trailingAnchor, constant: -14)
        ])
        
        vStack.layoutSubtreeIfNeeded()
        var frame = self.frame
        let newSize = vStack.fittingSize
        let delta = (newSize.height + 28) - frame.height
        frame.origin.y -= delta
        frame.size.height = newSize.height + 28
        frame.size.width = newSize.width + 28
        setFrame(frame, display: true)
    }
    
    @objc private func volumeChanged(_ sender: NSSlider) {
        let script = "set volume output volume \(Int(sender.doubleValue))"
        let _ = NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
    
    @objc private func brightnessChanged(_ sender: NSSlider) {
        // Brightness is harder without private APIs. A simple AppleScript placeholder or tool call.
        // We'll leave it as a UI demonstration for Phase 6 as standard apps usually use brightness tool
        // or private APIs like DisplayServices.
    }
}
