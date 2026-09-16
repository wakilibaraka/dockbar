import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*runningAppTrayView = RunningAppTrayView\(.*?\n\s*\)", "", content, flags=re.DOTALL)
content = re.sub(r"\s*runningAppTrayView\.preferredWidthDidChange = \{ \[weak self\] in\n\s*self\?\.schedulePreferredWidthNotification\(\)\n\s*self\?\.applyResponsiveWidthCapsNowOrSchedule\(\)\n\s*\}", "", content)
content = re.sub(r"\s*runningAppTrayView\.updateTrayContent\(.*?\)", "", content)

# Remove any other occurrences of runningAppTrayView
lines = content.split('\n')
lines = [line for line in lines if "runningAppTrayView" not in line]

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write('\n'.join(lines))
