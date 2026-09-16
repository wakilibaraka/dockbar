import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = re.sub(r"\s*let trayVisibleApplicationCapacity: Int\?", "", content)
content = re.sub(r"\s*trayVisibleApplicationCapacity = 0", "", content)
content = re.sub(r"\s*trayVisibleApplicationCapacity = nil", "", content)
content = re.sub(r"\s*lastAppliedTrayVisibleApplicationCapacity != trayVisibleApplicationCapacity \|\|", "", content)
content = re.sub(r"\s*lastAppliedTrayVisibleApplicationCapacity = trayVisibleApplicationCapacity", "", content)
content = re.sub(r"\s*private var lastAppliedTrayVisibleApplicationCapacity: Int\? = nil", "", content)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)

