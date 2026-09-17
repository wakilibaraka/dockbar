import SwiftUI

struct BlacklistSettingsTab: View {
    @ObservedObject var blacklistManager: BlacklistManager
    class ViewState: ObservableObject { @Published var newBundleID = "" }
    @StateObject private var state = ViewState()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Hidden Applications")
                .font(.headline)
            Text("Applications listed here will not appear in DeskBar.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Bundle Identifier (e.g. com.apple.Safari)", text: $state.newBundleID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    blacklistManager.add(bundleIdentifier: state.newBundleID)
                    state.newBundleID = ""
                }
                .disabled(state.newBundleID.isEmpty)
            }
            .padding(.vertical, 8)
            
            List {
                ForEach(Array(blacklistManager.blacklistedBundleIDs).sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID)
                        Spacer()
                        Button(action: {
                            blacklistManager.remove(bundleIdentifier: bundleID)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
            .border(Color.secondary.opacity(0.2))
        }
        .padding()
    }
}
