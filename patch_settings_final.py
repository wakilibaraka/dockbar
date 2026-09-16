import re

with open('Sources/DeskBar/Views/SettingsView.swift', 'r') as f:
    content = f.read()

# Remove configureSessionManagerWidgetDisplayPopupButton call
content = re.sub(r"\s*configureSessionManagerWidgetDisplayPopupButton\(\)", "", content)

# Remove bindings in updateBindings()
content = re.sub(r"\s*settings\.\$showSessionManagerWidget\n.*?\n\s*\.store\(in: &cancellables\)", "", content, flags=re.DOTALL)
content = re.sub(r"\s*settings\.\$sessionManagerWidgetPinnedDisplayID\n.*?\n\s*\.store\(in: &cancellables\)", "", content, flags=re.DOTALL)

# Remove updateSessionManagerWidgetDisplaySelection call
content = re.sub(r"\s*updateSessionManagerWidgetDisplaySelection\(\)", "", content)

# Look for updateWidgetControlsState method
content = re.sub(r"\s*let isSMWidgetEnabled = settings\.enableSessionManagerPlugin\n\s*sessionManagerWidgetDisplayPopupButton\.isEnabled = isSMWidgetEnabled", "", content)

# Look for any remaining references to sessionManagerWidgetDisplayOptions
content = re.sub(r"\s*if let selectedIndex = sessionManagerWidgetDisplayOptions\.firstIndex.*?\} \?\? 0", "", content, flags=re.DOTALL)
content = re.sub(r"\s*sessionManagerWidgetDisplayPopupButton\.selectItem\(at: selectedIndex\)", "", content)

with open('Sources/DeskBar/Views/SettingsView.swift', 'w') as f:
    f.write(content)

