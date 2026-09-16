import sys

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = content.replace(
    "zonesStackView.addArrangedSubview(runningAppTrayView)",
    "// zonesStackView.addArrangedSubview(runningAppTrayView)"
)

content = content.replace(
    "runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil)",
    "0"
)

content = content.replace(
    "runningAppTrayView.minimumOverflowContentWidth()",
    "0"
)

content = content.replace(
    "trayVisibleApplicationCapacity = runningAppTrayView.visibleApplicationCapacity(\n                fitting: availableTrayWidth\n            )",
    "trayVisibleApplicationCapacity = 0"
)

content = content.replace(
    "runningAppTrayView.plannedContentWidth(\n                    visibleApplicationCapacity: trayVisibleApplicationCapacity\n                )",
    "0"
)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)

