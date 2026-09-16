import re

with open('Sources/DeskBar/Views/SettingsView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*@objc\n\s*private func showSessionManagerWidgetChanged\(_ sender: NSButton\) \{\n\s*settings\.showSessionManagerWidget = sender\.state == \.on\n\s*\}", "", content)

with open('Sources/DeskBar/Views/SettingsView.swift', 'w') as f:
    f.write(content)
