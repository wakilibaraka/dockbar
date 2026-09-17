import re

with open('Sources/DeskBar/Views/BatteryFlyoutView.swift', 'r') as f:
    content = f.read()

# Remove the HStack that holds the duplicate buttons.
old_header = """            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DockBar")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Power & Devices")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        NSApp.sendAction(Selector(("restoreWindowsFromLastSleep:")), to: nil, from: nil)
                    }) {
                        Image(systemName: "uiwindow.split.2x1")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Restore Windows")
                    
                    Button(action: {
                        NSApp.sendAction(Selector(("openSettings:")), to: nil, from: nil)
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    
                    Button(action: {
                        NSApp.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Quit")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)"""

new_header = """            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DockBar")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Power & Devices")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)"""

if old_header in content:
    content = content.replace(old_header, new_header)
    with open('Sources/DeskBar/Views/BatteryFlyoutView.swift', 'w') as f:
        f.write(content)
    print("Patched successfully")
else:
    print("Header pattern not found. Need to check the exact string.")

