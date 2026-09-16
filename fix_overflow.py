import re

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'r') as f:
    content = f.read()

old_logic = """        guard let window = self.window else { return }
        let screenRect = window.convertToScreen(self.convert(self.bounds, to: nil))
        let panelSize = flyoutPanel.frame.size
        
        let margin: CGFloat = 8
        let originX = max(8, screenRect.midX - (panelSize.width / 2))
        let originY = screenRect.maxY + margin
        
        flyoutPanel.setFrameOrigin(NSPoint(x: originX, y: originY))"""

new_logic = """        guard let window = self.window, let screen = window.screen else { return }
        let screenRect = window.convertToScreen(self.convert(self.bounds, to: nil))
        let panelSize = flyoutPanel.frame.size
        
        let margin: CGFloat = 8
        
        var originX = screenRect.midX - (panelSize.width / 2)
        let maxAllowedX = screen.frame.maxX - margin
        
        if originX + panelSize.width > maxAllowedX {
            originX = maxAllowedX - panelSize.width
        }
        originX = max(screen.frame.minX + margin, originX)
        
        let originY = screenRect.maxY + margin
        
        flyoutPanel.setFrameOrigin(NSPoint(x: originX, y: originY))"""

content = content.replace(old_logic, new_logic)

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'w') as f:
    f.write(content)

