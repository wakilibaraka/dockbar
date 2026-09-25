import AppKit
import Combine

final class TaskbarPanel: NSPanel {
    private static let minimumContentHeight: CGFloat = 32
    private static let compactHorizontalMargin: CGFloat = 12
    private static let compactMinimumWidth: CGFloat = 420
    private static let compactFallbackWidth: CGFloat = 860
    private static let glassHorizontalMargin: CGFloat = 12

    let displayID: CGDirectDisplayID

    private let permissionsManager: PermissionsManager
    private let settings: TaskbarSettings
    private let rootView: TaskbarPanelRootView
    private let chromeShadowView: NSView
    private let visualEffectView: NSVisualEffectView
    private weak var hostedView: NSView?
    private var cancellables = Set<AnyCancellable>()
    private var pendingNormalizationFrame: NSRect?
    private var frameNormalizationScheduled = false

    init(
        permissionsManager: PermissionsManager,
        settings: TaskbarSettings,
        screen: NSScreen
    ) {
        self.displayID = ScreenGeometry.displayID(for: screen) ?? CGMainDisplayID()
        self.permissionsManager = permissionsManager
        self.settings = settings

        let frame = Self.panelFrame(
            isAccessibilityGranted: permissionsManager.isAccessibilityGranted,
            taskbarHeight: settings.taskbarHeight,
            layoutMode: settings.layoutMode,
            screen: screen
        )

        rootView = TaskbarPanelRootView(settings: settings, frame: NSRect(origin: .zero, size: frame.size))
        rootView.setPreferredCarrierSize(frame.size)
        chromeShadowView = NSView(frame: NSRect(origin: .zero, size: frame.size))
        visualEffectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .statusBar
        isFloatingPanel = true
        hidesOnDeactivate = false
        backgroundColor = .clear
        isMovableByWindowBackground = false
        isOpaque = false
        hasShadow = false

        rootView.autoresizingMask = [.width, .height]
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.clear.cgColor

        chromeShadowView.autoresizingMask = [.width, .height]
        chromeShadowView.wantsLayer = true
        chromeShadowView.layer?.backgroundColor = NSColor.clear.cgColor

        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.borderWidth = 0.5
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        chromeShadowView.addSubview(visualEffectView)
        rootView.addSubview(chromeShadowView)
        rootView.chromeView = chromeShadowView
        contentView = rootView
        updateChromeLayout(animated: false)

        settings.$taskbarHeight
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFrameForCurrentState(animated: true)
            }
            .store(in: &cancellables)

