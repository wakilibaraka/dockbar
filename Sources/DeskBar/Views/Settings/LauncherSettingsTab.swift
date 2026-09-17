import SwiftUI

struct LauncherSettingsTab: View {
    @ObservedObject var pinnedAppManager: PinnedAppManager
    class ViewState: ObservableObject { @Published var isShowingFilePicker = false }
    @StateObject private var state = ViewState()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Pinned Applications")
                .font(.headline)
            Text("These apps will always be pinned to the DeskBar launcher.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button("Add Application...") {
                    state.isShowingFilePicker = true
                }
                Spacer()
            }
            .padding(.vertical, 8)
            
            List {
                ForEach(pinnedAppManager.pinnedApps, id: \.bundleIdentifier) { app in
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "app.dashed")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(app.name)
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            pinnedAppManager.unpin(bundleIdentifier: app.bundleIdentifier)
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
        .fileImporter(
            isPresented: $state.isShowingFilePicker,
            allowedContentTypes: [.application],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first, let bundle = Bundle(url: url), let bundleIdentifier = bundle.bundleIdentifier {
                    if let name = bundle.infoDictionary?["CFBundleName"] as? String { pinnedAppManager.pin(bundleIdentifier: bundleIdentifier, name: name) }
                }
            case .failure(let error):
                print("Failed to select app: \(error.localizedDescription)")
            }
        }
    }
}
