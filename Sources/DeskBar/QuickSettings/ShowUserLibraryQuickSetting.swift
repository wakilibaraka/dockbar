import Foundation

final class ShowUserLibraryQuickSetting: QuickSetting {
    let id = "showUserLibrary"
    let title = "Show Library"
    let symbolName = "books.vertical.fill"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        if let values = try? url.resourceValues(forKeys: [.isHiddenKey]), let isHidden = values.isHidden {
            isOn = !isHidden
        } else {
            isOn = false
        }
    }
    
    func toggle() {
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library").path
        let chflagsProc = Process()
        chflagsProc.executableURL = URL(fileURLWithPath: "/usr/bin/chflags")
        chflagsProc.arguments = [isOn ? "hidden" : "nohidden", path]
        try? chflagsProc.run()
        chflagsProc.waitUntilExit()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.refreshState() }
    }
}
