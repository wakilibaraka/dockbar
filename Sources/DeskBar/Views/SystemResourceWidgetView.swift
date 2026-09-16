import AppKit
import Combine
import SwiftUI

final class SystemResourceWidgetView: NSView {
    private let settings: TaskbarSettings
    private let monitor: SystemResourceMonitor
    
    private var hostingView: NSHostingView<UnifiedSystemResourceWidgetView>?
    
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    
    var preferredWidthDidChange: (() -> Void)?
    
    private let isCollapsedInstance: Bool
    
    init(settings: TaskbarSettings, monitor: SystemResourceMonitor, displayID: CGDirectDisplayID? = nil, isCollapsedInstance: Bool = false) {
        self.settings = settings
        self.monitor = monitor
        self.isCollapsedInstance = isCollapsedInstance
        super.init(frame: .zero)
        setupUI()
        bindState()
        updateVisibility()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func preferredContentWidth() -> CGFloat {
        if isHidden { return 0 }
        let hasBattery = SystemStatsService.shared.batteryStats != nil
        let base = settings.showRingCharts ? 44.0 : 56.0
        return base + (hasBattery ? 34.0 : 0.0)
    }
    
    private func setupUI() {
        wantsLayer = true
        
        let hv = NSHostingView(rootView: UnifiedSystemResourceWidgetView(settings: settings, monitor: monitor))
        hv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hv)
        self.hostingView = hv
        
        NSLayoutConstraint.activate([
            hv.centerYAnchor.constraint(equalTo: centerYAnchor),
            hv.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
    
    private func bindState() {
        settings.$showSystemResourceWidget
            .combineLatest(settings.$systemResourceWidgetCollapsed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.updateVisibility()
            }
            .store(in: &cancellables)
            
        settings.$showRingCharts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.preferredWidthDidChange?()
            }
            .store(in: &cancellables)
            
        SystemStatsService.shared.$batteryStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.preferredWidthDidChange?()
            }
            .store(in: &cancellables)
    }
    
    private func updateVisibility() {
        if isCollapsedInstance { return }
        
        let shouldShow = settings.showSystemResourceWidget && !settings.systemResourceWidgetCollapsed
        if isHidden != !shouldShow {
            isHidden = !shouldShow
            preferredWidthDidChange?()
        }
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
        let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor))
        controller.preferredContentSize = NSSize(width: 320, height: 380)
        newPopover.contentViewController = controller
        newPopover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
        self.popover = newPopover
    }
}
typealias CollapsedSystemResourceWidgetView = SystemResourceWidgetView
