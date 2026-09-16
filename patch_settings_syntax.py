import re

with open('Sources/DeskBar/Views/SettingsView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*self\?\.\s*self\?\.updateSessionManagerWidgetDisplayPopupSelection\(\)", "", content)

with open('Sources/DeskBar/Views/SettingsView.swift', 'w') as f:
    f.write(content)

