import AppKit
import Combine
import SwiftUI

final class SystemResourceWidgetView: NSView {
    private let settings: TaskbarSettings
    private let monitor: SystemResourceMonitor
    private let smPluginService: SMPluginService?
    
    private let containerView = NSView()
    private let textLabel = NSTextField(labelWithString: "")
    private var cancellables = Set<AnyCancellable>()
    
    var preferredWidthDidChange: (() -> Void)?
    
    private let isCollapsedInstance: Bool
    
    init(settings: TaskbarSettings, monitor: SystemResourceMonitor, smPluginService: SMPluginService? = nil, displayID: CGDirectDisplayID? = nil, isCollapsedInstance: Bool = false) {
        self.settings = settings
        self.monitor = monitor
        self.smPluginService = smPluginService
        self.isCollapsedInstance = isCollapsedInstance
        super.init(frame: .zero)
        
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        
        setupUI()
        bindState()
        updateVisibility()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func preferredContentWidth() -> CGFloat {
        // Fixed width to prevent layout glitches
        return isHidden ? 0 : 56
    }
    
    override var intrinsicContentSize: NSSize {
        NSSize(width: preferredContentWidth(), height: NSView.noIntrinsicMetric)
    }
    
    private func setupUI() {
        wantsLayer = true
        
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 6
        containerView.layer?.cornerCurve = .continuous
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        textLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .bold)
        textLabel.alignment = .center
        textLabel.isBordered = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.drawsBackground = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 44),
            containerView.heightAnchor.constraint(equalToConstant: 22),
            
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }
    
    private func bindState() {
        monitor.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.update(with: snapshot)
            }
            .store(in: &cancellables)
            
        settings.$showSystemResourceWidget
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVisibility()
            }
            .store(in: &cancellables)
    }
    
    private func updateVisibility() {
        if isCollapsedInstance { return }
        
        let shouldShow = settings.showSystemResourceWidget
        if isHidden != !shouldShow {
            isHidden = !shouldShow
            invalidateIntrinsicContentSize()
            preferredWidthDidChange?()
        }
    }
    
    private func update(with snapshot: SystemResourceSnapshot) {
        let percent = snapshot.memoryUsedPercent ?? 0
        textLabel.stringValue = String(format: "%.0f%%", percent)
        
        let color: NSColor
        switch snapshot.memoryPressureLevel {
        case .critical:
            color = NSColor.systemRed
        case .warning:
            color = NSColor.systemOrange
        case .normal, .unknown:
            color = NSColor.systemGreen
        }
        
        textLabel.textColor = color
        containerView.layer?.backgroundColor = color.withAlphaComponent(0.15).cgColor
    }
    
    // MARK: - Interaction
    private lazy var popover: NSPopover = {
        let pop = NSPopover()
        pop.behavior = .transient
        // NSHostingController automatically provides the standard macOS popover appearance
        pop.contentViewController = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor, smPluginService: smPluginService))
        return pop
    }()
    
    private var popoverEventMonitor: Any?

    override func mouseDown(with event: NSEvent) {
        if popover.isShown {
            closePopover()
            return
        }
        
        popover.show(relativeTo: bounds, of: self, preferredEdge: .maxY)
        NSApp.activate(ignoringOtherApps: true)
        
        if popoverEventMonitor == nil {
            popoverEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }
        }
    }
    
    private func closePopover() {
        popover.performClose(nil)
        if let monitor = popoverEventMonitor {
            NSEvent.removeMonitor(monitor)
            popoverEventMonitor = nil
        }
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        
        let newTA = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(newTA)
        trackingArea = newTA
    }
}

typealias CollapsedSystemResourceWidgetView = SystemResourceWidgetView
