import AppKit
import Combine
import SwiftUI

final class SystemResourceWidgetView: NSView {
    private let settings: TaskbarSettings
    private let monitor: SystemResourceMonitor
    private let smPluginService: SMPluginService?
    
    private let containerView = NSView()
    private let textLabel = NSTextField(labelWithString: "")
    
    private var popover: NSPopover?
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
        return isHidden ? 0 : 72
    }
    
    override var intrinsicContentSize: NSSize {
        NSSize(width: preferredContentWidth(), height: NSView.noIntrinsicMetric)
    }
    
    private let iconView = NSImageView()

    private func setupUI() {
        wantsLayer = true
        
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 6
        containerView.layer?.cornerCurve = .continuous
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        iconView.image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: nil)?.withSymbolConfiguration(config)
        iconView.contentTintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)
        
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
            containerView.widthAnchor.constraint(equalToConstant: 60),
            containerView.heightAnchor.constraint(equalToConstant: 22),
            
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6)
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
            .combineLatest(settings.$systemResourceWidgetCollapsed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.updateVisibility()
            }
            .store(in: &cancellables)
    }
    
    private func updateVisibility() {
        if isCollapsedInstance { return }
        
        let shouldShow = settings.showSystemResourceWidget && !settings.systemResourceWidgetCollapsed
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
        if percent > 80 {
            color = NSColor.systemRed
        } else if percent > 60 {
            color = NSColor.systemOrange
        } else {
            color = NSColor.systemGreen
        }
        
        textLabel.textColor = color
        containerView.layer?.backgroundColor = color.withAlphaComponent(0.15).cgColor
    }
    
    // MARK: - Interaction
    
    override func mouseDown(with event: NSEvent) {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }
        
        let newPopover = NSPopover()
        newPopover.behavior = .transient
        let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor, smPluginService: smPluginService))
        controller.preferredContentSize = NSSize(width: 320, height: 480)
        newPopover.contentViewController = controller
        
        var anchorRect = self.bounds
        anchorRect.size.width = min(self.bounds.width, 44)
        
        newPopover.show(relativeTo: anchorRect, of: self, preferredEdge: .maxY)
        self.popover = newPopover
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
