import re

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'r') as f:
    content = f.read()

content = content.replace('Text("Session Manager")', 'Text("Antigravity Activity")')

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'w') as f:
    f.write(content)

