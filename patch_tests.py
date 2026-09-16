import re

with open('Tests/DeskBarTests/TaskbarSettingsTests.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*#expect\(settings\.showSessionManagerWidget\)", "", content)
content = re.sub(r"\s*settings\.showSessionManagerWidget = false", "", content)
content = re.sub(r"\s*#expect\(settings\.showSessionManagerWidget == false\)", "", content)

content = re.sub(r"\s*#expect\(settings\.sessionManagerWidgetPinnedDisplayID == nil\)", "", content)
content = re.sub(r"\s*settings\.sessionManagerWidgetPinnedDisplayID = 123", "", content)
content = re.sub(r"\s*#expect\(settings\.sessionManagerWidgetPinnedDisplayID == 123\)", "", content)

with open('Tests/DeskBarTests/TaskbarSettingsTests.swift', 'w') as f:
    f.write(content)

