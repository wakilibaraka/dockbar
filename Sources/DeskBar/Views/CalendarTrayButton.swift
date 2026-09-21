import AppKit

final class CalendarTrayButton: NSView {
    let button = NSButton()
    private var trackingArea: NSTrackingArea?
    var target: AnyObject? { get { button.target } set { button.target = newValue } }
    var action: Selector? { get { button.action } set { button.action = newValue } }
    
    private let calendarIconView = CalendarIconView()
    private let dayLabel = NSTextField(labelWithString: "")
    
    private let stackView = NSStackView()
    
    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.cornerCurve = .continuous
        
        button.isBordered = false
        button.title = ""
        button.imagePosition = .imageOnly
        button.alphaValue = 0 // Fully transparent, just captures clicks
        button.translatesAutoresizingMaskIntoConstraints = false
        
        dayLabel.font = .systemFont(ofSize: 13, weight: .medium)
        dayLabel.textColor = .labelColor
        dayLabel.alignment = .left
        
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(calendarIconView)
        stackView.addArrangedSubview(dayLabel)
        
        addSubview(stackView)
        addSubview(button)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 24),
            
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        updateDate()
        
        // Timer to update date automatically
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateDate()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    private func updateDate() {
        let date = Date()
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE" // e.g., "Thu"
        dayLabel.stringValue = dayFormatter.string(from: date)
        
        let dateNumFormatter = DateFormatter()
        dateNumFormatter.dateFormat = "d" // e.g., "17"
        calendarIconView.dateString = dateNumFormatter.string(from: date)

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        calendarIconView.monthString = monthFormatter.string(from: date)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea { removeTrackingArea(existing) }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self, userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
        }
    }

    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}

final class CalendarIconView: NSView {
    var monthString: String = "Jan" {
        didSet {
            guard monthString != oldValue else { return }
            needsDisplay = true
        }
    }

    var dateString: String = "1" {
        didSet {
            guard dateString != oldValue else { return }
            needsDisplay = true
        }
    }
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 18),
            heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        defer { context?.restoreGState() }
        
        let bounds = self.bounds
        let cornerRadius: CGFloat = 3.0
        let path = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        
        // The lower page follows the current appearance while the header keeps
        // the familiar calendar red.
        NSColor.controlBackgroundColor.setFill()
        path.fill()
        
        // Red header
        let headerHeight: CGFloat = 8.0
        let headerRect = NSRect(x: 0, y: bounds.height - headerHeight, width: bounds.width, height: headerHeight)
        let headerPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        // Clip to the header rect so we only draw the top part
        context?.saveGState()
        NSBezierPath(rect: headerRect).setClip()
        NSColor.systemRed.setFill()
        headerPath.fill()
        context?.restoreGState()
        
        // Red border
        NSColor.systemRed.setStroke()
        path.lineWidth = 2.0
        path.stroke()
        
        let monthParagraph = NSMutableParagraphStyle()
        monthParagraph.alignment = .center
        let monthAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 5.5, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: monthParagraph
        ]
        let monthRect = NSRect(x: 0, y: bounds.height - headerHeight + 1.0, width: bounds.width, height: headerHeight - 1.0)
        monthString.draw(in: monthRect, withAttributes: monthAttributes)

        // Date inside the page
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let fontSize: CGFloat = dateString.count > 1 ? 9 : 10
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let textSize = dateString.size(withAttributes: attributes)
        let textRect = NSRect(
            x: 0,
            y: (bounds.height - headerHeight - textSize.height) / 2.0 - 0.5,
            width: bounds.width,
            height: textSize.height
        )
        dateString.draw(in: textRect, withAttributes: attributes)
    }
}
