import re

with open('Sources/DeskBar/Views/Settings/BlacklistSettingsTab.swift', 'r') as f:
    content = f.read()
content = content.replace("@Published var state.newBundleID = \"\"", "@Published var newBundleID = \"\"")
with open('Sources/DeskBar/Views/Settings/BlacklistSettingsTab.swift', 'w') as f:
    f.write(content)

with open('Sources/DeskBar/Views/Settings/LauncherSettingsTab.swift', 'r') as f:
    content = f.read()
content = content.replace("@Published var state.isShowingFilePicker = false", "@Published var isShowingFilePicker = false")
with open('Sources/DeskBar/Views/Settings/LauncherSettingsTab.swift', 'w') as f:
    f.write(content)

with open('Sources/DeskBar/Views/Onboarding/OnboardingView.swift', 'r') as f:
    content = f.read()
content = content.replace("@Published var state.step = 0", "@Published var step = 0")
with open('Sources/DeskBar/Views/Onboarding/OnboardingView.swift', 'w') as f:
    f.write(content)
