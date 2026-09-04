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
        contentView2.material = .hudWindow
        contentView2.blendingMode = .behindWindow
        contentView2.state = .active
        contentView2.wantsLayer = true
        contentView2.layer?.cornerRadius = 14
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
}
