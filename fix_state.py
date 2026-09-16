import re

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'r') as f:
    content = f.read()

# Replace refreshApps() call with direct code inside onAppear and Button action
on_appear_code = """        .onAppear {
            self.apps = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .accessory || $0.activationPolicy == .prohibited }
                .filter { $0.localizedName != nil && !$0.localizedName!.isEmpty }
                .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
        }"""

button_code = """                            Button(action: {
                                app.terminate()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.apps = NSWorkspace.shared.runningApplications
                                        .filter { $0.activationPolicy == .accessory || $0.activationPolicy == .prohibited }
                                        .filter { $0.localizedName != nil && !$0.localizedName!.isEmpty }
                                        .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
                                }
                            }) {"""

content = re.sub(r"\s*\.onAppear \{\n\s*refreshApps\(\)\n\s*\}", "\n" + on_appear_code, content)
content = re.sub(r"\s*Button\(action: \{\n\s*app\.terminate\(\)\n\s*refreshApps\(\)\n\s*\}\) \{", "\n" + button_code, content)
content = re.sub(r"\s*private func refreshApps\(\) \{\n.*?\n\s*\}", "", content, flags=re.DOTALL)

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'w') as f:
    f.write(content)

