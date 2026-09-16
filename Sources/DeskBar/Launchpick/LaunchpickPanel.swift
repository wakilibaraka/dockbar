import Cocoa

class LaunchpickPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        
        let blurView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 720, height: 400))
        blurView.material = .popover
        blurView.state = .active
        blurView.blendingMode = .behindWindow
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 12
        blurView.layer?.masksToBounds = true
        blurView.autoresizingMask = [.width, .height]
        self.contentView = blurView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
