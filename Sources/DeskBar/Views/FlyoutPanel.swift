import AppKit

final class FlyoutPanel: NSPanel {
    private var localMouseDownMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var localKeyboardMonitor: Any?
    private var dismissHandler: (() -> Void)?

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func show(contentViewController: NSViewController, relativeTo rect: NSRect, of view: NSView) {
        self.contentViewController = contentViewController

        guard let window = view.window,
              let screen = window.screen ?? NSScreen.main else { return }

        let screenRect = view.convert(rect, to: nil)
        let anchor = window.convertToScreen(screenRect)

        contentViewController.view.needsLayout = true
        contentViewController.view.layoutSubtreeIfNeeded()
        var fit = contentViewController.view.fittingSize
        
        // If fitting size is 0 (some SwiftUI views without frames), fallback to preferredContentSize
        if fit.width <= 0 || fit.height <= 0 {
            fit = contentViewController.preferredContentSize
        }
        if fit.width <= 0 { fit.width = 320 }
        if fit.height <= 0 { fit.height = 320 }

        let visibleFrame = screen.visibleFrame
        let spacing: CGFloat = 8

        var panelWidth = fit.width
        var panelHeight = fit.height

        var originY = anchor.maxY + spacing
        var originX = anchor.midX - (panelWidth / 2)

        // Clamp width
        if panelWidth > visibleFrame.width {
            panelWidth = visibleFrame.width
        }
        
        // Clamp height
        if originY + panelHeight > visibleFrame.maxY {
            panelHeight = visibleFrame.maxY - originY - spacing
        }
        
        // Ensure it has some minimum height
        if panelHeight < 100 {
            panelHeight = 100 // fallback
        }

        // Clamp X
        if originX < visibleFrame.minX {
            originX = visibleFrame.minX + spacing
        } else if originX + panelWidth > visibleFrame.maxX {
            originX = visibleFrame.maxX - panelWidth - spacing
        }

        let finalFrame = NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight)
        self.setFrame(finalFrame, display: true)
        
        // Wrap in visual effect if not already
        if let view = contentViewController.view as? NSVisualEffectView {
            view.layer?.cornerRadius = 12
            view.layer?.cornerCurve = .continuous
            view.layer?.masksToBounds = true
            view.layer?.borderWidth = 1
            view.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
        } else {
            let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: finalFrame.size))
            effectView.material = .popover
            effectView.blendingMode = .behindWindow
            effectView.state = .active
            effectView.layer?.cornerRadius = 12
            effectView.layer?.cornerCurve = .continuous
            effectView.layer?.masksToBounds = true
            effectView.layer?.borderWidth = 1
            effectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
            
            contentViewController.view.autoresizingMask = [.width, .height]
            contentViewController.view.frame = effectView.bounds
            effectView.addSubview(contentViewController.view)
            self.contentView = effectView
        }

        // Setup monitors
        self.dismissHandler = { [weak self] in
            self?.closePanel()
        }

        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            let point = event.locationInWindow
            if !self.contentView!.frame.contains(point) {
                self.closePanel()
            }
            return event
        }
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }
        localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.closePanel()
                return nil
            }
            return event
        }

        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePanel() {
        if let lm = localMouseDownMonitor { NSEvent.removeMonitor(lm); localMouseDownMonitor = nil }
        if let gm = globalMouseDownMonitor { NSEvent.removeMonitor(gm); globalMouseDownMonitor = nil }
        if let lk = localKeyboardMonitor { NSEvent.removeMonitor(lk); localKeyboardMonitor = nil }
        self.close()
    }
}
