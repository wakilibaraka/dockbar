import Foundation

final class ShowUserLibraryQuickSetting: QuickSetting {
    let id = "showUserLibrary"
    let title = "Show Library"
    let symbolName = "books.vertical.fill"
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library").path
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/ls")
        proc.arguments = ["-dO", path]
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        isOn = !output.contains("hidden") // if NOT hidden, isOn=true (showing)
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
