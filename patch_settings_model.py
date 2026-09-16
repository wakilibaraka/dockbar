import re

with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'r') as f:
    content = f.read()

# Remove the properties
content = re.sub(r"\s*@Published var showSessionManagerWidget: Bool \{\n\s*didSet \{ defaults\.set\(showSessionManagerWidget, forKey: \"showSessionManagerWidget\"\) \}\n\s*\}", "", content)

content = re.sub(r"\s*@Published var sessionManagerWidgetPinnedDisplayID: CGDirectDisplayID\? \{\n\s*didSet \{\n\s*if let sessionManagerWidgetPinnedDisplayID \{\n\s*defaults\.set\(Int\(sessionManagerWidgetPinnedDisplayID\), forKey: \"sessionManagerWidgetPinnedDisplayID\"\)\n\s*\} else \{\n\s*defaults\.removeObject\(forKey: \"sessionManagerWidgetPinnedDisplayID\"\)\n\s*\}\n\s*\}\n\s*\}", "", content)

# Remove the initializations
content = re.sub(r"\s*showSessionManagerWidget = defaults\.object\(forKey: \"showSessionManagerWidget\"\) as\? Bool \?\? true", "", content)

content = re.sub(r"\s*if defaults\.object\(forKey: \"sessionManagerWidgetPinnedDisplayID\"\) != nil \{\n\s*sessionManagerWidgetPinnedDisplayID = CGDirectDisplayID\(defaults\.integer\(forKey: \"sessionManagerWidgetPinnedDisplayID\"\)\)\n\s*\} else \{\n\s*sessionManagerWidgetPinnedDisplayID = nil\n\s*\}", "", content)

with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'w') as f:
    f.write(content)

