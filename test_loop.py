with open("Sources/DeskBar/Views/TaskbarContentView.swift", "r") as f:
    content = f.read()

content = content.replace(
    "    override func layout() {\n        super.layout()\n        let contentWidth = availableContentWidth",
    "    override func layout() {\n        super.layout()\n        print(\"TaskbarContentView layout called bounds=\\(bounds.width)\")\n        let contentWidth = availableContentWidth"
)

with open("Sources/DeskBar/Views/TaskbarContentView.swift", "w") as f:
    f.write(content)
