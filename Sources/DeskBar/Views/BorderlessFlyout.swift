import AppKit

open class BorderlessFlyout: NSPanel {
    private var localMouseDownMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var localKeyboardMonitor: Any?
    var onDismiss: (() -> Void)?
    private weak var positioningView: NSView?
    private var hasFiredDismiss = false
    
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
        self.positioningView = view
        self.hasFiredDismiss = false
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
        
        var panelWidth = fit.width
        var panelHeight = fit.height
        
        var originY: CGFloat
        if anchor.minY > visibleFrame.midY {
            // Anchor is in the top half of the screen (e.g. top dock). Open DOWNWARD.
            originY = anchor.minY - spacing - panelHeight
            if originY < visibleFrame.minY + spacing {
                let overflow = (visibleFrame.minY + spacing) - originY
                panelHeight -= overflow
                originY = visibleFrame.minY + spacing
            }
        } else {
            // Anchor is in the bottom half of the screen (e.g. bottom dock). Open UPWARD.
            originY = anchor.maxY + spacing
            if originY + panelHeight > visibleFrame.maxY - spacing {
                panelHeight = (visibleFrame.maxY - spacing) - originY
            }
        }
        
        var originX = anchor.midX - (panelWidth / 2)
        if panelWidth > visibleFrame.width { panelWidth = visibleFrame.width }
        
        if originX < visibleFrame.minX + spacing {
            originX = visibleFrame.minX + spacing
        } else if originX + panelWidth > visibleFrame.maxX - spacing {
            originX = visibleFrame.maxX - panelWidth - spacing
        }
        
        let finalFrame = NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight)
        self.setFrame(finalFrame, display: true)
        
        if let effectView = contentViewController.view as? NSVisualEffectView {
            setupRoundedCorners(for: effectView)
            self.contentView = effectView
        } else {
            // Check if we need to wrap in a scroll view because we capped the height
            let needsScroll = panelHeight < fit.height && !(contentViewController.view is NSScrollView)
            
            let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: finalFrame.size))
            effectView.material = NSVisualEffectView.Material.popover
            effectView.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
            effectView.state = NSVisualEffectView.State.active
            setupRoundedCorners(for: effectView)
            
            if needsScroll {
                let scrollView = NSScrollView(frame: effectView.bounds)
                scrollView.hasVerticalScroller = true
                scrollView.drawsBackground = false
                scrollView.autoresizingMask = [.width, .height]
                contentViewController.view.frame = NSRect(x: 0, y: 0, width: panelWidth, height: fit.height)
                scrollView.documentView = contentViewController.view
                effectView.addSubview(scrollView)
            } else {
                contentViewController.view.autoresizingMask = [.width, .height]
                contentViewController.view.frame = effectView.bounds
                effectView.addSubview(contentViewController.view)
            }
            
            self.contentView = effectView
        }
        
        if let lm = localMouseDownMonitor { NSEvent.removeMonitor(lm); localMouseDownMonitor = nil }
        if let gm = globalMouseDownMonitor { NSEvent.removeMonitor(gm); globalMouseDownMonitor = nil }
        if let lk = localKeyboardMonitor { NSEvent.removeMonitor(lk); localKeyboardMonitor = nil }
        
        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            
            // If the event is in the flyout window, don't close.
            if event.window == self { return event }
            
            // If the event is in the window containing the positioning view...
            if let posView = self.positioningView, event.window == posView.window {
                // Convert event location to posView coordinates
                let pointInPosView = posView.convert(event.locationInWindow, from: nil)
                if posView.bounds.contains(pointInPosView) {
                    // Clicked exactly on the toggle button! Let the button's action handle closing.
                    return event
                }
            }
            
            // Clicked somewhere else in our app's windows. Close the flyout.
            self.performClose(nil)
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
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupRoundedCorners(for view: NSVisualEffectView) {
        view.wantsLayer = true
        view.layer?.cornerRadius = 14
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
    }
    
    open override func close() {
        if let lm = localMouseDownMonitor { NSEvent.removeMonitor(lm); localMouseDownMonitor = nil }
        if let gm = globalMouseDownMonitor { NSEvent.removeMonitor(gm); globalMouseDownMonitor = nil }
        if let lk = localKeyboardMonitor { NSEvent.removeMonitor(lk); localKeyboardMonitor = nil }
        
        if !hasFiredDismiss {
            hasFiredDismiss = true
            onDismiss?()
        }
        super.close()
    }
    
    open override func performClose(_ sender: Any?) {
        self.close()
    }
}
