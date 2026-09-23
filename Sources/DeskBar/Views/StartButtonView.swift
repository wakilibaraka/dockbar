import AppKit

final class StartButtonView: NSView {
    private let button = NSButton()
    private static let fixedWidth: CGFloat = 40
    private var popover: BorderlessFlyout?
    private let settings: TaskbarSettings
    private let pinnedAppManager: PinnedAppManager

    init(settings: TaskbarSettings, pinnedAppManager: PinnedAppManager) {
        self.settings = settings
        self.pinnedAppManager = pinnedAppManager
        super.init(frame: NSRect(x: 0, y: 0, width: Self.fixedWidth, height: 32))
        
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "square.grid.2x2.fill", accessibilityDescription: "Start")
        button.target = self
        button.action = #selector(toggleStartMenu)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func preferredContentWidth() -> CGFloat { Self.fixedWidth }
    
    @objc private func toggleStartMenu() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }
        
        let newPopover = BorderlessFlyout()
        
        newPopover.show(contentViewController: StartMenuViewController(settings: settings, pinnedAppManager: pinnedAppManager), relativeTo: bounds, of: self)
        popover = newPopover
    }
}
