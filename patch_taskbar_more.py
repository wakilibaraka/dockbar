import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = content.replace("            (sessionManagerWidgetView?.preferredContentWidth() ?? 0) +\n", "")

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)

