import AppKit
import Combine

final class SystemResourceWidgetView: NSView {
    static let separatorWidth: CGFloat = 1
    static let separatorHeight: CGFloat = 24
    static let memoryWidth: CGFloat = 88
    static let metricWidth: CGFloat = 88
    static let collapseWidth: CGFloat = 28
    static let widgetHeight: CGFloat = 32
    static let stackSpacing: CGFloat = 8
    static let leadingInset: CGFloat = 4

    private let settings: TaskbarSettings
    private let monitor: SystemResourceMonitor
    private let displayID: CGDirectDisplayID
    private let stackView = NSStackView()
    private let separatorView = NSView()
    private let memoryControl = SystemResourceMetricControl(metric: .memory)
    private let cpuControl = SystemResourceMetricControl(metric: .cpu)
    private let gpuControl = SystemResourceMetricControl(metric: .gpu)
    private let collapseButton = NSButton()
    private var widthConstraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()

    var preferredWidthDidChange: (() -> Void)?

    init(
        settings: TaskbarSettings,
        monitor: SystemResourceMonitor,
        displayID: CGDirectDisplayID
    ) {
        self.settings = settings
        self.monitor = monitor
        self.displayID = displayID
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        configureSubviews()
        configureActions()
        bindState()
        update(with: monitor.snapshot)
        updateMetricVisibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        isHidden ? .zero : NSSize(width: expandedContentWidth(), height: Self.widgetHeight)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func rightMouseDown(with event: NSEvent) {
        NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: self)
    }

    func preferredContentWidth() -> CGFloat {
        isHidden ? 0 : expandedContentWidth()
    }

    private func configureSubviews() {
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fill
        stackView.spacing = Self.stackSpacing
        stackView.edgeInsets = NSEdgeInsets(top: 0, left: Self.leadingInset, bottom: 0, right: 0)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        separatorView.wantsLayer = true
        separatorView.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.55).cgColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(separatorView)
        stackView.addArrangedSubview(memoryControl)
        stackView.addArrangedSubview(cpuControl)
        stackView.addArrangedSubview(gpuControl)
        NSLayoutConstraint.activate([
            separatorView.widthAnchor.constraint(equalToConstant: Self.separatorWidth),
            separatorView.heightAnchor.constraint(equalToConstant: Self.separatorHeight),
            memoryControl.widthAnchor.constraint(equalToConstant: Self.memoryWidth),
            cpuControl.widthAnchor.constraint(equalToConstant: Self.metricWidth),
            gpuControl.widthAnchor.constraint(equalToConstant: Self.metricWidth),
            memoryControl.heightAnchor.constraint(equalToConstant: Self.widgetHeight),
            cpuControl.heightAnchor.constraint(equalToConstant: Self.widgetHeight),
            gpuControl.heightAnchor.constraint(equalToConstant: Self.widgetHeight)
        ])

