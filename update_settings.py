import re

with open('Sources/DeskBar/Views/SettingsView.swift', 'r') as f:
    content = f.read()

# Remove UI elements
content = re.sub(r"\s*private let showSessionManagerWidgetCheckbox = NSButton\(checkboxWithTitle: \"Show SM widget\", target: nil, action: nil\)", "", content)
content = re.sub(r"\s*private let sessionManagerWidgetDisplayPopupButton = NSPopUpButton\(\)", "", content)

# Remove from layout
content = re.sub(r"\s*makeCheckboxRow\(showSessionManagerWidgetCheckbox\),", "", content)

# Remove setup
content = re.sub(r"\s*sessionManagerWidgetDisplayPopupButton\.target = self", "", content)
content = re.sub(r"\s*sessionManagerWidgetDisplayPopupButton\.action = #selector\(sessionManagerWidgetDisplayChanged\(_:\)\)", "", content)

content = re.sub(r"\s*showSessionManagerWidgetCheckbox\.target = self", "", content)
content = re.sub(r"\s*showSessionManagerWidgetCheckbox\.action = #selector\(showSessionManagerWidgetChanged\(_:\)\)", "", content)

# Remove binding
content = re.sub(r"\s*settings\.\$showSessionManagerWidget\n\s*\.receive\(on: RunLoop\.main\)\n\s*\.sink \{ \[weak self\] value in\n\s*self\?\.showSessionManagerWidgetCheckbox\.state = value \? \.on : \.off\n\s*\}\n\s*\.store\(in: &cancellables\)", "", content)

# Remove enable state sync
content = content.replace("        let isSMWidgetEnabled = settings.enableSessionManagerPlugin && settings.showSessionManagerWidget\n", "        let isSMWidgetEnabled = settings.enableSessionManagerPlugin\n")
content = re.sub(r"\s*showSessionManagerWidgetCheckbox\.isEnabled = settings\.enableSessionManagerPlugin", "", content)
content = content.replace("        sessionManagerWidgetDisplayPopupButton.isEnabled = isSMWidgetEnabled\n", "")

# Remove actions
content = re.sub(r"\s*@objc private func showSessionManagerWidgetChanged\(_ sender: NSButton\) \{\n\s*settings\.showSessionManagerWidget = sender\.state == \.on\n\s*\}", "", content)

with open('Sources/DeskBar/Views/SettingsView.swift', 'w') as f:
    f.write(content)

