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
    private var layoutUpdateScheduled = false

    init(
        permissionsManager: PermissionsManager,
        settings: TaskbarSettings,
        screen: NSScreen
    ) {
        self.displayID = ScreenGeometry.displayID(for: screen) ?? CGMainDisplayID()
        self.permissionsManager = permissionsManager
        self.settings = settings

        let layout = Self.barLayout(
            spec: settings.taskbarMode.spec,
            taskbarHeight: settings.taskbarHeight,
            dockPosition: settings.dockPosition,
            screen: screen
        )
        let frame = layout.panel

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

        visualEffectView.material = settings.taskbarMode.strategy.visualEffectMaterial
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

        settings.$dockPosition
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFrameForCurrentState(animated: true)
            }
            .store(in: &cancellables)

        settings.$taskbarMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.visualEffectView.material = self.settings.taskbarMode.strategy.visualEffectMaterial
                self.updateFrameForCurrentState(animated: true)
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
        guard !layoutUpdateScheduled else {
            return
        }

        layoutUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.layoutUpdateScheduled = false
            self.updateFrameForCurrentState(animated: animated)
        }
    }

    func updateCollectionBehavior(showOverFullScreenApps: Bool) {
        var behavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if showOverFullScreenApps {
            behavior.insert(.fullScreenAuxiliary)
        }

        collectionBehavior = behavior
    }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        guard let screen else {
            return frameRect
        }

        let visibleFrame = screen.visibleFrame
        let width = min(frameRect.width, visibleFrame.width)
        let x = min(max(frameRect.minX, visibleFrame.minX), visibleFrame.maxX - width)
        return NSRect(
            x: x,
            y: frameRect.minY,
            width: width,
            height: frameRect.height
        )
    }

    private func updateFrameForCurrentState(animated: Bool, screen: NSScreen? = nil) {
        let resolvedScreen = screen ??
            ScreenGeometry.screen(for: displayID) ??
            self.screen ??
            NSScreen.screens.first

        let strategy = settings.taskbarMode.strategy
        let resolvedPosition = strategy.dockPosition(defaultPosition: settings.dockPosition)

        let layout = Self.barLayout(
            spec: strategy.spec,
            taskbarHeight: settings.taskbarHeight,
            dockPosition: resolvedPosition,
            screen: resolvedScreen
        )
        let nextFrame = layout.panel

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
        let strategy = settings.taskbarMode.strategy
        let layoutMode = strategy.layoutMode(defaultLayoutMode: settings.layoutMode)
        let compactWidth: CGFloat? = strategy.usesCompactContentWidth(defaultUsesCompactWidth: settings.layoutMode.usesCompactWidth) ? compactContentWidth() : nil

        let resolvedPosition = strategy.dockPosition(defaultPosition: settings.dockPosition)

        // `chromeFrame` can only describe a strip along the bottom: it takes its height
        // from the bar height and its width from the layout mode, and has no idea which
        // edge the bar is on. A vertical bar's chrome therefore comes from BarPanelLayout
        // instead, which knows about edges.
        let chromeFrame: NSRect
        let spec = strategy.spec
        let edge = spec.resolvedEdge(userChoice: .bottom)
        if edge.isVertical {
            let layout = Self.barLayout(
                spec: spec,
                taskbarHeight: settings.taskbarHeight,
                dockPosition: resolvedPosition,
                screen: self.screen
            )
            // The chrome is expressed in screen coordinates; the panel's subviews are not.
            chromeFrame = NSRect(
                x: layout.chrome.minX - frame.minX,
                y: 0,
                width: layout.chrome.width,
                height: layout.chrome.height
            )
        } else {
            chromeFrame = Self.chromeFrame(
                layoutMode: layoutMode,
                dockPosition: resolvedPosition,
                compactContentWidth: compactWidth,
                bounds: rootView.bounds
            )
        }

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

    /// Where the panel and its chrome sit, for whichever edge the bar is on.
///
/// The old `panelFrame` could only ever return a strip along the bottom: the height came
/// from the bar height and the width from the visible frame, with no notion of which edge
/// the bar was on. That arithmetic is kept for the bottom-edge styles unchanged, and
/// vertical bars go through `BarPanelLayout`, which is edge-aware and unit-tested.
    private static func barLayout(
        spec: TaskbarStyleSpec,
        taskbarHeight: CGFloat,
        dockPosition: DockPosition,
        screen: NSScreen?
    ) -> BarPanelLayout {
        guard let screen else {
            return BarPanelLayout(panel: .zero, chrome: .zero)
        }

        let edge = spec.edge ?? .bottom
        let span: BarSpan = spec.usesCompactContentWidth ? .hugContents : .fullSpan
        let thickness = max(taskbarHeight, minimumContentHeight)

        if edge == .bottom {
            let isFloating = dockPosition == .floatingCenter
            let height = thickness + (isFloating ? BarGeometry.floatingInset : 0)
            let panel = NSRect(
                x: screen.visibleFrame.minX,
                y: screen.frame.minY,
                width: screen.visibleFrame.width,
                height: height
            )
            return BarPanelLayout(panel: panel, chrome: panel)
        }

        return BarPanelLayout.make(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            edge: edge,
            span: span,
            thickness: thickness,
            contentLength: screen.visibleFrame.height * 0.5,
            floatsClearOfEdge: spec.floatsClearOfEdge
        )
    }

    private static func chromeFrame(
        layoutMode: DeskBarLayoutMode,
        dockPosition: DockPosition,
        compactContentWidth: CGFloat?,
        bounds: NSRect
    ) -> NSRect {
        let isFloating = dockPosition == .floatingCenter
        let marginX: CGFloat = isFloating ? 12 : 0
        let marginY: CGFloat = isFloating ? 8 : 0

        let width: CGFloat
        switch layoutMode {
        case .fullWidth, .fullWidthGlass:
            width = isFloating ? max(120, bounds.width - marginX * 2) : bounds.width
        case .compact, .compactGlass:
            let maximumWidth = max(120, bounds.width - marginX * 2)
            let minimumWidth = min(compactMinimumWidth, maximumWidth)
            let desiredWidth = compactContentWidth ?? min(compactFallbackWidth, maximumWidth)
            width = min(max(ceil(desiredWidth), minimumWidth), maximumWidth)
        }

        let originX: CGFloat
        if dockPosition == .bottomLeft {
            originX = bounds.minX + marginX
        } else {
            originX = bounds.minX + floor((bounds.width - width) / 2)
        }

        return NSRect(
            x: originX,
            y: bounds.minY + marginY,
            width: width,
            height: bounds.height - marginY
        )
    }

    private func compactContentWidth() -> CGFloat? {
        guard let taskbarContentView = hostedView as? TaskbarContentView else {
            return hostedView?.fittingSize.width
        }

        return taskbarContentView.preferredCompactWidth()
    }

    private func updateVisualStyle(for frame: NSRect) {
        let strategy = settings.taskbarMode.strategy
        let resolvedPosition = strategy.dockPosition(defaultPosition: settings.dockPosition)
        let isFloating = resolvedPosition == .floatingCenter
        let layoutMode = strategy.layoutMode(defaultLayoutMode: settings.layoutMode)
        let usesGlassChrome = layoutMode.usesGlassChrome
        let cornerRadius = (usesGlassChrome || isFloating) ? min(frame.height / 2, 18) : 0

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
        visualEffectView.layer?.masksToBounds = usesGlassChrome || isFloating
        visualEffectView.layer?.borderWidth = (usesGlassChrome || isFloating) ? 1 : 0
        visualEffectView.layer?.borderColor = (usesGlassChrome || isFloating) ? NSColor.white.withAlphaComponent(0.12).cgColor : NSColor.clear.cgColor
        
        if isFloating {
            visualEffectView.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            visualEffectView.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
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
        self == .compact || self == .compactGlass
    }

    var usesGlassChrome: Bool {
        self == .compactGlass || self == .fullWidthGlass
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
        let strategy = settings.taskbarMode.strategy
        let layoutMode = strategy.layoutMode(defaultLayoutMode: settings.layoutMode)
        if layoutMode.limitsHitTestingToChrome,
           let chromeView,
           !chromeView.frame.contains(point) {
            return nil
        }

        return super.hitTest(point)
    }

    override var fittingSize: NSSize {
        let strategy = settings.taskbarMode.strategy
        let usesCompact = strategy.usesCompactContentWidth(defaultUsesCompactWidth: settings.layoutMode.usesCompactWidth)
        if let preferredCarrierSize, !usesCompact {
            return preferredCarrierSize
        }

        return super.fittingSize
    }

    override var intrinsicContentSize: NSSize {
        let strategy = settings.taskbarMode.strategy
        let usesCompact = strategy.usesCompactContentWidth(defaultUsesCompactWidth: settings.layoutMode.usesCompactWidth)
        if let preferredCarrierSize, !usesCompact {
            return preferredCarrierSize
        }

        return super.intrinsicContentSize
    }

    func setPreferredCarrierSize(_ size: NSSize) {
        preferredCarrierSize = size
        invalidateIntrinsicContentSize()
    }
}
