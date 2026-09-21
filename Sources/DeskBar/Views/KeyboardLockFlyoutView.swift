import SwiftUI

struct KeyboardLockFlyoutView: View {
    @ObservedObject var setting: KeyboardLockQuickSetting
    var onChange: (() -> Void)?
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                setting.isOn ? "Keyboard Locked" : "Keyboard Lock",
                systemImage: setting.isOn ? "lock.fill" : "keyboard"
            )
            .font(.headline)

            if setting.isOn {
                Text("Unlocks automatically in \(remainingText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Unlock") {
                    setting.toggle()
                    onChange?()
                }
            } else {
                Button("Lock Keyboard") {
                    setting.toggle()
                    onChange?()
                }
            }
        }
        .padding(16)
        .frame(width: 220)
        .onReceive(timer) { now = $0 }
    }

    private var remainingText: String {
        guard let unlockDate = setting.unlockDate else { return "less than 5 minutes" }
        let seconds = max(0, Int(unlockDate.timeIntervalSince(now).rounded(.up)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
