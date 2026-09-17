import re

with open('Sources/DeskBar/Views/BatteryFlyoutView.swift', 'r') as f:
    content = f.read()

# Replace Recently Closed apps logic to always render something, and wrap context menu
old_bottom = """            // Recently Closed Apps
            if !recentlyClosed.closedApps.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recently Closed")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentlyClosed.closedApps, id: \\.bundleIdentifier) { app in
                                Button(action: {
                                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                                        recentlyClosed.remove(bundleIdentifier: app.bundleIdentifier)
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        if let icon = app.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                        } else {
                                            Color.gray.opacity(0.3).frame(width: 32, height: 32).cornerRadius(8)
                                        }
                                        Text(app.localizedName)
                                            .font(.system(size: 10))
                                            .lineLimit(1)
                                            .frame(width: 50)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            
            // Context Menu Actions
            VStack(spacing: 4) {
                ContextMenuButton(
                    title: "Restore Windows From Last Sleep",
                    icon: "uiwindow.split.2x1",
                    action: { NSApp.sendAction(Selector(("restoreWindowsFromLastSleep:")), to: nil, from: nil) }
                )
                
                ContextMenuButton(
                    title: "Settings...",
                    icon: "gearshape.fill",
                    action: { NSApp.sendAction(Selector(("openSettings:")), to: nil, from: nil) }
                )
                
                ContextMenuButton(
                    title: "Quit DeskBar",
                    icon: "power",
                    action: { NSApp.terminate(nil) },
                    isDestructive: true
                )
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)"""

new_bottom = """            // Recently Closed Apps (Always render to maintain structure)
            VStack(alignment: .leading, spacing: 10) {
                Text("Recently Closed")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                if recentlyClosed.closedApps.isEmpty {
                    Text("No recently closed apps")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentlyClosed.closedApps, id: \\.bundleIdentifier) { app in
                                Button(action: {
                                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                                        recentlyClosed.remove(bundleIdentifier: app.bundleIdentifier)
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        if let icon = app.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                        } else {
                                            Color.gray.opacity(0.3).frame(width: 32, height: 32).cornerRadius(8)
                                        }
                                        Text(app.localizedName)
                                            .font(.system(size: 10))
                                            .lineLimit(1)
                                            .frame(width: 50)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(12)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            
            // Context Menu Actions in a Unified Card
            VStack(spacing: 2) {
                ContextMenuButton(
                    title: "Restore Windows From Last Sleep",
                    icon: "uiwindow.split.2x1",
                    action: { NSApp.sendAction(Selector(("restoreWindowsFromLastSleep:")), to: nil, from: nil) }
                )
                Divider().opacity(0.4).padding(.horizontal, 8)
                ContextMenuButton(
                    title: "Settings...",
                    icon: "gearshape.fill",
                    action: { NSApp.sendAction(Selector(("openSettings:")), to: nil, from: nil) }
                )
                Divider().opacity(0.4).padding(.horizontal, 8)
                ContextMenuButton(
                    title: "Quit DeskBar",
                    icon: "power",
                    action: { NSApp.terminate(nil) },
                    isDestructive: true
                )
            }
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(12)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)"""

if old_bottom in content:
    content = content.replace(old_bottom, new_bottom)
    with open('Sources/DeskBar/Views/BatteryFlyoutView.swift', 'w') as f:
        f.write(content)
    print("Patched bottom successfully")
else:
    print("Bottom pattern not found. Need to check the exact string.")
