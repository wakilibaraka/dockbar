import AppKit

/// The remaining task zone views: the container that arranges groups and loose windows,
/// the width measurement it reports, and the separator and spacer views that pad the
/// zone out to the available width.


final class TaskZoneGroupContainerView: NSView {
    private let settings: TaskbarSettings
    private let blacklistManager: BlacklistManager
    private let badgeProvider: (String?) -> Bool
    private let agentAnnotationProvider: (WindowInfo) -> SMAgentWindowAnnotation?
    private let pluginMenuConfigurationProvider: (WindowInfo) -> TaskButtonPluginMenuConfiguration?
    private let windowActiveProvider: (WindowInfo, pid_t?, String?) -> Bool
    private let windowActivationHandler: (WindowInfo) -> Void
    private let thumbnailProvider: (CGWindowID) async -> NSImage?
    private let thumbnailService: ThumbnailService?
    private let stackView = NSStackView()
    private let headerView: TaskZoneGroupButtonView
    private var childViews: [String: TaskButtonView] = [:]

    init(
        group: AppGroup,
        frontmostPID: pid_t?,
        frontmostWindowID: String?,
        isActive: Bool,
        hasBadge: Bool,
        isAccessibilityAvailable: Bool,
        groupRuntimeState: AppRuntimeState,
        showsActivityOverlay: Bool,
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        dragConfiguration: TaskButtonDragConfiguration,
        badgeProvider: @escaping (String?) -> Bool,
        runtimeStateProvider: @escaping (pid_t) -> AppRuntimeState,
        agentAnnotationProvider: @escaping (WindowInfo) -> SMAgentWindowAnnotation?,
        pluginMenuConfigurationProvider: @escaping (WindowInfo) -> TaskButtonPluginMenuConfiguration?,
        windowActiveProvider: @escaping (WindowInfo, pid_t?, String?) -> Bool,
        activationHandler: @escaping () -> Void,
        windowActivationHandler: @escaping (WindowInfo) -> Void,
        thumbnailProvider: @escaping (CGWindowID) async -> NSImage?, thumbnailService: ThumbnailService?
    ) {
        self.settings = settings
        self.blacklistManager = blacklistManager
        self.badgeProvider = badgeProvider
        self.agentAnnotationProvider = agentAnnotationProvider
        self.pluginMenuConfigurationProvider = pluginMenuConfigurationProvider
        self.windowActiveProvider = windowActiveProvider
        self.windowActivationHandler = windowActivationHandler
        self.thumbnailProvider = thumbnailProvider
        self.thumbnailService = thumbnailService
        headerView = TaskZoneGroupButtonView(
            appGroup: group,
            hasBadge: hasBadge,
            runtimeState: groupRuntimeState,
            showsActivityOverlay: showsActivityOverlay,
            isActive: isActive,
            settings: settings,
            dragConfiguration: dragConfiguration,
            activationHandler: activationHandler,
            windowActivationHandler: windowActivationHandler,
            thumbnailProvider: thumbnailProvider,
            thumbnailService: thumbnailService
        )
        self.runtimeStateProvider = runtimeStateProvider
        self.showsActivityOverlay = showsActivityOverlay
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 8
        stackView.edgeInsets = NSEdgeInsetsZero
        stackView.distribution = .fill
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        headerView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        update(
            group: group,
            frontmostPID: frontmostPID,
            frontmostWindowID: frontmostWindowID,
            isActive: isActive,
            hasBadge: hasBadge,
            isAccessibilityAvailable: isAccessibilityAvailable,
            groupRuntimeState: groupRuntimeState,
            showsActivityOverlay: showsActivityOverlay
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let runtimeStateProvider: (pid_t) -> AppRuntimeState
    private var showsActivityOverlay: Bool

    func taskButtonViews() -> [TaskbarWidthParticipant] {
        stackView.arrangedSubviews.compactMap { $0 as? TaskbarWidthParticipant }.filter { !$0.isHidden }
    }

    func widthMeasurement(usesAdaptiveTaskWidth: Bool) -> TaskZoneWidthMeasurement {
        let visibleSubviews = stackView.arrangedSubviews.filter { !$0.isHidden }
        guard !visibleSubviews.isEmpty else {
            return TaskZoneWidthMeasurement()
        }

        var measurement = TaskZoneWidthMeasurement()
        for view in visibleSubviews {
            if let participant = view as? TaskbarWidthParticipant {
                measurement.taskButtonItems.append(
                    participant.widthPlanItem(usesAdaptiveWidth: usesAdaptiveTaskWidth)
                )
            } else {
                measurement.fixedWidth += Self.preferredWidth(for: view)
            }
        }
        measurement.fixedWidth += CGFloat(visibleSubviews.count - 1) * stackView.spacing
        return measurement
    }

    func update(
        group: AppGroup,
        frontmostPID: pid_t?,
        frontmostWindowID: String?,
        isActive: Bool,
        hasBadge: Bool,
        isAccessibilityAvailable: Bool,
        groupRuntimeState: AppRuntimeState,
        showsActivityOverlay: Bool
    ) {
        self.showsActivityOverlay = showsActivityOverlay
        headerView.update(
            appGroup: group,
            hasBadge: hasBadge,
            runtimeState: groupRuntimeState,
            showsActivityOverlay: showsActivityOverlay,
            isActive: isActive
        )

        var desiredViews: [NSView] = [headerView]
        var retainedChildIDs = Set<String>()

        if group.isExpanded {
            for window in group.windows {
                let windowID = window.id
                let buttonView: TaskButtonView

                if let existingView = childViews[windowID] {
                    existingView.update(
                        windowInfo: window,
                        isActive: windowActiveProvider(window, frontmostPID, frontmostWindowID),
                        hasBadge: badgeProvider(window.bundleIdentifier),
                        isAccessibilityAvailable: isAccessibilityAvailable,
                        runtimeState: runtimeStateProvider(window.pid),
                        showsActivityOverlay: showsActivityOverlay,
                        agentAnnotation: agentAnnotationProvider(window),
                        pluginMenuConfiguration: pluginMenuConfigurationProvider(window)
                    )
                    buttonView = existingView
                } else {
                    let newButtonView = TaskButtonView(
                        windowInfo: window,
                        isActive: windowActiveProvider(window, frontmostPID, frontmostWindowID),
                        hasBadge: badgeProvider(window.bundleIdentifier),
                        isAccessibilityAvailable: isAccessibilityAvailable,
                        runtimeState: runtimeStateProvider(window.pid),
                        showsActivityOverlay: showsActivityOverlay,
                        agentAnnotation: agentAnnotationProvider(window),
                        settings: settings,
                        blacklistManager: blacklistManager,
                        pluginMenuConfiguration: pluginMenuConfigurationProvider(window)
                    ) { [windowActivationHandler] windowInfo in
                        windowActivationHandler(windowInfo)
                    }
                    newButtonView.heightAnchor.constraint(equalToConstant: 32).isActive = true
                    childViews[windowID] = newButtonView
                    buttonView = newButtonView
                }

                desiredViews.append(buttonView)
                retainedChildIDs.insert(windowID)
            }
        }

        let staleChildIDs = Set(childViews.keys).subtracting(retainedChildIDs)
        for childID in staleChildIDs {
            guard let view = childViews.removeValue(forKey: childID) else {
                continue
            }

            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        reconcileArrangedSubviews(desiredViews, in: stackView)
    }

    private static func preferredWidth(for view: NSView) -> CGFloat {
        let intrinsicWidth = view.intrinsicContentSize.width
        if intrinsicWidth != NSView.noIntrinsicMetric, intrinsicWidth > 0 {
            return intrinsicWidth
        }

        return max(0, view.fittingSize.width)
    }
}

struct TaskZoneWidthMeasurement {
    var fixedWidth: CGFloat = 0
    var taskButtonItems: [TaskbarWidthPlanItem] = []

    var preferredWidth: CGFloat {
        fixedWidth + taskButtonItems.reduce(0) { $0 + $1.preferredWidth }
    }

    var hasContent: Bool {
        fixedWidth > 0 || !taskButtonItems.isEmpty
    }

    mutating func append(_ other: TaskZoneWidthMeasurement) {
        fixedWidth += other.fixedWidth
        taskButtonItems.append(contentsOf: other.taskButtonItems)
    }
}

final class TaskZoneSeparatorView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.6).cgColor

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 1),
            heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 1, height: 22)
    }
}

final class TaskZoneFlexibleSpacerView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 8, height: 1)
    }
}

func reconcileArrangedSubviews(_ desiredViews: [NSView], in stackView: NSStackView) {
    let desiredIdentifiers = Set(desiredViews.map(ObjectIdentifier.init))

    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0
        context.allowsImplicitAnimation = false

        for view in stackView.arrangedSubviews where !desiredIdentifiers.contains(ObjectIdentifier(view)) {
            view.layer?.removeAllAnimations()
            view.alphaValue = 1
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, view) in desiredViews.enumerated() {
            let currentSubviews = stackView.arrangedSubviews

            if currentSubviews.indices.contains(index), currentSubviews[index] === view {
                continue
            }

            if currentSubviews.contains(where: { $0 === view }) {
                stackView.removeArrangedSubview(view)
            }

            view.layer?.removeAllAnimations()
            view.alphaValue = 1
            stackView.insertArrangedSubview(view, at: index)
        }
    }
}

extension NSEvent {
    /// True for any of the mouse-down event types, so collapse and drag handling can
    /// treat them the same without repeating the check.
    var isMouseDown: Bool {
        type == .leftMouseDown ||
            type == .rightMouseDown ||
            type == .otherMouseDown
    }
}
