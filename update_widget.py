import re

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'r') as f:
    content = f.read()

# Add smPluginService property
content = content.replace("    private let monitor: SystemResourceMonitor", "    private let monitor: SystemResourceMonitor\n    private let smPluginService: SMPluginService?")

# Update init
content = content.replace(
    "init(settings: TaskbarSettings, monitor: SystemResourceMonitor, displayID: CGDirectDisplayID? = nil, isCollapsedInstance: Bool = false)",
    "init(settings: TaskbarSettings, monitor: SystemResourceMonitor, smPluginService: SMPluginService? = nil, displayID: CGDirectDisplayID? = nil, isCollapsedInstance: Bool = false)"
)

content = content.replace(
    "        self.monitor = monitor\n        self.isCollapsedInstance = isCollapsedInstance",
    "        self.monitor = monitor\n        self.smPluginService = smPluginService\n        self.isCollapsedInstance = isCollapsedInstance"
)

# Pass to SystemResourceDashboardView
content = content.replace(
    "let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor))",
    "let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor, smPluginService: smPluginService))"
)

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'w') as f:
    f.write(content)

