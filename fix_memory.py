import re

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'r') as f:
    content = f.read()

content = content.replace("monitor.snapshot.memoryUsed ?? 0", "monitor.snapshot.memoryUsedBytes ?? 0")
content = content.replace("monitor.snapshot.memoryUsedPercent", "monitor.snapshot.memoryPressurePercent")

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'w') as f:
    f.write(content)
