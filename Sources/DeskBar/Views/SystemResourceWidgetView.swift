import AppKit
import Combine
import SwiftUI

final class SystemResourceWidgetView: NSView {
    private let settings: TaskbarSettings
    private let monitor: SystemResourceMonitor
    
    private var hostingView: NSHostingView<UnifiedSystemResourceWidgetView>?
    
    private lazy var flyoutPanel = SystemResourceFlyoutPanel(monitor: monitor)
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
        return isHidden ? 0 : 56
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
        if flyoutPanel.isVisible {
            flyoutPanel.close()
            return
        }
        
        guard let window = self.window else { return }
        let screenRect = window.convertToScreen(self.convert(self.bounds, to: nil))
        let panelSize = flyoutPanel.frame.size
        
        let margin: CGFloat = 8
        let originX = max(8, screenRect.midX - (panelSize.width / 2))
        let originY = screenRect.maxY + margin
        
        flyoutPanel.setFrameOrigin(NSPoint(x: originX, y: originY))
        flyoutPanel.makeKeyAndOrderFront(nil)
    }
}
typealias CollapsedSystemResourceWidgetView = SystemResourceWidgetView
