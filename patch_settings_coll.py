import re

with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*@Published var systemResourceWidgetCollapsed: Bool \{\n\s*didSet \{ defaults\.set\(systemResourceWidgetCollapsed, forKey: \"systemResourceWidgetCollapsed\"\) \}\n\s*\}", "", content)
content = re.sub(r"\s*systemResourceWidgetCollapsed = defaults\.object\(forKey: \"systemResourceWidgetCollapsed\"\) as\? Bool \?\? false", "", content)

with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'w') as f:
    f.write(content)

with open('Tests/DeskBarTests/TaskbarSettingsTests.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*#expect\(settings\.systemResourceWidgetCollapsed == false\)", "", content)
content = re.sub(r"\s*settings\.systemResourceWidgetCollapsed = true", "", content)
content = re.sub(r"\s*#expect\(settings\.systemResourceWidgetCollapsed\)", "", content)

with open('Tests/DeskBarTests/TaskbarSettingsTests.swift', 'w') as f:
    f.write(content)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*settings\.\$systemResourceWidgetCollapsed\n\s*\.receive\(on: RunLoop\.main\)\n\s*\.sink \{ \[weak self\] _ in\n\s*self\?\.schedulePreferredWidthNotification\(\)\n\s*\}\n\s*\.store\(in: &cancellables\)", "", content)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)

