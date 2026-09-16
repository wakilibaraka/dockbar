import re

# Fix TaskbarSettings.swift
with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*if let pinnedDisplayID = defaults\.object\(forKey: \"sessionManagerWidgetPinnedDisplayID\"\) as\? NSNumber \{\n\s*sessionManagerWidgetPinnedDisplayID = CGDirectDisplayID\(pinnedDisplayID\.uint32Value\)\n\s*\} else \{\n\s*sessionManagerWidgetPinnedDisplayID = nil\n\s*\}", "", content)

with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'w') as f:
    f.write(content)


# Fix SettingsView.swift
with open('Sources/DeskBar/Views/SettingsView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*if let pinnedDisplayID = settings\.sessionManagerWidgetPinnedDisplayID.*?\}\n\s*\}", "", content, flags=re.DOTALL)
content = re.sub(r"\s*let isSMWidgetEnabled = settings\.enableSessionManagerPlugin.*?sessionManagerWidgetDisplayPopupButton\.isEnabled = isSMWidgetEnabled", "", content, flags=re.DOTALL)
content = re.sub(r"\s*if !settings\.showSessionManagerWidget \{.*?\}", "", content, flags=re.DOTALL)

with open('Sources/DeskBar/Views/SettingsView.swift', 'w') as f:
    f.write(content)

