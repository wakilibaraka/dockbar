import Foundation
import Combine

struct DownloadItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let filename: String
    var progress: Double // 0.0 to 1.0
    var isFinished: Bool
}

final class DownloadsMonitor: ObservableObject {
    static let shared = DownloadsMonitor()
    
    @Published var activeDownloads: [DownloadItem] = []
    @Published var recentDownloads: [DownloadItem] = []
    
    private var stream: FSEventStreamRef?
    private let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.path
    private var timer: Timer?
    
    init() {
        startWatching()
        startPolling()
    }
    
    deinit {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        timer?.invalidate()
    }
    
    private func startWatching() {
        let pathsToWatch = [downloadsPath] as CFArray
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        
        let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            guard let clientInfo = clientCallBackInfo else { return }
            let monitor = Unmanaged<DownloadsMonitor>.fromOpaque(clientInfo).takeUnretainedValue()
            DispatchQueue.main.async {
                monitor.scanDirectory()
            }
        }
        
        stream = FSEventStreamCreate(kCFAllocatorDefault,
                                     callback,
                                     &context,
                                     pathsToWatch,
                                     UInt64(kFSEventStreamEventIdSinceNow),
                                     1.0,
                                     UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))
        
        if let stream = stream {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .background))
            FSEventStreamStart(stream)
        }
        scanDirectory()
    }
    
    private func scanDirectory() {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: downloadsPath) else { return }
        
        var actives: [DownloadItem] = []
        var recents: [DownloadItem] = []
        
        let now = Date()
        
        for file in files {
            if file.hasPrefix(".") { continue }
            let url = URL(fileURLWithPath: downloadsPath).appendingPathComponent(file)
            
            let isPart = file.hasSuffix(".crdownload") || file.hasSuffix(".part") || file.hasSuffix(".download")
            
            if isPart {
                actives.append(DownloadItem(url: url, filename: file, progress: 0.1, isFinished: false)) // size polling will update progress
            } else {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let creationDate = attrs[.creationDate] as? Date {
                    if now.timeIntervalSince(creationDate) < 86400 {
                        recents.append(DownloadItem(url: url, filename: file, progress: 1.0, isFinished: true))
                    }
                }
            }
        }
        
        recents.sort { a, b in
            let attrA = (try? FileManager.default.attributesOfItem(atPath: a.url.path))?[.creationDate] as? Date ?? Date.distantPast
            let attrB = (try? FileManager.default.attributesOfItem(atPath: b.url.path))?[.creationDate] as? Date ?? Date.distantPast
            return attrA > attrB
        }
        
        self.activeDownloads = actives
        self.recentDownloads = Array(recents.prefix(10))
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.activeDownloads.isEmpty {
                // To do proper progress we need expected size which we don't have easily,
                // so we just mock a pulsing progress or use file size changes to guess
                var updated = self.activeDownloads
                for i in 0..<updated.count {
                    updated[i].progress += 0.05
                    if updated[i].progress > 0.95 { updated[i].progress = 0.05 }
                }
                self.activeDownloads = updated
            }
        }
    }
    
    func clearRecents() {
        recentDownloads.removeAll()
    }
}