        settings.$layoutMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFrameForCurrentState(animated: true)
            }
            .store(in: &cancellables)
    }

    func setContentSubview(_ view: NSView) {
        hostedView?.removeFromSuperview()
        view.frame = visualEffectView.bounds
        view.autoresizingMask = [.width, .height]
        visualEffectView.addSubview(view)
        hostedView = view
        updateFrameForCurrentState(animated: false)
    }

    func updateForAccessibilityPermissionChange() {
        updateFrameForCurrentState(animated: true)
    }

    func updateFrame(for screen: NSScreen) {
        updateFrameForCurrentState(animated: true, screen: screen)
    }

    func requestLayoutUpdate(animated: Bool) {
        updateFrameForCurrentState(animated: animated)
    }

    func updateCollectionBehavior(showOverFullScreenApps: Bool) {
        var behavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if showOverFullScreenApps {
            behavior.insert(.fullScreenAuxiliary)
        }

        collectionBehavior = behavior
    }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    private func updateFrameForCurrentState(animated: Bool, screen: NSScreen? = nil) {
        let resolvedScreen = screen ??
            ScreenGeometry.screen(for: displayID) ??
            self.screen ??
            NSScreen.screens.first

        let nextFrame = Self.panelFrame(
            isAccessibilityGranted: permissionsManager.isAccessibilityGranted,
            taskbarHeight: settings.taskbarHeight,
            layoutMode: settings.layoutMode,
            screen: resolvedScreen
        )

        rootView.setPreferredCarrierSize(nextFrame.size)
        let frameChanged = !Self.framesApproximatelyEqual(frame, nextFrame)
        if frameChanged {
            setFrame(nextFrame, display: true, animate: false)
        }
        rootView.frame = NSRect(origin: .zero, size: nextFrame.size)

        updateChromeLayout(animated: animated)
        scheduleFrameNormalization(to: nextFrame)
    }

    private func updateChromeLayout(animated: Bool) {
        let compactContentWidth = settings.layoutMode.usesCompactWidth ? compactContentWidth() : nil
        let chromeFrame = Self.chromeFrame(
            layoutMode: settings.layoutMode,
            compactContentWidth: compactContentWidth,
            bounds: rootView.bounds
        )

        if !Self.framesApproximatelyEqual(chromeShadowView.frame, chromeFrame) {
            chromeShadowView.frame = chromeFrame
        }

        let effectFrame = chromeShadowView.bounds
        if !Self.framesApproximatelyEqual(visualEffectView.frame, effectFrame) {
            visualEffectView.frame = effectFrame
        }

        let hostedFrame = visualEffectView.bounds
        if let hostedView, !Self.framesApproximatelyEqual(hostedView.frame, hostedFrame) {
            hostedView.frame = hostedFrame
        }
        updateVisualStyle(for: chromeFrame)
    }

    private static func panelFrame(
        isAccessibilityGranted: Bool,
        taskbarHeight: CGFloat,
        layoutMode: DeskBarLayoutMode,
        screen: NSScreen?
    ) -> NSRect {
        guard let screen else {
            return .zero
        }

        let contentHeight = max(taskbarHeight, minimumContentHeight)
        let height = contentHeight

        var yPos = screen.frame.origin.y
        if layoutMode == .floatingCenter {
            yPos += 12 // margin from screen edge
        }
        
        return NSRect(
            x: screen.frame.origin.x,
            y: yPos,
            width: screen.frame.width,
            height: height
        )
    }

    private static func chromeFrame(
        layoutMode: DeskBarLayoutMode,
        compactContentWidth: CGFloat?,
        bounds: NSRect
    ) -> NSRect {
        let width: CGFloat

        switch layoutMode {
        case .fullWidth, .windows11:
            width = bounds.width
        case .fullWidthGlass:
            width = max(120, bounds.width - glassHorizontalMargin * 2)
        case .compact, .compactGlass, .floatingCenter:
            let maximumWidth = max(120, bounds.width - compactHorizontalMargin * 2)
            let minimumWidth = min(compactMinimumWidth, maximumWidth)
            let desiredWidth = compactContentWidth ?? min(compactFallbackWidth, maximumWidth)
            width = min(max(ceil(desiredWidth), minimumWidth), maximumWidth)
        }

        let originX = bounds.minX + floor((bounds.width - width) / 2)
        return NSRect(
            x: originX,
            y: bounds.minY,
            width: width,
            height: bounds.height
        )
    }

    private func compactContentWidth() -> CGFloat? {
        guard let taskbarContentView = hostedView as? TaskbarContentView else {
            return hostedView?.fittingSize.width
        }

        return taskbarContentView.preferredCompactWidth()
    }

    private func updateVisualStyle(for frame: NSRect) {
        let usesGlassChrome = settings.layoutMode.usesGlassChrome
        let cornerRadius = usesGlassChrome ? min(frame.height / 2, 18) : 0

        chromeShadowView.layer?.cornerRadius = cornerRadius
        chromeShadowView.layer?.masksToBounds = false
        chromeShadowView.layer?.shadowColor = NSColor.black.cgColor
        chromeShadowView.layer?.shadowOpacity = usesGlassChrome ? 0.35 : 0
        chromeShadowView.layer?.shadowRadius = usesGlassChrome ? 12 : 0
        chromeShadowView.layer?.shadowOffset = NSSize(width: 0, height: -4)
        chromeShadowView.layer?.shadowPath = usesGlassChrome
            ? CGPath(roundedRect: chromeShadowView.bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            : nil

        visualEffectView.layer?.cornerRadius = cornerRadius
        visualEffectView.layer?.cornerCurve = .continuous
        visualEffectView.layer?.masksToBounds = usesGlassChrome
        visualEffectView.layer?.borderWidth = usesGlassChrome ? 1 : 0
        visualEffectView.layer?.borderColor = usesGlassChrome ? NSColor.white.withAlphaComponent(0.12).cgColor : NSColor.clear.cgColor
    }

    private func scheduleFrameNormalization(to frame: NSRect) {
        pendingNormalizationFrame = frame
        guard !frameNormalizationScheduled else {
            return
        }

        frameNormalizationScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.frameNormalizationScheduled = false
            guard let frame = self.pendingNormalizationFrame else {
                return
            }
            self.pendingNormalizationFrame = nil
            self.normalizeFrame(to: frame)
        }
    }

    private func normalizeFrame(to frame: NSRect) {
        let windowFrameChanged = !Self.framesApproximatelyEqual(self.frame, frame)
        if windowFrameChanged {
            setFrame(frame, display: true, animate: false)
        }

        let rootFrame = NSRect(origin: .zero, size: frame.size)
        let rootFrameChanged = !Self.framesApproximatelyEqual(rootView.frame, rootFrame)
        if rootFrameChanged {
            rootView.frame = rootFrame
        }

        updateChromeLayout(animated: false)
        if windowFrameChanged || rootFrameChanged {
            hostedView?.needsLayout = true
        }
    }

    private static func framesApproximatelyEqual(_ lhs: NSRect, _ rhs: NSRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) < 0.5 &&
            abs(lhs.origin.y - rhs.origin.y) < 0.5 &&
            abs(lhs.size.width - rhs.size.width) < 0.5 &&
            abs(lhs.size.height - rhs.size.height) < 0.5
    }

}

private extension DeskBarLayoutMode {
    var usesCompactWidth: Bool {
        self == .compact || self == .compactGlass || self == .floatingCenter
    }

    var usesGlassChrome: Bool {
        self == .compactGlass || self == .fullWidthGlass || self == .floatingCenter
    }

    var limitsHitTestingToChrome: Bool {
        usesCompactWidth || usesGlassChrome
    }
}

private final class TaskbarPanelRootView: NSView {
    private let settings: TaskbarSettings
    weak var chromeView: NSView?
    private var preferredCarrierSize: NSSize?

    init(settings: TaskbarSettings, frame frameRect: NSRect) {
        self.settings = settings
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if settings.layoutMode.limitsHitTestingToChrome,
           let chromeView,
           !chromeView.frame.contains(point) {
            return nil
        }

        return super.hitTest(point)
    }

    override var fittingSize: NSSize {
        if let preferredCarrierSize, !settings.layoutMode.usesCompactWidth {
            return preferredCarrierSize
        }

        return super.fittingSize
    }

    override var intrinsicContentSize: NSSize {
        if let preferredCarrierSize, !settings.layoutMode.usesCompactWidth {
            return preferredCarrierSize
        }

        return super.intrinsicContentSize
    }

    func setPreferredCarrierSize(_ size: NSSize) {
        preferredCarrierSize = size
        invalidateIntrinsicContentSize()
    }
}