        configureIconButton(
            collapseButton,
            symbolName: "chevron.right",
            fallbackTitle: ">",
            tooltip: "Collapse system resource widget"
        )
        stackView.addArrangedSubview(collapseButton)
        let widthConstraint = widthAnchor.constraint(equalToConstant: expandedContentWidth())
        self.widthConstraint = widthConstraint
        NSLayoutConstraint.activate([
            collapseButton.widthAnchor.constraint(equalToConstant: Self.collapseWidth),
            collapseButton.heightAnchor.constraint(equalToConstant: Self.collapseWidth),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            widthConstraint,
            heightAnchor.constraint(equalToConstant: Self.widgetHeight)
        ])
    }

    private func configureIconButton(
        _ button: NSButton,
        symbolName: String,
        fallbackTitle: String,
        tooltip: String
    ) {
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.setButtonType(.momentaryChange)
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
        button.contentTintColor = .secondaryLabelColor
        button.toolTip = tooltip

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: tooltip) {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            button.title = fallbackTitle
            button.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .semibold)
        }
    }

    private func configureActions() {
        memoryControl.target = self
        memoryControl.action = #selector(openMemoryMonitor(_:))

        cpuControl.target = self
        cpuControl.action = #selector(openCPUMonitor(_:))

        gpuControl.target = self
        gpuControl.action = #selector(openGPUMonitor(_:))

        collapseButton.target = self
        collapseButton.action = #selector(collapseWidget(_:))
    }

    private func bindState() {
        monitor.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.update(with: snapshot)
            }
            .store(in: &cancellables)

        settings.$showSystemResourceWidget
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMetricVisibility()
            }
            .store(in: &cancellables)

        settings.$systemResourceWidgetCollapsed
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMetricVisibility()
            }
            .store(in: &cancellables)

        settings.$systemStatsDisplayMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMetricVisibility()
            }
            .store(in: &cancellables)

        settings.$systemResourceWidgetPinnedDisplayID
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMetricVisibility()
            }
            .store(in: &cancellables)

        settings.$showSystemResourceMemoryMetric
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMetricVisibility()
            }
            .store(in: &cancellables)

        settings.$showSystemResourceCPUMetric
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMetricVisibility()
            }
            .store(in: &cancellables)

        settings.$showSystemResourceGPUMetric
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMetricVisibility()
            }
            .store(in: &cancellables)
    }

    private func update(with snapshot: SystemResourceSnapshot) {
        memoryControl.update(
            value: memoryValueString(for: snapshot),
            fraction: snapshot.memoryUsedPercent.map { $0 / 100 },
            detail: memoryTooltip(for: snapshot),
            severity: metricSeverity(
                percent: snapshot.memoryUsedPercent,
                pressureLevel: snapshot.memoryPressureLevel
            )
        )
        cpuControl.update(
            value: percentString(snapshot.cpuPercent),
            fraction: snapshot.cpuPercent.map { $0 / 100 },
            detail: metricTooltip(name: "CPU usage", percent: snapshot.cpuPercent, destination: "Activity Monitor CPU History"),
            severity: metricSeverity(percent: snapshot.cpuPercent)
        )
        gpuControl.update(
            value: percentString(snapshot.gpuPercent),
            fraction: snapshot.gpuPercent.map { $0 / 100 },
            detail: metricTooltip(name: "GPU usage", percent: snapshot.gpuPercent, destination: "Activity Monitor GPU History"),
            severity: metricSeverity(percent: snapshot.gpuPercent)
        )
    }

    private func updateMetricVisibility() {
        memoryControl.isHidden = !settings.showSystemResourceMemoryMetric
        cpuControl.isHidden = !settings.showSystemResourceCPUMetric
        gpuControl.isHidden = !settings.showSystemResourceGPUMetric

        let shouldShow = settings.showSystemResourceWidget &&
            !settings.systemResourceWidgetCollapsed &&
            settings.systemStatsDisplayMode == .inline &&
            displayMatchesPin &&
            enabledMetricCount > 0
        isHidden = !shouldShow
        widthConstraint?.constant = expandedContentWidth()
        invalidateIntrinsicContentSize()
        preferredWidthDidChange?()
    }

    private var displayMatchesPin: Bool {
        guard let pinnedDisplayID = settings.systemResourceWidgetPinnedDisplayID else {
            return true
        }

        return pinnedDisplayID == displayID
    }

    private var enabledMetricCount: Int {
        [
            settings.showSystemResourceMemoryMetric,
            settings.showSystemResourceCPUMetric,
            settings.showSystemResourceGPUMetric
        ].filter { $0 }.count
    }

    private func expandedContentWidth() -> CGFloat {
        guard enabledMetricCount > 0 else {
            return 0
        }

        var widths: [CGFloat] = [Self.separatorWidth]
        if settings.showSystemResourceMemoryMetric {
            widths.append(Self.memoryWidth)
        }
        if settings.showSystemResourceCPUMetric {
            widths.append(Self.metricWidth)
        }
        if settings.showSystemResourceGPUMetric {
            widths.append(Self.metricWidth)
        }
        widths.append(Self.collapseWidth)

        let spacing = CGFloat(max(widths.count - 1, 0)) * Self.stackSpacing
        return Self.leadingInset + widths.reduce(0, +) + spacing
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let collapseItem = NSMenuItem(title: "Collapse Widget", action: #selector(collapseWidget(_:)), keyEquivalent: "")
        collapseItem.target = self
        menu.addItem(collapseItem)

        menu.addItem(.separator())

        let pinItem = NSMenuItem(
            title: "Pin to \(displayName)",
            action: #selector(pinWidgetToThisDisplay(_:)),
            keyEquivalent: ""
        )
        pinItem.target = self
        pinItem.isEnabled = settings.systemResourceWidgetPinnedDisplayID != displayID
        menu.addItem(pinItem)

        let allDisplaysItem = NSMenuItem(
            title: "Show on All Displays",
            action: #selector(showWidgetOnAllDisplays(_:)),
            keyEquivalent: ""
        )
        allDisplaysItem.target = self
        allDisplaysItem.isEnabled = settings.systemResourceWidgetPinnedDisplayID != nil
        menu.addItem(allDisplaysItem)

        menu.addItem(.separator())

        let hideItem = NSMenuItem(title: "Hide System Resource Widget", action: #selector(hideWidget(_:)), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        return menu
    }

    private var displayName: String {
        ScreenGeometry.screen(for: displayID)?.localizedName ?? "This Display"
    }

    private func percentString(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }

        return "\(Int(value.rounded()))%"
    }

    private func memoryValueString(for snapshot: SystemResourceSnapshot) -> String {
        guard let usedBytes = snapshot.memoryUsedBytes,
              let totalBytes = snapshot.memoryTotalBytes else {
            return percentString(snapshot.memoryUsedPercent)
        }

        return "\(Self.memoryAmountString(usedBytes, includesUnit: false))/\(Self.memoryAmountString(totalBytes, includesUnit: true))"
    }

    private func memoryTooltip(for snapshot: SystemResourceSnapshot) -> String {
        let used = memoryValueString(for: snapshot)
        let pressure = percentString(snapshot.memoryPressurePercent)
        let free = snapshot.memoryFreePercent.map { "\(Int($0.rounded()))% free" } ?? "free memory unavailable"
        return "Memory: \(used). Pressure: \(snapshot.memoryPressureLevel.displayName), \(pressure) pressure, \(free). Click to open Activity Monitor Memory."
    }

    private func metricTooltip(name: String, percent: Double?, destination: String) -> String {
        "\(name): \(percentString(percent)). Click to open \(destination)."
    }

    private func metricSeverity(
        percent: Double?,
        pressureLevel: MemoryPressureLevel? = nil
    ) -> SystemResourceMetricSeverity {
        if pressureLevel == .critical {
            return .critical
        }

        if pressureLevel == .warning {
            return .warning
        }

        guard let percent else {
            return .unknown
        }

        if percent >= 90 {
            return .critical
        }

        if percent >= 75 {
            return .warning
        }

        return .normal
    }

    private static func memoryAmountString(_ bytes: UInt64, includesUnit: Bool) -> String {
        let gibibytes = Double(bytes) / 1_073_741_824
        let suffix = includesUnit ? "G" : ""
        if gibibytes >= 10 {
            return "\(Int(gibibytes.rounded()))\(suffix)"
        }

        return String(format: "%.1f%@", gibibytes, suffix)
    }

    @objc
    private func collapseWidget(_ sender: Any?) {
        settings.systemResourceWidgetCollapsed = true
    }

    @objc
    private func pinWidgetToThisDisplay(_ sender: Any?) {
        settings.systemResourceWidgetPinnedDisplayID = displayID
    }

    @objc
    private func showWidgetOnAllDisplays(_ sender: Any?) {
        settings.systemResourceWidgetPinnedDisplayID = nil
    }

    @objc
    private func hideWidget(_ sender: Any?) {
        settings.showSystemResourceWidget = false
    }

    @objc
    private func openMemoryMonitor(_ sender: Any?) {
        ActivityMonitorLauncher.open(.memory)
    }

    @objc
    private func openCPUMonitor(_ sender: Any?) {
        ActivityMonitorLauncher.open(.cpu)
    }

    @objc
    private func openGPUMonitor(_ sender: Any?) {
        ActivityMonitorLauncher.open(.gpu)
    }
}

