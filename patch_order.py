import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

# Change the order
old_order = """        zonesStackView.addArrangedSubview(launcherZoneView)
        zonesStackView.addArrangedSubview(taskZoneContainer)
        zonesStackView.addArrangedSubview(systemResourceWidgetView)
        // zonesStackView.addArrangedSubview(runningAppTrayView)

        // Vertical divider between running apps and system tray
        let trayDivider = NSView()
        trayDivider.wantsLayer = true
        trayDivider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        trayDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trayDivider.widthAnchor.constraint(equalToConstant: 1),
            trayDivider.heightAnchor.constraint(equalToConstant: 20)
        ])
        zonesStackView.addArrangedSubview(trayDivider)
        zonesStackView.addArrangedSubview(connectivityTrayView)"""

new_order = """        zonesStackView.addArrangedSubview(launcherZoneView)
        zonesStackView.addArrangedSubview(taskZoneContainer)
        
        zonesStackView.addArrangedSubview(connectivityTrayView)

        // Vertical divider
        let trayDivider = NSView()
        trayDivider.wantsLayer = true
        trayDivider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        trayDivider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trayDivider.widthAnchor.constraint(equalToConstant: 1),
            trayDivider.heightAnchor.constraint(equalToConstant: 20)
        ])
        zonesStackView.addArrangedSubview(trayDivider)
        
        zonesStackView.addArrangedSubview(systemResourceWidgetView)"""

content = content.replace(old_order, new_order)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)

