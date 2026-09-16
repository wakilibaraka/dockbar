import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

# Remove sessionManagerWidgetView declaration
content = re.sub(r"\s*private let sessionManagerWidgetView: SessionManagerWidgetView\?", "", content)

# Remove sessionManagerWidgetView init block
sm_init_block = r"""        if let smPluginService \{
            sessionManagerWidgetView = SessionManagerWidgetView\(
                settings: settings,
                service: smPluginService,
                displayID: displayID
            \)
        \} else \{
            sessionManagerWidgetView = nil
        \}"""
content = re.sub(sm_init_block, "", content)

# Inject smPluginService into systemResourceWidgetView init
content = content.replace(
    "systemResourceWidgetView = SystemResourceWidgetView(\n            settings: settings,\n            monitor: systemResourceMonitor,\n            displayID: displayID\n        )",
    "systemResourceWidgetView = SystemResourceWidgetView(\n            settings: settings,\n            monitor: systemResourceMonitor,\n            smPluginService: smPluginService,\n            displayID: displayID\n        )"
)

# Remove sessionManagerWidgetView from occupiedViews
content = content.replace("            sessionManagerWidgetView,\n", "")

# Remove preferredWidthDidChange block
content = re.sub(r"\s*sessionManagerWidgetView\?\.preferredWidthDidChange = \{ \[weak self\] in\n\s*self\?\.schedulePreferredWidthNotification\(\)\n\s*self\?\.applyResponsiveWidthCapsNowOrSchedule\(\)\n\s*\}", "", content)

# Remove from zonesStackView
content = content.replace(
"""        if let sessionManagerWidgetView {
            zonesStackView.addArrangedSubview(sessionManagerWidgetView)
        }
""", "")

# Remove from nonTrayFixedWidth and effectiveFixedZoneWidth math
content = content.replace("                (sessionManagerWidgetView?.preferredContentWidth() ?? 0) +\n", "")

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)

