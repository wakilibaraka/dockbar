import AppKit
import EventKit
import Combine

final class CalendarFlyoutPanel: NSPanel {
    private let calendarService: CalendarEventService
    private let settings: TaskbarSettings
    private let contentStack = NSStackView()
    private var cancellables = Set<AnyCancellable>()
    
    init(calendarService: CalendarEventService, settings: TaskbarSettings) {
        self.calendarService = calendarService
        self.settings = settings
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .popUpMenu
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .transient]
        
        setupUI()
        bindEvents()
        refreshUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 12
        effectView.layer?.cornerCurve = .continuous
        effectView.layer?.masksToBounds = true
        contentView = effectView
        
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: effectView.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: effectView.bottomAnchor, constant: -12),
            contentStack.leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: 14),
            contentStack.trailingAnchor.constraint(equalTo: effectView.trailingAnchor, constant: -14)
        ])
        
        // Handle Escape key
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.close()
                return nil
            }
            return event
        }
    }
    
    private func bindEvents() {
        calendarService.$upcomingEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshUI() }
            .store(in: &cancellables)
        
        calendarService.$permissionDenied
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshUI() }
            .store(in: &cancellables)
    }
    
    private func refreshUI() {
        // Clear existing rows
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Header
        let header = makeHeaderLabel()
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(8, after: header)
        
        let separator = makeSeparator()
        contentStack.addArrangedSubview(separator)
        contentStack.setCustomSpacing(8, after: separator)
        
        if calendarService.permissionDenied {
            let label = makeBodyLabel("Enable Calendar access in\nSystem Settings → Privacy → Calendars")
            contentStack.addArrangedSubview(label)
        } else {
            let now = Date()
            let endOfDay = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now)
            let todayEvents = calendarService.upcomingEvents.filter { $0.startDate < endOfDay }
            
            if todayEvents.isEmpty {
                let label = makeBodyLabel("No events today")
                contentStack.addArrangedSubview(label)
            } else {
                for event in todayEvents {
                    let row = makeEventRow(event)
                    contentStack.addArrangedSubview(row)
                    contentStack.setCustomSpacing(6, after: row)
                }
            }
        }
        
        // Resize panel to fit content
        contentStack.layoutSubtreeIfNeeded()
        let height = contentStack.fittingSize.height + 24
        let clampedHeight = max(80, min(400, height))
        var frame = self.frame
        let delta = clampedHeight - frame.height
        frame.origin.y -= delta
        frame.size.height = clampedHeight
        setFrame(frame, display: true)
    }
    
    // MARK: - Factory helpers
    
    private func makeHeaderLabel() -> NSTextField {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMM"
        let label = NSTextField(labelWithString: "Today · " + formatter.string(from: Date()))
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        return label
    }
    
    private func makeSeparator() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.2).cgColor
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        v.widthAnchor.constraint(equalToConstant: 272).isActive = true
        return v
    }
    
    private func makeBodyLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 11)
        label.textColor = NSColor.white.withAlphaComponent(0.7)
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 2
        return label
    }
    
    private func makeEventRow(_ event: EKEvent) -> NSView {
        let container = NSStackView()
        container.orientation = .horizontal
        container.spacing = 6
        container.alignment = .centerY
        
        // Calendar color dot
        let dot = NSView()
        dot.wantsLayer = true
        if let calColor = event.calendar?.cgColor {
            dot.layer?.backgroundColor = calColor
        } else {
            dot.layer?.backgroundColor = NSColor.systemBlue.cgColor
        }
        dot.layer?.cornerRadius = 4
        dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        container.addArrangedSubview(dot)
        
        // Time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeLabel = NSTextField(labelWithString: timeFormatter.string(from: event.startDate))
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = NSColor.white.withAlphaComponent(0.7)
        timeLabel.widthAnchor.constraint(equalToConstant: 36).isActive = true
        container.addArrangedSubview(timeLabel)
        
        // Title
        var title = event.title ?? "(No title)"
        if title.count > 28 { title = String(title.prefix(28)) + "…" }
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        container.addArrangedSubview(titleLabel)
        
        return container
    }
}
