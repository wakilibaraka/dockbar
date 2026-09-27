import re
with open("Sources/DeskBar/Views/LauncherZoneView.swift", "r") as f:
    content = f.read()

ax = """
    override func accessibilityLabel() -> String? { return "LauncherZone" }
    override func accessibilityRole() -> NSAccessibility.Role? { return .button }
"""
content = re.sub(r'\}\s*$', ax + '}\n', content)
with open("Sources/DeskBar/Views/LauncherZoneView.swift", "w") as f:
    f.write(content)
