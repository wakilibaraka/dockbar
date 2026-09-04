import AppKit
import Combine

final class DashboardCenterView: NSView, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private var pinnedAppManager: PinnedAppManager?
    private var recents: [SearchResultItem] = []
    
    private let pinnedCollectionView = NSCollectionView()
    private let recentsCollectionView = NSCollectionView()
    
    private var recentsQuery: NSMetadataQuery?
    private var cancellables = Set<AnyCancellable>()
    
    var onToggleAllApps: (() -> Void)?
    var onLaunchApp: ((URL) -> Void)?
    
    init() {
        super.init(frame: .zero)
        setupUI()
        setupRecentsQuery()
    }
    
    func configure(pinnedAppManager: PinnedAppManager) {
        self.pinnedAppManager = pinnedAppManager
        pinnedAppManager.$pinnedApps
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.pinnedCollectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let pinnedHeader = makeHeader(title: "Pinned", buttonTitle: "All apps \u{2192}") { [weak self] in
            self?.onToggleAllApps?()
        }
        
        setupCollectionView(pinnedCollectionView)
        
        let recentsHeader = makeHeader(title: "Recommended", buttonTitle: "More \u{2192}") {
            // maybe launch finder recents
        }
        
        setupCollectionView(recentsCollectionView)
        
        let stack = NSStackView(views: [pinnedHeader, pinnedCollectionView, recentsHeader, recentsCollectionView])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            pinnedCollectionView.widthAnchor.constraint(equalTo: widthAnchor),
            pinnedCollectionView.heightAnchor.constraint(equalToConstant: 200),
            
            recentsCollectionView.widthAnchor.constraint(equalTo: widthAnchor),
            
            pinnedHeader.widthAnchor.constraint(equalTo: widthAnchor),
            recentsHeader.widthAnchor.constraint(equalTo: widthAnchor)
        ])
    }
    
    private func setupCollectionView(_ cv: NSCollectionView) {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        cv.collectionViewLayout = layout
        cv.isSelectable = true
        cv.backgroundColors = [.clear]
        cv.dataSource = self
        cv.delegate = self
        cv.register(DashboardAppItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("DashboardAppItem"))
    }
    
    private func makeHeader(title: String, buttonTitle: String, action: @escaping () -> Void) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let btn = NSButton(title: buttonTitle, target: nil, action: nil)
        btn.isBordered = false
        btn.font = .systemFont(ofSize: 12)
        btn.contentTintColor = .secondaryLabelColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        let handler = ButtonHandler(action: action)
        btn.target = handler
        btn.action = #selector(ButtonHandler.invoke)
        objc_setAssociatedObject(btn, "handler", handler, .OBJC_ASSOCIATION_RETAIN)
        
        container.addSubview(label)
        container.addSubview(btn)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            btn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            btn.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func setupRecentsQuery() {
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "kMDItemContentTypeTree == 'com.apple.application-bundle'")
        query.searchScopes = [NSMetadataQueryUserHomeScope, "/Applications"]
        query.sortDescriptors = [NSSortDescriptor(key: "kMDItemLastUsedDate", ascending: false)]
        
        NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main) { [weak self] _ in
            self?.processRecentsQuery(query)
        }
        
        recentsQuery = query
        query.start()
    }
    
    private func processRecentsQuery(_ query: NSMetadataQuery) {
        var items: [SearchResultItem] = []
        let count = min(query.resultCount, 8)
        for i in 0..<count {
            if let item = query.result(at: i) as? NSMetadataItem,
               let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                items.append(.app(URL(fileURLWithPath: path)))
            }
        }
        recents = items
        recentsCollectionView.reloadData()
    }
    
    // MARK: - NSCollectionView
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == pinnedCollectionView {
            return pinnedAppManager?.pinnedApps.count ?? 0
        } else {
            return recents.count
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("DashboardAppItem"), for: indexPath) as! DashboardAppItem
        if collectionView == pinnedCollectionView {
            if let app = pinnedAppManager?.pinnedApps[indexPath.item] {
                item.configure(name: app.name, icon: app.icon)
            }
        } else {
            let searchItem = recents[indexPath.item]
            if case .app(let url) = searchItem {
                let name = url.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                item.configure(name: name, icon: icon)
            }
        }
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectItems(at: indexPaths)
        guard let idx = indexPaths.first?.item else { return }
        if collectionView == pinnedCollectionView {
            if let app = pinnedAppManager?.pinnedApps[idx], let url = app.applicationURL {
                onLaunchApp?(url)
            }
        } else {
            let searchItem = recents[idx]
            if case .app(let url) = searchItem {
                onLaunchApp?(url)
            }
        }
    }
}

final class DashboardAppItem: NSCollectionViewItem {
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.cornerRadius = 8
    }
    
    private let iconView = NSImageView()
    private let label = NSTextField(labelWithString: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11)
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 2
        
        view.addSubview(iconView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
            
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            label.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -4)
        ])
    }
    
    func configure(name: String, icon: NSImage?) {
        label.stringValue = name
        iconView.image = icon
    }
    
    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            view.layer?.backgroundColor = highlightState == .forSelection ? NSColor.selectedControlColor.cgColor : NSColor.clear.cgColor
        }
    }
    
    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected ? NSColor.selectedControlColor.cgColor : NSColor.clear.cgColor
        }
    }
}

private class ButtonHandler: NSObject {
    let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func invoke() { action() }
}
