import AppKit
import Combine

enum SearchResultItem: Equatable {
    case app(URL)
    case file(URL)
    case webSearch(String)
}

final class StartMenuWindowController: NSWindowController, NSSearchFieldDelegate, NSWindowDelegate {
    static let shared = StartMenuWindowController()

    private var settings: TaskbarSettings?
    private let searchField = NSSearchField()
    private let resultsTableView = NSTableView()
    private let scrollView = NSScrollView()
    
    func configure(settings: TaskbarSettings, pinnedAppManager: PinnedAppManager) {
        self.settings = settings
        self.dashboardCenterView?.configure(pinnedAppManager: pinnedAppManager)
        self.leftWidgetsView?.configure(settings: settings)
    }
    
    // Simplistic application model
    private var allApps: [URL] = []
    private var displayedResults: [SearchResultItem] = []
    
    private var metadataQuery: NSMetadataQuery?
    private var isSearching = false
    private var outsideClickMonitor: Any?
    private var searchDebounceTimer: Timer?
    
    init() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 600),
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
        window.delegate = self
        
        setupUI()
        loadApps()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopQuery()
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private let bodyStackView = NSStackView()
    private let leftWidgetsContainer = NSView()
    private let centerDashboardContainer = NSView()
    private let rightRailContainer = NSView()
    private var leftWidgetsView: DashboardLeftWidgetsView?
    private var dashboardCenterView: DashboardCenterView?
    
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
        searchField.font = .systemFont(ofSize: 22, weight: .regular)
        searchField.focusRingType = .none
        searchField.delegate = self
        searchField.placeholderString = "Search apps, files, or web..."
        visualEffect.addSubview(searchField)
        
        bodyStackView.translatesAutoresizingMaskIntoConstraints = false
        bodyStackView.orientation = .horizontal
        bodyStackView.spacing = 16
        bodyStackView.distribution = .fillProportionally
        visualEffect.addSubview(bodyStackView)
        
        leftWidgetsContainer.translatesAutoresizingMaskIntoConstraints = false
        centerDashboardContainer.translatesAutoresizingMaskIntoConstraints = false
        rightRailContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup simple list (scrollView) inside center container for now
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = resultsTableView
        scrollView.drawsBackground = false
        centerDashboardContainer.addSubview(scrollView)
        

        
        let dashboardCenterView = DashboardCenterView()
        dashboardCenterView.translatesAutoresizingMaskIntoConstraints = false
        centerDashboardContainer.addSubview(dashboardCenterView)
        
        self.dashboardCenterView = dashboardCenterView
        
        dashboardCenterView.onToggleAllApps = { [weak self] in
            guard let self = self else { return }
            let showingList = !self.scrollView.isHidden
            self.scrollView.isHidden = showingList
            self.dashboardCenterView?.isHidden = !showingList
        }
        
        dashboardCenterView.onLaunchApp = { [weak self] url in
            NSWorkspace.shared.open(url)
            self?.toggle() // close menu
        }
        
        let rightRailView = DashboardRightRailView()
        rightRailView.translatesAutoresizingMaskIntoConstraints = false
        rightRailContainer.addSubview(rightRailView)
        
        let leftWidgetsView = DashboardLeftWidgetsView()
        self.leftWidgetsView = leftWidgetsView
        leftWidgetsView.translatesAutoresizingMaskIntoConstraints = false
        leftWidgetsContainer.addSubview(leftWidgetsView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: centerDashboardContainer.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: centerDashboardContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: centerDashboardContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: centerDashboardContainer.trailingAnchor),
            
            dashboardCenterView.topAnchor.constraint(equalTo: centerDashboardContainer.topAnchor),
            dashboardCenterView.bottomAnchor.constraint(equalTo: centerDashboardContainer.bottomAnchor),
            dashboardCenterView.leadingAnchor.constraint(equalTo: centerDashboardContainer.leadingAnchor),
            dashboardCenterView.trailingAnchor.constraint(equalTo: centerDashboardContainer.trailingAnchor),
            
            rightRailView.topAnchor.constraint(equalTo: rightRailContainer.topAnchor),
            rightRailView.bottomAnchor.constraint(equalTo: rightRailContainer.bottomAnchor),
            rightRailView.leadingAnchor.constraint(equalTo: rightRailContainer.leadingAnchor),
            rightRailView.trailingAnchor.constraint(equalTo: rightRailContainer.trailingAnchor),
            
            leftWidgetsView.topAnchor.constraint(equalTo: leftWidgetsContainer.topAnchor),
            leftWidgetsView.bottomAnchor.constraint(equalTo: leftWidgetsContainer.bottomAnchor),
            leftWidgetsView.leadingAnchor.constraint(equalTo: leftWidgetsContainer.leadingAnchor),
            leftWidgetsView.trailingAnchor.constraint(equalTo: leftWidgetsContainer.trailingAnchor)
        ])
        
        bodyStackView.addArrangedSubview(leftWidgetsContainer)
        bodyStackView.addArrangedSubview(centerDashboardContainer)
        bodyStackView.addArrangedSubview(rightRailContainer)
        
        // Set widths for side panels
        NSLayoutConstraint.activate([
            leftWidgetsContainer.widthAnchor.constraint(equalToConstant: 240),
            rightRailContainer.widthAnchor.constraint(equalToConstant: 240)
        ])
        
        resultsTableView.headerView = nil
        resultsTableView.backgroundColor = .clear
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.target = self
        resultsTableView.doubleAction = #selector(launchSelectedResult)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ResultColumn"))
        resultsTableView.addTableColumn(column)
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: visualEffect.topAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -20),
            
            bodyStackView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 16),
            bodyStackView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 20),
            bodyStackView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -20),
            bodyStackView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadApps() {
        DispatchQueue.global(qos: .userInitiated).async {
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
            let sortedApps = apps.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            DispatchQueue.main.async {
                self.allApps = sortedApps
                if self.searchField.stringValue.isEmpty {
                    self.displayedResults = self.allApps.map { .app($0) }
                    self.resultsTableView.reloadData()
                }
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        searchDebounceTimer?.invalidate()
        
        let query = searchField.stringValue
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if settings?.startMenuStyle == .fullDashboard {
            let isTyping = !trimmed.isEmpty
            scrollView.isHidden = !isTyping
            dashboardCenterView?.isHidden = isTyping
        }
        
        if trimmed.isEmpty {
            stopQuery()
            displayedResults = allApps.map { .app($0) }
            resultsTableView.reloadData()
            return
        }
        
        // Fast local app search (immediate)
        let lowerQuery = trimmed.lowercased()
        let appMatches = allApps.filter { $0.lastPathComponent.lowercased().contains(lowerQuery) }
        var initialResults = appMatches.map { SearchResultItem.app($0) }
        initialResults.append(.webSearch(trimmed))
        
        displayedResults = initialResults
        resultsTableView.reloadData()
        resultsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        
        // Debounced file search
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.startFileSearch(query: trimmed)
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            launchSelectedResult()
            return true
        } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
            let row = resultsTableView.selectedRow
            if row > 0 {
                resultsTableView.selectRowIndexes(IndexSet(integer: row - 1), byExtendingSelection: false)
                resultsTableView.scrollRowToVisible(row - 1)
            }
            return true
        } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
            let row = resultsTableView.selectedRow
            if row < displayedResults.count - 1 {
                resultsTableView.selectRowIndexes(IndexSet(integer: row + 1), byExtendingSelection: false)
                resultsTableView.scrollRowToVisible(row + 1)
            }
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            toggle()
            return true
        }
        return false
    }
    
    private func startFileSearch(query: String) {
        stopQuery()
        let mdQuery = NSMetadataQuery()
        mdQuery.predicate = NSPredicate(format: "%K CONTAINS[cd] %@", NSMetadataItemFSNameKey, query)
        mdQuery.searchScopes = [NSMetadataQueryUserHomeScope]
        
        NotificationCenter.default.addObserver(self, selector: #selector(queryDidUpdate(_:)), name: .NSMetadataQueryDidUpdate, object: mdQuery)
        NotificationCenter.default.addObserver(self, selector: #selector(queryDidUpdate(_:)), name: .NSMetadataQueryDidFinishGathering, object: mdQuery)
        
        self.metadataQuery = mdQuery
        mdQuery.start()
    }
    
    @objc private func queryDidUpdate(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }
        query.disableUpdates()
        
        var files: [URL] = []
        let count = min(query.resultCount, 15) // Limit to 15 files
        for i in 0..<count {
            if let item = query.result(at: i) as? NSMetadataItem,
               let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                files.append(URL(fileURLWithPath: path))
            }
        }
        
        // Merge results: Apps -> Files -> WebSearch
        let apps = displayedResults.compactMap { if case .app(let u) = $0 { return u } else { return nil } }
        let web = displayedResults.compactMap { if case .webSearch(let q) = $0 { return q } else { return nil } }.first ?? ""
        
        var newResults = apps.map { SearchResultItem.app($0) }
        newResults.append(contentsOf: files.map { SearchResultItem.file($0) })
        if !web.isEmpty {
            newResults.append(.webSearch(web))
        }
        
        displayedResults = newResults
        resultsTableView.reloadData()
        
        query.enableUpdates()
    }
    
    private func stopQuery() {
        if let query = metadataQuery {
            query.stop()
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: query)
            NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: query)
            metadataQuery = nil
        }
    }
    
    @objc private func launchSelectedResult() {
        let row = resultsTableView.selectedRow
        guard row >= 0 && row < displayedResults.count else { return }
        
        let item = displayedResults[row]
        switch item {
        case .app(let url), .file(let url):
            NSWorkspace.shared.open(url)
        case .webSearch(let query):
            if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                NSWorkspace.shared.open(url)
            }
        }
        
        toggle()
    }
    
    enum Mode {
        case start
        case search
    }

    func toggle(mode: Mode = .start, triggerView: NSView? = nil) {
        guard let window = window else { return }
        if window.isVisible {
            window.orderOut(nil)
            if let m = outsideClickMonitor {
                NSEvent.removeMonitor(m)
                outsideClickMonitor = nil
            }
            stopQuery()
        } else {
            let isDashboard = settings?.startMenuStyle == .fullDashboard
            let width: CGFloat = isDashboard ? 900 : 450
            let height: CGFloat = 600
            
            if window.frame.width != width {
                var newFrame = window.frame
                newFrame.size = NSSize(width: width, height: height)
                window.setFrame(newFrame, display: true)
            }
            
            leftWidgetsContainer.isHidden = !isDashboard
            rightRailContainer.isHidden = !isDashboard
            
            if let triggerView = triggerView {
                FlyoutAnchorHelper.position(flyout: window, relativeTo: triggerView, gap: 12)
            } else if let screen = NSScreen.main {
                let x = screen.frame.minX + 12
                let y: CGFloat = 60
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            searchField.placeholderString = mode == .search ? "Search files..." : "Type to search..."
            searchField.stringValue = ""
            
            if isDashboard && mode != .search {
                scrollView.isHidden = true
                dashboardCenterView?.isHidden = false
            } else {
                scrollView.isHidden = false
                dashboardCenterView?.isHidden = true
            }
            
            if mode == .search {
                displayedResults = allApps.map { .app($0) }
                resultsTableView.reloadData()
            } else {
                stopQuery()
                displayedResults = allApps.map { .app($0) }
                resultsTableView.reloadData()
            }
            
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            window.makeFirstResponder(searchField)
            
            outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                DispatchQueue.main.async {
                    if self?.window?.isVisible == true {
                        self?.toggle()
                    }
                }
            }
        }
    }
    func windowDidResignKey(_ notification: Notification) {
        toggle()
    }
}

