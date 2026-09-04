import AppKit
import Combine

final class ClockWidgetView: NSView {
    private let timeLabel = NSTextField(labelWithString: "")
    private let dateLabel = NSTextField(labelWithString: "")
    private var timer: Timer?
    private let settings: TaskbarSettings

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init(frame: .zero)

        setupView()
        updateTime()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    private func setupView() {
        wantsLayer = true
        
        let stackView = NSStackView(views: [timeLabel, dateLabel])
        stackView.orientation = .vertical
        stackView.alignment = .trailing
        stackView.spacing = 0
        
        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = .white
        dateLabel.font = .systemFont(ofSize: 11, weight: .regular)
        dateLabel.textColor = .white
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    private func updateTime() {
        let now = Date()
        let timeString = timeFormatter.string(from: now)
        let dateString = dateFormatter.string(from: now)
        
        if timeLabel.stringValue != timeString {
            timeLabel.stringValue = timeString
        }
        if dateLabel.stringValue != dateString {
            dateLabel.stringValue = dateString
        }
    }

    override func mouseDown(with event: NSEvent) {
        // Handle click to launch calendar
        let appName = settings.clockTargetApp
        
        if let url = URL(string: "calendar366://"), NSWorkspace.shared.urlForApplication(toOpen: url) != nil {
            NSWorkspace.shared.open(url)
            return
        }
        
        // Fallback to launching by name
        if !appName.isEmpty {
            let script = """
            try
                tell application "\(appName)" to activate
            on error
                log "Could not activate \(appName)"
            end try
            """
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }
}