final class CollapsedSystemResourceWidgetView: NSView {
    private let settings: TaskbarSettings
    private let monitor: SystemResourceMonitor
    private let displayID: CGDirectDisplayID
    private let button = NSButton()
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: TaskbarSettings,
        monitor: SystemResourceMonitor,
        displayID: CGDirectDisplayID
    ) {
        self.settings = settings
        self.monitor = monitor
        self.displayID = displayID
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        configureButton()
        bindState()
        updateTooltip(with: monitor.snapshot)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let dotLayer = CALayer()
    private let label = NSTextField(labelWithString: "")
    
    override var intrinsicContentSize: NSSize {
        NSSize(width: 48, height: 24)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func rightMouseDown(with event: NSEvent) {
        NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: self)
    }

    private func configureButton() {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.setButtonType(.momentaryChange)
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
        button.target = self
        button.action = #selector(expandWidget(_:))
        button.title = ""

        addSubview(button)
        
        dotLayer.bounds = CGRect(x: 0, y: 0, width: 6, height: 6)
        dotLayer.cornerRadius = 3
        dotLayer.backgroundColor = NSColor.systemGreen.cgColor
        
        let containerLayer = CALayer()
        containerLayer.addSublayer(dotLayer)
        button.layer?.addSublayer(containerLayer)
        
        // Use a wrapper layer to position the dot properly or just set dotLayer position in layout
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        button.addSubview(label)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 48),
            heightAnchor.constraint(equalToConstant: 24),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4)
        ])
    }
    
    override func layout() {
        super.layout()
        dotLayer.position = CGPoint(x: 10, y: bounds.midY)
    }

    private func bindState() {
        monitor.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.updateTooltip(with: snapshot)
            }
            .store(in: &cancellables)
    }

    private func updateTooltip(with snapshot: SystemResourceSnapshot) {
        var parts: [String] = []
        if settings.showSystemResourceMemoryMetric {
            parts.append("MEM \(percentString(snapshot.memoryUsedPercent))")
        }
        if settings.showSystemResourceCPUMetric {
            parts.append("CPU \(percentString(snapshot.cpuPercent))")
        }
        if settings.showSystemResourceGPUMetric {
            parts.append("GPU \(percentString(snapshot.gpuPercent))")
        }

        button.toolTip = "System resources: \(parts.joined(separator: "  "))"
        toolTip = button.toolTip
        
        // Update live RAM%
        label.stringValue = percentString(snapshot.memoryUsedPercent)
        
        let pressure = snapshot.memoryPressureLevel
        switch pressure {
        case .normal, .unknown:
            dotLayer.backgroundColor = NSColor.systemGreen.cgColor
        case .warning:
            dotLayer.backgroundColor = NSColor.systemYellow.cgColor
        case .critical:
            dotLayer.backgroundColor = NSColor.systemRed.cgColor
        }
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let expandItem = NSMenuItem(title: "Expand Widget", action: #selector(expandWidget(_:)), keyEquivalent: "")
        expandItem.target = self
        menu.addItem(expandItem)

        menu.addItem(.separator())

        let pinItem = NSMenuItem(
            title: "Pin to \(displayName)",
            action: #selector(pinWidgetToThisDisplay(_:)),
            keyEquivalent: ""
        )
        pinItem.target = self
        pinItem.isEnabled = settings.systemResourceWidgetPinnedDisplayID != displayID
        menu.addItem(pinItem)

        let allDisplaysItem = NSMenuItem(
            title: "Show on All Displays",
            action: #selector(showWidgetOnAllDisplays(_:)),
            keyEquivalent: ""
        )
        allDisplaysItem.target = self
        allDisplaysItem.isEnabled = settings.systemResourceWidgetPinnedDisplayID != nil
        menu.addItem(allDisplaysItem)

        menu.addItem(.separator())

        let hideItem = NSMenuItem(title: "Hide System Resource Widget", action: #selector(hideWidget(_:)), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        return menu
    }

    private var displayName: String {
        ScreenGeometry.screen(for: displayID)?.localizedName ?? "This Display"
    }

    private func percentString(_ value: Double?) -> String {
        guard let value else {
            return "--"
        }

        return "\(Int(value.rounded()))%"
    }

    private var flyoutPanel: SystemResourceFlyoutPanel?
    private var outsideClickMonitor: Any?

    @objc
    private func expandWidget(_ sender: Any?) {
        if settings.systemStatsDisplayMode == .flyout {
            if flyoutPanel != nil {
                dismissFlyout()
                return
            }
            
            let flyout = SystemResourceFlyoutPanel(monitor: monitor, settings: settings)
            flyoutPanel = flyout
            
            FlyoutAnchorHelper.position(flyout: flyout, relativeTo: self)
            
            flyout.makeKeyAndOrderFront(nil)
            
            outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.dismissFlyout()
                }
            }
        } else {
            settings.systemResourceWidgetCollapsed = false
        }
    }
    
    private func dismissFlyout() {
        flyoutPanel?.close()
        flyoutPanel = nil
        if let m = outsideClickMonitor {
            NSEvent.removeMonitor(m)
            outsideClickMonitor = nil
        }
    }

    @objc
    private func pinWidgetToThisDisplay(_ sender: Any?) {
        settings.systemResourceWidgetPinnedDisplayID = displayID
    }

    @objc
    private func showWidgetOnAllDisplays(_ sender: Any?) {
        settings.systemResourceWidgetPinnedDisplayID = nil
    }

    @objc
    private func hideWidget(_ sender: Any?) {
        settings.showSystemResourceWidget = false
    }
}

