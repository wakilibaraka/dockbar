import re

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'r') as f:
    content = f.read()

# Replace mouseDown with the old implementation
new_mouse_down = """    private lazy var flyoutPanel: SystemResourceFlyoutPanel = {
        SystemResourceFlyoutPanel(monitor: monitor, smPluginService: smPluginService)
    }()

    override func mouseDown(with event: NSEvent) {
        if flyoutPanel.isVisible {
            flyoutPanel.close()
            return
        }
        
        guard let window = self.window else { return }
        let screenRect = window.convertToScreen(self.convert(self.bounds, to: nil))
        let panelSize = flyoutPanel.frame.size
        
        let margin: CGFloat = 8
        let originX = max(8, screenRect.midX - (panelSize.width / 2))
        let originY = screenRect.maxY + margin
        
        flyoutPanel.setFrameOrigin(NSPoint(x: originX, y: originY))
        flyoutPanel.makeKeyAndOrderFront(nil)
    }"""

content = re.sub(r"\s*override func mouseDown\(with event: NSEvent\) \{.*?(?=\n    override func mouseEntered|\n    override func rightMouseDown)", "\n" + new_mouse_down + "\n", content, flags=re.DOTALL)

# Also remove popover property
content = re.sub(r"\s*private var popover: NSPopover\?", "", content)

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'w') as f:
    f.write(content)

