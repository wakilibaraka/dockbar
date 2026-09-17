import AppKit
import Combine

struct ClosedAppInfo: Equatable {
    let bundleIdentifier: String
    let localizedName: String
    let icon: NSImage?
    let closedAt: Date
    
    static func == (lhs: ClosedAppInfo, rhs: ClosedAppInfo) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}

final class RecentlyClosedTracker: ObservableObject {
    static let shared = RecentlyClosedTracker()
    
    @Published private(set) var closedApps: [ClosedAppInfo] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .sink { [weak self] notification in
                guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleID = app.bundleIdentifier,
                      let name = app.localizedName else { return }
                
                self?.addClosedApp(bundleID: bundleID, name: name, icon: app.icon)
            }
            .store(in: &cancellables)
    }
    
    private func addClosedApp(bundleID: String, name: String, icon: NSImage?) {
        // Remove if already in list to update its position to the top
        closedApps.removeAll { $0.bundleIdentifier == bundleID }
        
        let info = ClosedAppInfo(bundleIdentifier: bundleID, localizedName: name, icon: icon, closedAt: Date())
        closedApps.insert(info, at: 0)
        
        if closedApps.count > 10 {
            closedApps.removeLast()
        }
    }
    
    func remove(bundleIdentifier: String) {
        closedApps.removeAll { $0.bundleIdentifier == bundleIdentifier }
    }
}
