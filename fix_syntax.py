import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*trayVisibleApplicationCapacity,\n\s*notifiesPreferredWidthChange: false\n\s*\)", "", content)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)