enum SystemResourceMetricSeverity {
    case normal
    case warning
    case critical
    case unknown
}

final class SystemResourceMetricControl: NSControl {
    let metric: SystemResourceMetric
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private let dotLayer = CALayer()
    private var fraction: Double?
    private var severityColor: NSColor = .controlAccentColor

    init(metric: SystemResourceMetric) {
        self.metric = metric
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: metric == .memory ? SystemResourceWidgetView.memoryWidth : SystemResourceWidgetView.metricWidth, height: SystemResourceWidgetView.widgetHeight)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func layout() {
        super.layout()
        dotLayer.frame = CGRect(x: bounds.width - 10, y: bounds.midY - 3, width: 6, height: 6)
    }

    override func mouseDown(with event: NSEvent) {
        sendAction(action, to: target)
    }

    override func rightMouseDown(with event: NSEvent) {
        nextResponder?.rightMouseDown(with: event)
    }

    func update(value: String, fraction: Double?, detail: String, severity: SystemResourceMetricSeverity) {
        if valueLabel.stringValue != value {
            valueLabel.stringValue = value
        }
        self.fraction = fraction.map { min(max($0, 0), 1) }
        if toolTip != detail {
            toolTip = detail
        }
        updateColors(severity: severity)
    }

    private func configureSubviews() {
        titleLabel.stringValue = metric.shortTitle
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        valueLabel.textColor = .labelColor
        valueLabel.alignment = .right
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        dotLayer.cornerRadius = 3
        dotLayer.backgroundColor = NSColor.systemGreen.cgColor
        wantsLayer = true
        layer?.addSublayer(dotLayer)

        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 24),

            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func updateColors(severity: SystemResourceMetricSeverity) {
        switch severity {
        case .normal:
            severityColor = metric == .memory ? .systemGreen : .controlAccentColor
        case .warning:
            severityColor = .systemYellow
        case .critical:
            severityColor = .systemRed
        case .unknown:
            severityColor = .separatorColor
        }

        dotLayer.backgroundColor = severityColor.cgColor
        
        if severity == .critical {
            dotLayer.shadowColor = severityColor.cgColor
            dotLayer.shadowOpacity = 0.8
            dotLayer.shadowRadius = 4
            dotLayer.shadowOffset = .zero
        } else {
            dotLayer.shadowOpacity = 0
        }
    }
}

extension SystemResourceMetric {
    var shortTitle: String {
        switch self {
        case .memory:
            return "MEM"
        case .cpu:
            return "CPU"
        case .gpu:
            return "GPU"
        }
    }
}
