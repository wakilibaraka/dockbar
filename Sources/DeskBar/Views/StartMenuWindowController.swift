import AppKit

final class StartMenuWindowController: NSWindowController {
    static let shared = StartMenuWindowController()

    private let searchField = NSSearchField()
    private let appsTableView = NSTableView()
    private let scrollView = NSScrollView()
    
    // Simplistic application model
    private var allApps: [URL] = []
    private var filteredApps: [URL] = []

    init() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isFloatingPanel = true
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        super.init(window: window)
        
        setupUI()
        loadApps()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let window = window else { return }
        
        let visualEffect = NSVisualEffectView(frame: window.contentRect(forFrameRect: window.frame))
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.cornerCurve = .continuous
        visualEffect.layer?.masksToBounds = true
        window.contentView = visualEffect
        
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.font = .systemFont(ofSize: 18)
        searchField.focusRingType = .none
        searchField.target = self
        searchField.action = #selector(searchAction(_:))
        visualEffect.addSubview(searchField)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = appsTableView
        scrollView.drawsBackground = false
        visualEffect.addSubview(scrollView)
        
        appsTableView.headerView = nil
        appsTableView.backgroundColor = .clear
        appsTableView.delegate = self
        appsTableView.dataSource = self
        appsTableView.target = self
        appsTableView.doubleAction = #selector(launchSelectedApp)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AppColumn"))
        appsTableView.addTableColumn(column)
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: visualEffect.topAnchor, constant: 16),
            searchField.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -16),
            
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadApps() {
        let fileManager = FileManager.default
        let appDirs = ["/Applications", "/System/Applications", NSHomeDirectory() + "/Applications"]
        
        var apps: [URL] = []
        for dir in appDirs {
            let url = URL(fileURLWithPath: dir)
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "app" {
                        apps.append(fileURL)
                    }
                }
            }
        }
        allApps = apps.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        filteredApps = allApps
        appsTableView.reloadData()
    }
    
    @objc private func searchAction(_ sender: NSSearchField) {
        let query = sender.stringValue.lowercased()
        if query.isEmpty {
            filteredApps = allApps
        } else {
            filteredApps = allApps.filter { $0.lastPathComponent.lowercased().contains(query) }
        }
        appsTableView.reloadData()
    }
    
    @objc private func launchSelectedApp() {
        let row = appsTableView.selectedRow
        guard row >= 0 && row < filteredApps.count else { return }
        
        let appURL = filteredApps[row]
        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        
        toggle()
    }
    
    func toggle() {
        guard let window = window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            // Position above the taskbar on the left side
            if let screen = NSScreen.main {
                let x = screen.frame.minX + 12 // Slightly offset from left edge
                let y: CGFloat = 60 // Just above the taskbar
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            searchField.stringValue = ""
            searchAction(searchField)
            
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(searchField)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

extension StartMenuWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredApps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let appURL = filteredApps[row]
        let cellIdentifier = NSUserInterfaceItemIdentifier("AppCell")
        
        var cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellIdentifier
            
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cellView?.addSubview(imageView)
            cellView?.imageView = imageView
            
            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.font = .systemFont(ofSize: 14)
            textField.textColor = .white
            cellView?.addSubview(textField)
            cellView?.textField = textField
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                imageView.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 32),
                imageView.heightAnchor.constraint(equalToConstant: 32),
                
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4)
            ])
        }
        
        cellView?.textField?.stringValue = appURL.deletingPathExtension().lastPathComponent
        cellView?.imageView?.image = NSWorkspace.shared.icon(forFile: appURL.path)
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40
    }
}
