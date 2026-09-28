import AppKit
import Combine
import SwiftUI

final class SystemStatsWidgetView: NSView {
    private let settings: TaskbarSettings
    private let monitor: SystemResourceMonitor
    
    private let containerView = NSStackView()
    private let batteryIcon = NSImageView()
    private let textLabel = NSTextField(labelWithString: "")
    private var cancellables = Set<AnyCancellable>()
    
    var preferredWidthDidChange: (() -> Void)?
    
    private let isCollapsedInstance: Bool
    
    init(settings: TaskbarSettings, monitor: SystemResourceMonitor, isCollapsedInstance: Bool = false) {
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
        return isHidden ? 0 : 80
    }
    
    override var intrinsicContentSize: NSSize {
        NSSize(width: preferredContentWidth(), height: NSView.noIntrinsicMetric)
    }
    
    private func setupUI() {
        wantsLayer = true
        
        containerView.orientation = .horizontal
        containerView.alignment = .centerY
        containerView.spacing = 6
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        batteryIcon.image = NSImage(systemSymbolName: "battery.100", accessibilityDescription: nil)?.withSymbolConfiguration(config)
        batteryIcon.contentTintColor = .white
        
        textLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .bold)
        textLabel.textColor = .white
        textLabel.alignment = .right
        
        containerView.addArrangedSubview(batteryIcon)
        containerView.addArrangedSubview(textLabel)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func bindState() {
        monitor.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.update(with: snapshot)
            }
            .store(in: &cancellables)
            
        SystemStatsService.shared.$batteryStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.updateBattery(with: stats)
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
        textLabel.stringValue = String(format: "%.0f%% RAM", percent)
    }
    
    private func updateBattery(with stats: MacBatteryStats?) {
        guard let stats = stats else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        
        let symbolName: String
        if stats.isCharging {
            symbolName = "battery.100.bolt"
        } else {
            let p = Int(stats.percentage)
            if p > 75 { symbolName = "battery.100" }
            else if p > 50 { symbolName = "battery.75" }
            else if p > 25 { symbolName = "battery.50" }
            else { symbolName = "battery.25" }
        }
        batteryIcon.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
        
        if stats.percentage <= 20 && !stats.isCharging {
            batteryIcon.contentTintColor = .systemRed
        } else {
            batteryIcon.contentTintColor = .white
        }
    }
    
    // MARK: - Interaction
    private var flyout: BorderlessFlyout?
    
    override func mouseDown(with event: NSEvent) {
        if flyout?.isShown == true {
            flyout?.performClose(nil)
            return
        }
        
        let newFlyout = BorderlessFlyout()
        newFlyout.onDismiss = { [weak self] in self?.flyout = nil }
        
        let rootVC = NSHostingController(rootView: SystemStatsFlyoutView(monitor: monitor))
        rootVC.view.translatesAutoresizingMaskIntoConstraints = false
        rootVC.view.widthAnchor.constraint(equalToConstant: 280).isActive = true
        rootVC.view.layoutSubtreeIfNeeded()
        let fittingSize = rootVC.view.fittingSize
        rootVC.view.frame = NSRect(origin: .zero, size: fittingSize)
        rootVC.preferredContentSize = fittingSize
        
        newFlyout.show(contentViewController: rootVC, relativeTo: bounds, of: self)
        self.flyout = newFlyout
    }
}
