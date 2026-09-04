import AppKit
import Collaboration

final class DashboardRightRailView: NSView {
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let profileView = makeProfileView()
        let shortcutsView = makeShortcutsView()
        let powerView = makePowerControlsView()
        
        let stack = NSStackView(views: [profileView, shortcutsView, powerView])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
    
    private func makeProfileView() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 20
        imageView.layer?.masksToBounds = true
        
        let nameLabel = NSTextField(labelWithString: NSUserName())
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if let identity = CBIdentity(name: NSUserName(), authority: CBIdentityAuthority.default()) {
            nameLabel.stringValue = identity.fullName
            imageView.image = identity.image
        }
        
        container.addSubview(imageView)
        container.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        return container
    }
    
    private func makeShortcutsView() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let shortcuts = [
            ("Documents", "doc", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first),
            ("Downloads", "arrow.down.circle", FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first),
            ("Pictures", "photo", FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first),
            ("Music", "music.note", FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first)
        ]
        
        for (name, icon, url) in shortcuts {
            let btn = NSButton(title: name, image: NSImage(systemSymbolName: icon, accessibilityDescription: nil)!, target: nil, action: nil)
            btn.imagePosition = .imageLeft
            btn.isBordered = false
            btn.font = .systemFont(ofSize: 13)
            let handler = ShortcutHandler(url: url)
            btn.target = handler
            btn.action = #selector(ShortcutHandler.invoke)
            objc_setAssociatedObject(btn, "handler_\(name)", handler, .OBJC_ASSOCIATION_RETAIN)
            stack.addArrangedSubview(btn)
        }
        
        return stack
    }
    
    private func makePowerControlsView() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let controls = [
            ("Sleep", "moon.zzz", "tell application \"System Events\" to sleep"),
            ("Restart", "arrow.clockwise", "tell application \"System Events\" to restart"),
            ("Shut Down", "power", "tell application \"System Events\" to shut down"),
            ("Lock", "lock", "tell application \"System Events\" to keystroke \"q\" using {control down, command down}")
        ]
        
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(separator)
        NSLayoutConstraint.activate([separator.widthAnchor.constraint(equalToConstant: 200)])
        
        for (name, icon, script) in controls {
            let btn = NSButton(title: name, image: NSImage(systemSymbolName: icon, accessibilityDescription: nil)!, target: nil, action: nil)
            btn.imagePosition = .imageLeft
            btn.isBordered = false
            btn.font = .systemFont(ofSize: 13)
            let handler = PowerHandler(name: name, scriptString: script)
            btn.target = handler
            btn.action = #selector(PowerHandler.invoke)
            objc_setAssociatedObject(btn, "handler_\(name)", handler, .OBJC_ASSOCIATION_RETAIN)
            stack.addArrangedSubview(btn)
        }
        
        return stack
    }
}

private class ShortcutHandler: NSObject {
    let url: URL?
    init(url: URL?) { self.url = url }
    @objc func invoke() {
        if let url = url {
            NSWorkspace.shared.open(url)
            StartMenuWindowController.shared.toggle()
        }
    }
}

private class PowerHandler: NSObject {
    let name: String
    let scriptString: String
    init(name: String, scriptString: String) {
        self.name = name
        self.scriptString = scriptString
    }
    @objc func invoke() {
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to \(name.lowercased())?"
        alert.informativeText = "Any unsaved changes may be lost."
        alert.addButton(withTitle: name)
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let script = NSAppleScript(source: scriptString) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                if let error = error {
                    print("Error executing power script: \(error)")
                }
            }
        }
    }
}
