import AppKit
import Combine

final class SystemResourceFlyoutPanel: NSPanel {
    private let monitor: SystemResourceMonitor
    private let settings: TaskbarSettings
    private var cancellables = Set<AnyCancellable>()
    
    private let stackView = NSStackView()
    private var metricControls: [SystemResourceMetricControl] = []
    
    init(monitor: SystemResourceMonitor, settings: TaskbarSettings) {
        self.monitor = monitor
        self.settings = settings
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        
        setupUI()
        bindState()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        let visualEffect = NSVisualEffectView(frame: contentRect(forFrameRect: frame))
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.cornerCurve = .continuous
        visualEffect.layer?.masksToBounds = true
        contentView = visualEffect
        
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: visualEffect.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor, constant: -16)
        ])
        
        // Add metrics
        if settings.showSystemResourceMemoryMetric {
            let ctrl = SystemResourceMetricControl(metric: .memory)
            metricControls.append(ctrl)
            stackView.addArrangedSubview(ctrl)
        }
        if settings.showSystemResourceCPUMetric {
            let ctrl = SystemResourceMetricControl(metric: .cpu)
            metricControls.append(ctrl)
            stackView.addArrangedSubview(ctrl)
        }
        if settings.showSystemResourceGPUMetric {
            let ctrl = SystemResourceMetricControl(metric: .gpu)
            metricControls.append(ctrl)
            stackView.addArrangedSubview(ctrl)
        }
    }
    
    private func bindState() {
        monitor.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.updateMetrics(with: snapshot)
            }
            .store(in: &cancellables)
    }
    
    private func updateMetrics(with snapshot: SystemResourceSnapshot) {
        for ctrl in metricControls {
            switch ctrl.metric {
            case .memory:
                let severity: SystemResourceMetricSeverity
                if snapshot.memoryPressureLevel == .critical {
                    severity = .critical
                } else if snapshot.memoryPressureLevel == .warning {
                    severity = .warning
                } else if let percent = snapshot.memoryUsedPercent, percent > 85 {
                    severity = .warning
                } else {
                    severity = snapshot.memoryUsedPercent == nil ? .unknown : .normal
                }
                
                let valueStr: String
                if let used = snapshot.memoryUsedBytes, let total = snapshot.memoryTotalBytes {
                    valueStr = "\(formatBytes(used)) / \(formatBytes(total))"
                } else {
                    valueStr = "--"
                }
                
                ctrl.update(value: valueStr, fraction: (snapshot.memoryUsedPercent ?? 0) / 100.0, detail: "", severity: severity)
                
            case .cpu:
                let severity: SystemResourceMetricSeverity
                if let percent = snapshot.cpuPercent {
                    severity = percent > 90 ? .critical : (percent > 70 ? .warning : .normal)
                } else {
                    severity = .unknown
                }
                
                let valueStr = snapshot.cpuPercent.map { "\(Int($0.rounded()))%" } ?? "--"
                ctrl.update(value: valueStr, fraction: (snapshot.cpuPercent ?? 0) / 100.0, detail: "", severity: severity)
                
            case .gpu:
                let severity: SystemResourceMetricSeverity
                if let percent = snapshot.gpuPercent {
                    severity = percent > 90 ? .critical : (percent > 75 ? .warning : .normal)
                } else {
                    severity = .unknown
                }
                
                let valueStr = snapshot.gpuPercent.map { "\(Int($0.rounded()))%" } ?? "--"
                ctrl.update(value: valueStr, fraction: (snapshot.gpuPercent ?? 0) / 100.0, detail: "", severity: severity)
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
