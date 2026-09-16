import sys

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = content.replace("            runningAppTrayView,\n", "            runningAppTrayView as NSView?,\n")

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)
