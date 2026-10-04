import AppKit

open class BorderlessFlyout: NSPanel {
    private var localMouseDownMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var localKeyboardMonitor: Any?
    
    var isShown: Bool { isVisible }
    
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        self.isFloatingPanel = true
        self.level = .popUpMenu
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
    }
    
    open override var canBecomeKey: Bool { true }
    open override var canBecomeMain: Bool { true }
    
    func show(contentViewController: NSViewController, relativeTo rect: NSRect, of view: NSView) {
        self.contentViewController = contentViewController
        
        guard let window = view.window,
              let screen = window.screen ?? NSScreen.main else { return }
        
        let screenRect = view.convert(rect, to: nil)
        let anchor = window.convertToScreen(screenRect)
        
        contentViewController.view.layoutSubtreeIfNeeded()
        var fit = contentViewController.view.fittingSize
        
        if fit.width <= 0 { fit.width = contentViewController.preferredContentSize.width }
        if fit.height <= 0 { fit.height = contentViewController.preferredContentSize.height }
        if fit.width <= 0 { fit.width = 300 }
        if fit.height <= 0 { fit.height = 300 }
        
        let visibleFrame = screen.visibleFrame
        let spacing: CGFloat = 12
        
        // Placement rules live in FlyoutLayout so they are unit-tested: prefer below the
        // anchor, flip above when it does not fit, and only clamp as a last resort so a
        // tall panel is never squashed into unreadability.
        let placement = FlyoutLayout.placement(
            anchor: anchor,
            contentSize: fit,
            visibleFrame: visibleFrame,
            spacing: spacing
        )
        self.setFrame(placement.frame, display: true)
        
        if let effectView = contentViewController.view as? NSVisualEffectView {
            setupRoundedCorners(for: effectView)
        } else {
            let effectView = NSVisualEffectView(frame: self.contentView?.bounds ?? NSRect.zero)
            effectView.material = NSVisualEffectView.Material.popover
            effectView.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
            effectView.state = NSVisualEffectView.State.active
            setupRoundedCorners(for: effectView)
            
            contentViewController.view.autoresizingMask = [.width, .height]
            contentViewController.view.frame = effectView.bounds
            effectView.addSubview(contentViewController.view)
            self.contentView = effectView
        }
        
        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            let point = event.locationInWindow
            if !self.contentView!.frame.contains(point) {
                self.performClose(nil)
            }
            return event
        }
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.performClose(nil)
        }
        localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.performClose(nil)
                return nil
            }
            return event
        }
        
        self.makeKeyAndOrderFront(nil)
        NSApp.activateCompat()
    }
    
    /// Taskbar flyouts are smooth, corner-continuous rounded rectangles. There is
    /// deliberately no notch or pointer here - those belong to the menu-bar panels, which
    /// are allowed to point back at their status item.
    private func setupRoundedCorners(for view: NSVisualEffectView) {
        view.layer?.cornerRadius = 14
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
    }
    
    open override func performClose(_ sender: Any?) {
        if let lm = localMouseDownMonitor { NSEvent.removeMonitor(lm); localMouseDownMonitor = nil }
        if let gm = globalMouseDownMonitor { NSEvent.removeMonitor(gm); globalMouseDownMonitor = nil }
        if let lk = localKeyboardMonitor { NSEvent.removeMonitor(lk); localKeyboardMonitor = nil }
        self.close()
    }
}
