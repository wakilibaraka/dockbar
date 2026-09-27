
import AppKit
import Combine
import DockBarCore

final class TaskbarPanel: NSPanel {
    private let settings: TaskbarSettings
    private let permissionsManager: PermissionsManager
    private var cancellables = Set<AnyCancellable>()

    private var assignedScreen: NSScreen?
    private var displayID: CGDirectDisplayID?
    
    private let rootView: TaskbarPanelRootView
    private var hostedView: NSView?

    private var frameNormalizationScheduled = false
    private var pendingNormalizationFrame: NSRect?

    static let minimumContentHeight: CGFloat = 40

    init(
        settings: TaskbarSettings,
        permissionsManager: PermissionsManager,
        screen: NSScreen?,
        displayID: CGDirectDisplayID? = nil
    ) {
        self.settings = settings
        self.permissionsManager = permissionsManager
        self.assignedScreen = screen
        self.displayID = displayID

        let resolvedScreen = screen ?? NSScreen.main
        let frame = Self.panelFrame(
            isAccessibilityGranted: permissionsManager.isAccessibilityGranted,
            taskbarHeight: settings.taskbarHeight,
            screen: resolvedScreen
        )

        rootView = TaskbarPanelRootView(settings: settings, frame: NSRect(origin: .zero, size: frame.size))
        
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
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        contentView = rootView

        bindSettings()
    }

    private func bindSettings() {
        settings.$taskbarHeight
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateFrameForCurrentState(animated: false)
            }
            .store(in: &cancellables)
            
        settings.$dockMode
            .sink { [weak self] _ in
                self?.updateFrameForCurrentState(animated: true)
            }
            .store(in: &cancellables)
    }

    func setContentSubview(_ view: NSView) {
        hostedView?.removeFromSuperview()
        view.frame = rootView.bounds
        view.autoresizingMask = [.width, .height]
        rootView.addSubview(view)
        hostedView = view
        updateFrameForCurrentState(animated: false)
    }

    
    func updateCollectionBehavior(showOverFullScreenApps: Bool) {
        var newBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if showOverFullScreenApps {
            newBehavior.insert(.fullScreenAuxiliary)
        }
        self.collectionBehavior = newBehavior
    }
    
    func updateFrame(animated: Bool) {
        updateFrameForCurrentState(animated: animated)
    }

    func updateForAccessibilityPermissionChange() {
        updateFrameForCurrentState(animated: true)
    }

    private func updateFrameForCurrentState(animated: Bool) {
        let resolvedScreen =
            (displayID != nil ? ScreenGeometry.screen(for: displayID!) : nil) ??
            self.assignedScreen ??
            NSScreen.screens.first

        let nextFrame = Self.panelFrame(
            isAccessibilityGranted: permissionsManager.isAccessibilityGranted,
            taskbarHeight: settings.taskbarHeight,
            screen: resolvedScreen
        )

        let frameChanged = !Self.framesApproximatelyEqual(frame, nextFrame)
        if frameChanged {
            setFrame(nextFrame, display: true, animate: false)
        }
        rootView.frame = NSRect(origin: .zero, size: nextFrame.size)

        scheduleFrameNormalization(to: nextFrame)
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
        let yPos = screen.frame.origin.y
        
        return NSRect(
            x: screen.frame.origin.x,
            y: yPos,
            width: screen.frame.width,
            height: height
        )
    }

    private func scheduleFrameNormalization(to frame: NSRect) {
        pendingNormalizationFrame = frame
        guard !frameNormalizationScheduled else { return }

        frameNormalizationScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.frameNormalizationScheduled = false
            guard let frame = self.pendingNormalizationFrame else { return }
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

private final class TaskbarPanelRootView: NSView {
    private let settings: TaskbarSettings

    init(settings: TaskbarSettings, frame frameRect: NSRect) {
        self.settings = settings
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        // If we only hit the root view itself (transparent), let clicks pass through
        if hit == self { return nil }
        return hit
    }
}
