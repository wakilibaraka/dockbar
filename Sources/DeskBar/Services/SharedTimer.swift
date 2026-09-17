import Combine
import Foundation

@MainActor
final class SharedTimer {
    static let shared = SharedTimer()
    
    let tick2s = PassthroughSubject<Void, Never>()
    let tick5s = PassthroughSubject<Void, Never>()
    
    private var timer: DispatchSourceTimer?
    private var tickCount = 0
    
    private init() {
        start()
    }
    
    private func start() {
        let queue = DispatchQueue(label: "com.deskbar.sharedtimer", qos: .background)
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 2.0)
        
        timer?.setEventHandler { [weak self] in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.tick2s.send()
                
                self.tickCount += 2
                if self.tickCount >= 6 {
                    self.tick5s.send()
                    self.tickCount = 0
                }
            }
        }
        timer?.resume()
    }
}
