import AppKit
import Combine
import EventKit

final class EnhancedClockWidgetView: NSView {
    // Injected
    private let settings: TaskbarSettings
    private weak var calendarService: CalendarEventService?
    
    // Subviews
    private let timeLabel = NSTextField(labelWithString: "")
    private let dateLabel = NSTextField(labelWithString: "")
    private let eventLabel = NSTextField(labelWithString: "")
    private let labelsStack = NSStackView()
    private let gradientLayer = CAGradientLayer()
    
    // State
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastRenderedMinute = -1
    private var lastRenderedDate = ""
    private var calendarFlyout: CalendarFlyoutPanel?
    private var outsideClickMonitor: Any?
    
    // Formatters
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()
    private let relativeFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.unitsStyle = .abbreviated
        f.allowedUnits = [.hour, .minute]
        f.maximumUnitCount = 1
        return f
    }()
    
    init(settings: TaskbarSettings, calendarService: CalendarEventService? = nil) {
        self.settings = settings
        self.calendarService = calendarService
        super.init(frame: .zero)
        setupView()
        startTimer()
        bindSettings()
        if let calendarService {
            bindCalendarService(calendarService)
        }
        updateDisplay(force: true)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    var preferredWidthDidChange: (() -> Void)?
    
    deinit {
        timer?.invalidate()
        timer = nil
        if let m = outsideClickMonitor { NSEvent.removeMonitor(m); outsideClickMonitor = nil }
    }
    
    func preferredContentWidth() -> CGFloat {
        if isHidden { return 0 }
        return max(72, labelsStack.fittingSize.width + 12)
    }

    /// Call after init to wire up the calendar service (needed when init order requires super.init first).
    func configure(calendarService: CalendarEventService) {
        self.calendarService = calendarService
        bindCalendarService(calendarService)
        updateDisplay(force: true)
    }

    
    // MARK: - Setup
    
    private func setupView() {
        wantsLayer = true
        
        // Labels
        timeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        timeLabel.textColor = .white
        timeLabel.alignment = .right
        timeLabel.lineBreakMode = .byClipping
        timeLabel.cell?.wraps = false
        
        dateLabel.font = .systemFont(ofSize: 10, weight: .regular)
        dateLabel.textColor = NSColor.white.withAlphaComponent(0.8)
        dateLabel.alignment = .right
        dateLabel.lineBreakMode = .byClipping
        dateLabel.cell?.wraps = false
        
        eventLabel.font = .systemFont(ofSize: 9, weight: .regular)
        eventLabel.textColor = NSColor.white.withAlphaComponent(0.75)
        eventLabel.alignment = .right
        eventLabel.lineBreakMode = .byTruncatingTail
        eventLabel.cell?.wraps = false
        eventLabel.isHidden = true
        
        labelsStack.orientation = .vertical
        labelsStack.alignment = .trailing
        labelsStack.spacing = 0
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.addArrangedSubview(timeLabel)
        labelsStack.addArrangedSubview(dateLabel)
        labelsStack.addArrangedSubview(eventLabel)
        
        addSubview(labelsStack)
        
        NSLayoutConstraint.activate([
            labelsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            labelsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            labelsStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelsStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 2),
            labelsStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -2),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 72)
        ])
        
        updateTextColors()
    }
    
    private func updateTextColors() {
        // Just use white in the simplified design, respecting theme only if you want, but simple is better
        let color = NSColor.white
        timeLabel.textColor = color
        dateLabel.textColor = color.withAlphaComponent(0.8)
        eventLabel.textColor = color.withAlphaComponent(0.75)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateDisplay(force: false)
            }
        }
        timer.map { RunLoop.main.add($0, forMode: .common) }
    }
    
    // MARK: - Update
    
    private func updateDisplay(force: Bool) {
        let now = Date()
        let cal = Calendar.current
        let minute = cal.component(.minute, from: now)
        let dateStr = dateFormatter.string(from: now)
        let timeStr = timeFormatter.string(from: now)
        
        if force || minute != lastRenderedMinute || dateStr != lastRenderedDate {
            lastRenderedMinute = minute
            lastRenderedDate = dateStr
            
            timeLabel.stringValue = timeStr
            dateLabel.stringValue = dateStr
            preferredWidthDidChange?()
        }
        
        updateEventLine(now: now)
    }
    
    private func updateEventLine(now: Date) {
        guard settings.showClockEvents,
              let service = calendarService,
              !service.permissionDenied else {
            eventLabel.isHidden = true
            return
        }
        
        // Find next upcoming event from now
        let upcoming = service.upcomingEvents.filter { $0.startDate > now }.sorted { $0.startDate < $1.startDate }
        if let next = upcoming.first {
            let interval = next.startDate.timeIntervalSince(now)
            if interval < 60 * 60 * 24 { // Only show if within 24h
                let timeUntil = relativeFormatter.string(from: interval) ?? ""
                var title = next.title ?? ""
                if title.count > 18 { title = String(title.prefix(18)) + "…" }
                if eventLabel.stringValue != "· \(title) \(timeUntil)" || eventLabel.isHidden {
                    eventLabel.stringValue = "· \(title) \(timeUntil)"
                    eventLabel.isHidden = false
                    preferredWidthDidChange?()
                }
                return
            }
        }
        if !eventLabel.isHidden {
            eventLabel.stringValue = ""
            eventLabel.isHidden = true
            preferredWidthDidChange?()
        }
    }
    
    // MARK: - Bindings
    
    private func bindSettings() {
        settings.$showClockEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDisplay(force: true)
            }
            .store(in: &cancellables)
    }
    
    private func bindCalendarService(_ service: CalendarEventService) {
        service.$upcomingEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDisplay(force: true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        showAgendaFlyout()
    }
    
    override func rightMouseDown(with event: NSEvent) {
        launchCalendarApp()
    }
    
    private func showAgendaFlyout() {
        if calendarFlyout != nil {
            dismissFlyout()
            return
        }
        guard let service = calendarService else {
            launchCalendarApp()
            return
        }
        
        let flyout = CalendarFlyoutPanel(calendarService: service, settings: settings)
        calendarFlyout = flyout
        
        // Position above the clock widget
        if let window = self.window {
            let clockInScreen = window.convertToScreen(convert(bounds, to: nil))
            var origin = NSPoint(
                x: clockInScreen.maxX - 300,
                y: clockInScreen.maxY + 4
            )
            // Keep on screen
            if let screen = window.screen ?? NSScreen.main {
                let visibleFrame = screen.visibleFrame
                origin.x = max(visibleFrame.minX + 4, min(origin.x, visibleFrame.maxX - 304))
                origin.y = min(origin.y, visibleFrame.maxY - 4)
            }
            flyout.setFrameOrigin(origin)
        }
        
        flyout.makeKeyAndOrderFront(nil)
        
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.dismissFlyout()
            }
        }
    }
    
    private func dismissFlyout() {
        calendarFlyout?.close()
        calendarFlyout = nil
        if let m = outsideClickMonitor { NSEvent.removeMonitor(m); outsideClickMonitor = nil }
    }
    
    private func launchCalendarApp() {
        // Try calendar366:// first
        if let url = URL(string: "calendar366://") {
            if NSWorkspace.shared.open(url) { return }
        }
        // Fallback to AppleScript
        let appName = settings.clockTargetApp
        guard !appName.isEmpty else { return }
        let script = """
        try
            tell application "\(appName)" to activate
        on error
        end try
        """
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }
    
    // MARK: - Accessibility
    
    override func accessibilityLabel() -> String? { "Clock" }
    override func accessibilityRole() -> NSAccessibility.Role? { .button }
}
