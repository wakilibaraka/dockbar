import AppKit
import Combine

final class TaskbarPanel: NSPanel {
    private static let bannerHeight: CGFloat = 32
    private static let minimumContentHeight: CGFloat = 32
    private static let compactHorizontalMargin: CGFloat = 12
    private static let compactMinimumWidth: CGFloat = 420
    private static let compactFallbackWidth: CGFloat = 860
    private static let glassHorizontalMargin: CGFloat = 12

    let displayID: CGDirectDisplayID

    private let permissionsManager: PermissionsManager
    private let settings: TaskbarSettings
    private let rootView: TaskbarPanelRootView
    private var primaryChromeView = ChromePillView(frame: .zero)
    private var extraChromeViews: [ChromePillView] = []
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
            screen: screen
        )

        rootView = TaskbarPanelRootView(settings: settings, frame: NSRect(origin: .zero, size: frame.size))
        rootView.setPreferredCarrierSize(frame.size)
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

        rootView.addSubview(primaryChromeView)
        rootView.chromeView = primaryChromeView
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
        view.frame = rootView.bounds
        view.autoresizingMask = [.width, .height]
        rootView.addSubview(view, positioned: .above, relativeTo: nil)
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

        let hostedFrame = (settings.layoutMode == .pills) ? rootView.bounds : chromeFrame
        if let hostedView, !Self.framesApproximatelyEqual(hostedView.frame, hostedFrame) {
            hostedView.frame = hostedFrame
        }

        if settings.layoutMode == .pills {
            primaryChromeView.isHidden = true
            extraChromeViews.forEach { $0.removeFromSuperview() }
            extraChromeViews.removeAll()
            rootView.extraChromeViews = []
        } else {
            primaryChromeView.isHidden = false
            extraChromeViews.forEach { $0.removeFromSuperview() }
            extraChromeViews.removeAll()
            rootView.extraChromeViews = []
            
            if !Self.framesApproximatelyEqual(primaryChromeView.frame, chromeFrame) {
                primaryChromeView.frame = chromeFrame
            }
            primaryChromeView.updateVisualStyle(layoutMode: settings.layoutMode)
        }
    }

    private static func panelFrame(
        isAccessibilityGranted: Bool,
        taskbarHeight: CGFloat,
        screen: NSScreen?
    ) -> NSRect {
        guard let screen else {
            return .zero
        }

        let contentHeight = max(taskbarHeight, minimumContentHeight)
        let height = contentHeight

        return NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y,
            width: screen.frame.width,
            height: height
        )
    }

    private static let winstrixBottomMargin: CGFloat = 8

    private static func chromeFrame(
        layoutMode: DeskBarLayoutMode,
        compactContentWidth: CGFloat?,
        bounds: NSRect
    ) -> NSRect {
        let width: CGFloat
        var height = bounds.height
        var y = bounds.minY

        switch layoutMode {
        case .fullWidth, .pills:
            width = bounds.width
        case .fullWidthGlass:
            width = max(120, bounds.width - glassHorizontalMargin * 2)
        case .compact, .compactGlass, .winstrix, .winstrixFlat:
            let maximumWidth = max(120, bounds.width - compactHorizontalMargin * 2)
            let minimumWidth = min(compactMinimumWidth, maximumWidth)
            let desiredWidth = compactContentWidth ?? min(compactFallbackWidth, maximumWidth)
            width = min(max(ceil(desiredWidth), minimumWidth), maximumWidth)
        }
        
        if layoutMode == .winstrix || layoutMode == .winstrixFlat {
            height = max(minimumContentHeight, bounds.height - winstrixBottomMargin)
            y = bounds.minY + winstrixBottomMargin
        }

        let originX = bounds.minX + floor((bounds.width - width) / 2)
        return NSRect(
            x: originX,
            y: y,
            width: width,
            height: height
        )
    }

    private func compactContentWidth() -> CGFloat? {
        guard let taskbarContentView = hostedView as? TaskbarContentView else {
            return hostedView?.fittingSize.width
        }

        return taskbarContentView.preferredCompactWidth()
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
        if !Self.framesApproximatelyEqual(self.frame, frame) {
            setFrame(frame, display: true, animate: false)
        }

        let rootFrame = NSRect(origin: .zero, size: frame.size)
        if !Self.framesApproximatelyEqual(rootView.frame, rootFrame) {
            rootView.frame = rootFrame
        }

        updateChromeLayout(animated: false)
        hostedView?.needsLayout = true
    }

    private static func framesApproximatelyEqual(_ lhs: NSRect, _ rhs: NSRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) < 0.5 &&
            abs(lhs.origin.y - rhs.origin.y) < 0.5 &&
            abs(lhs.size.width - rhs.size.width) < 0.5 &&
            abs(lhs.size.height - rhs.size.height) < 0.5
    }
}

extension DeskBarLayoutMode {
    var usesCompactWidth: Bool {
        self == .compact || self == .compactGlass || self == .winstrix || self == .winstrixFlat
    }

    var usesGlassChrome: Bool {
        self == .compactGlass || self == .fullWidthGlass || self == .winstrix || self == .winstrixFlat || self == .pills
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

    var extraChromeViews: [NSView] = []

    override func hitTest(_ point: NSPoint) -> NSView? {
        if settings.layoutMode.limitsHitTestingToChrome {
            let inPrimary = chromeView?.frame.contains(point) ?? false
            let inExtra = extraChromeViews.contains { $0.frame.contains(point) }
            if !inPrimary && !inExtra {
                return nil
            }
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
