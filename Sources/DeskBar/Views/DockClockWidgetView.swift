import AppKit
import SwiftUI

final class DockClockWidgetView: NSView {
    private let timeLabel = NSTextField(labelWithString: "")
    private let dateLabel = NSTextField(labelWithString: "")
    private let stack = NSStackView()
    private var timer: Timer?
    private let fixedWidth: CGFloat = 70
    
    private var flyout: BorderlessFlyout?

    
    init() {
        super.init(frame: .zero)
        
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = .labelColor
        timeLabel.alignment = .right
        
        dateLabel.font = .systemFont(ofSize: 10, weight: .regular)
        dateLabel.textColor = NSColor.labelColor.withAlphaComponent(0.8)
        dateLabel.alignment = .right
        
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.spacing = 0
        stack.addArrangedSubview(timeLabel)
        stack.addArrangedSubview(dateLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: fixedWidth)
        ])
        
        startTimer()
        updateDisplay()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startTimer() {
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func updateDisplay() {
        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        
        timeLabel.stringValue = timeFormatter.string(from: now)
        dateLabel.stringValue = dateFormatter.string(from: now)
    }
    
    func preferredContentWidth() -> CGFloat {
        return fixedWidth
    }

    override func mouseDown(with event: NSEvent) {
        if let current = flyout, current.isShown {
            current.performClose(nil)
            return
        }
        let popover = BorderlessFlyout()
        popover.onDismiss = { [weak self] in
            self?.flyout = nil
        }
        let hc = NSHostingController(rootView: CalendarView())
        popover.show(contentViewController: hc, relativeTo: bounds, of: self)
        flyout = popover
    }

    override func isAccessibilityElement() -> Bool { return true }
    override func accessibilityLabel() -> String? { return "ClockWidget" }
    override func accessibilityRole() -> NSAccessibility.Role? { return .button }
}
