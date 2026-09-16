import re

with open('Sources/DeskBar/Views/SettingsView.swift', 'r') as f:
    content = f.read()

# Remove the display options list
content = re.sub(r"\s*private var sessionManagerWidgetDisplayOptions: \[CGDirectDisplayID\?\] = \[\]", "", content)

# Remove the makeLabeledControlRow
content = re.sub(r"\s*makeLabeledControlRow\(label: \"SM widget show on\", control: sessionManagerWidgetDisplayPopupButton\)", "", content)

# Remove the configure function
content = re.sub(r"\s*private func configureSessionManagerWidgetDisplayPopupButton\(\) \{.*?\n    \}", "", content, flags=re.DOTALL)

# Remove the updateSessionManagerWidgetDisplaySelection function call
content = re.sub(r"\s*updateSessionManagerWidgetDisplaySelection\(\)", "", content)

# Remove the updateSessionManagerWidgetDisplaySelection function definition
content = re.sub(r"\s*private func updateSessionManagerWidgetDisplaySelection\(\) \{.*?\n    \}", "", content, flags=re.DOTALL)

# Remove the sessionManagerWidgetDisplayChanged function
content = re.sub(r"\s*@objc private func sessionManagerWidgetDisplayChanged\(_ sender: NSPopUpButton\) \{.*?\n    \}", "", content, flags=re.DOTALL)

# Remove the binding for sessionManagerWidgetPinnedDisplayID
content = re.sub(r"\s*settings\.\$sessionManagerWidgetPinnedDisplayID\n\s*\.receive\(on: RunLoop\.main\)\n\s*\.sink \{ \[weak self\] _ in\n\s*self\?\.updateSessionManagerWidgetDisplaySelection\(\)\n\s*\}\n\s*\.store\(in: &cancellables\)", "", content)

with open('Sources/DeskBar/Views/SettingsView.swift', 'w') as f:
    f.write(content)

