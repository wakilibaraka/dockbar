import AppKit

import DockBarCore

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
        let finalFrame = FlyoutGeometry.calculateFrame(
            anchor: anchor,
            contentSize: fit,
            visibleFrame: visibleFrame,
            spacing: 12
        )
        
        let opensUpward = anchor.minY <= visibleFrame.midY
        let startFrame = NSRect(
            x: finalFrame.origin.x,
            y: opensUpward ? finalFrame.origin.y - 10 : finalFrame.origin.y + 10,
            width: finalFrame.width,
            height: finalFrame.height
        )
        
        self.alphaValue = 0
        self.setFrame(startFrame, display: true)
        
        if let effectView = contentViewController.view as? NSVisualEffectView {
            setupRoundedCorners(for: effectView)
            self.contentView = effectView
        } else {
            let needsScroll = finalFrame.height < fit.height && !(contentViewController.view is NSScrollView)
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
                contentViewController.view.frame = NSRect(x: 0, y: 0, width: finalFrame.width, height: fit.height)
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
            if event.window == self { return event }
            if let posView = self.positioningView, event.window == posView.window {
                let pointInPosView = posView.convert(event.locationInWindow, from: nil)
                if posView.bounds.contains(pointInPosView) { return event }
            }
            self.performClose(nil)
            return event
        }
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.performClose(nil)
        }
        localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
                self?.performClose(nil)
                return nil
            }
            return event
        }
        
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
            self.animator().setFrame(finalFrame, display: true)
        })
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
        
        let opensUpward = (self.positioningView?.window?.frame.minY ?? 0) <= (NSScreen.main?.visibleFrame.midY ?? 0)
        let endFrame = NSRect(
            x: frame.origin.x,
            y: opensUpward ? frame.origin.y - 10 : frame.origin.y + 10,
            width: frame.width,
            height: frame.height
        )
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
            self.animator().setFrame(endFrame, display: true)
        }, completionHandler: {
            super.close()
        })
    }
    
    open override func performClose(_ sender: Any?) {
        self.close()
    }
}
