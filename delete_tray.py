import re
with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*private let runningAppTrayView: RunningAppTrayView", "", content)
content = re.sub(r"\s*runningAppTrayView = RunningAppTrayView\(\n\s*settings: settings,\n\s*monitor: systemResourceMonitor,\n\s*displayID: displayID\n\s*\)", "", content)

content = re.sub(r"\s*runningAppTrayView\.preferredWidthDidChange = \{ \[weak self\] in\n\s*self\?\.schedulePreferredWidthNotification\(\)\n\s*\}", "", content)
content = re.sub(r"\s*runningAppTrayView\.requestCollapseSystemResourceWidget = \{ \[weak self\] in\n\s*self\?\.settings\.systemResourceWidgetCollapsed = true\n\s*\}", "", content)
content = re.sub(r"\s*runningAppTrayView\.requestExpandSystemResourceWidget = \{ \[weak self\] in\n\s*self\?\.settings\.systemResourceWidgetCollapsed = false\n\s*\}", "", content)

# It was commented out here: // zonesStackView.addArrangedSubview(runningAppTrayView)
content = re.sub(r"\s*// zonesStackView\.addArrangedSubview\(runningAppTrayView\)", "", content)

# Remove from occupiedViews
content = content.replace("            runningAppTrayView,\n", "")

# Remove from availableTaskZoneContentWidth
# it's not in the math anymore.

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)
