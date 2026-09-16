import re

with open('Sources/DeskBar/Views/SettingsView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*private func updateSessionManagerWidgetDisplayPopupSelection\(\) \{.*?\n    \}", "", content, flags=re.DOTALL)
content = re.sub(r"\s*@objc\n\s*private func sessionManagerWidgetDisplayChanged\(_ sender: NSPopUpButton\) \{.*?\n    \}", "", content, flags=re.DOTALL)

with open('Sources/DeskBar/Views/SettingsView.swift', 'w') as f:
    f.write(content)
