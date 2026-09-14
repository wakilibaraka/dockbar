import AppKit
import UserNotifications

final class PomodoroQuickSetting: QuickSetting {
    let id = "pomodoro"
    let title = "Pomodoro"
    let symbolName = "timer"
    var isOn: Bool = false
    
    private var timer: Timer?
    private static let duration: TimeInterval = 25 * 60
    
    deinit {
        timer?.invalidate()
    }
    
    func refreshState() {
        isOn = timer != nil
    }
    
    func toggle() {
        if isOn {
            timer?.invalidate()
            timer = nil
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: Self.duration, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    let content = UNMutableNotificationContent()
                    content.title = "Pomodoro Complete"
                    content.body = "25 minutes done! Take a break."
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request) { _ in }
                    self?.timer = nil
                    self?.refreshState()
                }
            }
        }
        refreshState()
    }
}
