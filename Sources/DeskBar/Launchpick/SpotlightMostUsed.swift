import Foundation
import AppKit

class SpotlightMostUsed {
    static let shared = SpotlightMostUsed()
    private var query = NSMetadataQuery()
    private var completion: (([LaunchpickItem]) -> Void)?
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidFinish),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )
    }
    
    func fetch(limit: Int = 8, completion: @escaping ([LaunchpickItem]) -> Void) {
        self.completion = completion
        query.stop()
        
        let predicate = NSPredicate(format: "kMDItemContentType == 'com.apple.application-bundle'")
        query.predicate = predicate
        query.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemLastUsedDateKey, ascending: false)]
        query.valueListAttributes = [NSMetadataItemPathKey]
        
        query.start()
    }
    
    @objc private func queryDidFinish(_ notification: Notification) {
        query.stop()
        
        var items: [LaunchpickItem] = []
        let limit = 8
        
        for i in 0..<query.resultCount {
            guard let item = query.result(at: i) as? NSMetadataItem else { continue }
            guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { continue }
            
            // Skip hidden or core services apps
            guard path.hasPrefix("/Applications") || path.hasPrefix("/System/Applications") else { continue }
            guard !path.contains("/Contents/") else { continue }
            
            let url = URL(fileURLWithPath: path)
            let name = url.deletingPathExtension().lastPathComponent
            let icon = NSWorkspace.shared.icon(forFile: path)
            
            items.append(LaunchpickItem(
                name: name,
                exec: "open -a '\(name)'",
                icon: icon,
                category: "Most Used"
            ))
            
            if items.count >= limit { break }
        }
        
        DispatchQueue.main.async {
            self.completion?(items)
        }
    }
}
