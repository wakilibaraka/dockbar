import re

with open('Sources/DeskBar/Views/SystemResourceFlyoutPanel.swift', 'r') as f:
    content = f.read()

content = content.replace("private let monitor: SystemResourceMonitor", "private let monitor: SystemResourceMonitor\n    private let smPluginService: SMPluginService?")
content = content.replace("init(monitor: SystemResourceMonitor) {", "init(monitor: SystemResourceMonitor, smPluginService: SMPluginService? = nil) {\n        self.smPluginService = smPluginService")
content = content.replace("SystemResourceDashboardView(monitor: monitor)", "SystemResourceDashboardView(monitor: monitor, smPluginService: smPluginService)")

# Let's make sure it has an arrow if it needs one? The user didn't ask for an arrow, just "render so that above the dock bar and not over it".
# A standard NSPanel doesn't have an arrow.

with open('Sources/DeskBar/Views/SystemResourceFlyoutPanel.swift', 'w') as f:
    f.write(content)