extension StartMenuWindowController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayedResults.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = displayedResults[row]
        let cellIdentifier = NSUserInterfaceItemIdentifier("ResultCell")
        
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
            textField.lineBreakMode = .byTruncatingMiddle
            cellView?.addSubview(textField)
            cellView?.textField = textField
            
            let secondaryLabel = NSTextField(labelWithString: "")
            secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
            secondaryLabel.font = .systemFont(ofSize: 11)
            secondaryLabel.textColor = NSColor.white.withAlphaComponent(0.6)
            secondaryLabel.lineBreakMode = .byTruncatingMiddle
            secondaryLabel.tag = 999
            cellView?.addSubview(secondaryLabel)
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                imageView.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 32),
                imageView.heightAnchor.constraint(equalToConstant: 32),
                
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                textField.topAnchor.constraint(equalTo: cellView!.topAnchor, constant: 6),
                
                secondaryLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
                secondaryLabel.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                secondaryLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 2)
            ])
        }
        
        let secondaryLabel = cellView?.viewWithTag(999) as? NSTextField
        
        switch item {
        case .app(let url):
            cellView?.textField?.stringValue = url.deletingPathExtension().lastPathComponent
            secondaryLabel?.stringValue = "Application"
            cellView?.imageView?.image = NSWorkspace.shared.icon(forFile: url.path)
        case .file(let url):
            cellView?.textField?.stringValue = url.lastPathComponent
            secondaryLabel?.stringValue = url.deletingLastPathComponent().path
            cellView?.imageView?.image = NSWorkspace.shared.icon(forFile: url.path)
        case .webSearch(let query):
            cellView?.textField?.stringValue = "Search the web for '\(query)'"
            secondaryLabel?.stringValue = "Web Search"
            let image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            image?.isTemplate = true
            cellView?.imageView?.image = image
            cellView?.imageView?.contentTintColor = NSColor.white.withAlphaComponent(0.8)
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 48
    }
}
