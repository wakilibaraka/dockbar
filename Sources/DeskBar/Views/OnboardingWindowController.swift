import AppKit
import Combine

final class OnboardingWindowController: NSWindowController {
    static let shared = OnboardingWindowController()
    
    private let titleLabel = NSTextField(labelWithString: "Welcome to DeskBar")
    private let subtitleLabel = NSTextField(labelWithString: "Let's set up the permissions required for DeskBar to function fully.")
    
    private let axButton = NSButton(title: "Grant Accessibility Access", target: nil, action: nil)
    private let calendarButton = NSButton(title: "Grant Calendar Access", target: nil, action: nil)
    private let continueButton = NSButton(title: "Continue", target: nil, action: nil)
    
    private var permissions: PermissionsManager?
    private var calendar: CalendarEventService?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.titlebarAppearsTransparent = true
        window.title = ""
        super.init(window: window)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(permissions: PermissionsManager, calendar: CalendarEventService) {
        self.permissions = permissions
        self.calendar = calendar
        
        axButton.target = self
        axButton.action = #selector(requestAX)
        
        calendarButton.target = self
        calendarButton.action = #selector(requestCalendar)
        
        continueButton.target = self
        continueButton.action = #selector(finishOnboarding)
        
        permissions.$isAccessibilityGranted
            .receive(on: RunLoop.main)
            .sink { [weak self] granted in
                self?.axButton.title = granted ? "Accessibility Granted ✓" : "Grant Accessibility Access"
                self?.axButton.isEnabled = !granted
            }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        guard let window = window else { return }
        
        let container = NSView()
        window.contentView = container
        
        let stack = NSStackView(views: [titleLabel, subtitleLabel, axButton, calendarButton, continueButton])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor
        
        axButton.controlSize = .large
        calendarButton.controlSize = .large
        continueButton.controlSize = .large
        continueButton.bezelStyle = .rounded
        continueButton.keyEquivalent = "\r"
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
    
    @objc private func requestAX() {
        permissions?.requestAccessibilityPermission()
    }
    
    @objc private func requestCalendar() {
        calendar?.requestAccessAndFetch()
        calendarButton.title = "Calendar Requested"
        calendarButton.isEnabled = false
    }
    
    @objc private func finishOnboarding() {
        window?.orderOut(nil)
    }
}
