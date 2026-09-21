import SwiftUI

struct KeyboardLockFlyoutView: View {
    @ObservedObject var setting: KeyboardLockQuickSetting

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: setting.isOn ? "lock.fill" : "keyboard")
                .font(.system(size: 48))
                .foregroundColor(setting.isOn ? .red : .primary)

            Text(setting.isOn ? "Keyboard Locked" : "Keyboard is Active")
                .font(.headline)

            if setting.isOn {
                Text("Your keyboard is locked to allow cleaning without triggering inputs.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Text("It will auto-unlock in 5 minutes.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Button("Unlock Keyboard") {
                    setting.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Text("Lock your keyboard when you need to wipe it down without putting your Mac to sleep.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Button("Lock Keyboard") {
                    setting.toggle()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 300)
    }
}
