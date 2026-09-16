import re

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'r') as f:
    content = f.read()

# Increase preferred width
content = content.replace("return isHidden ? 0 : 56", "return isHidden ? 0 : 72")

# Update setupUI
setupUI_old = """    private func setupUI() {
        wantsLayer = true
        
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 6
        containerView.layer?.cornerCurve = .continuous
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        textLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .bold)
        textLabel.alignment = .center
        textLabel.isBordered = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.drawsBackground = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 44),
            containerView.heightAnchor.constraint(equalToConstant: 22),
            
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
    }"""

setupUI_new = """    private let iconView = NSImageView()

    private func setupUI() {
        wantsLayer = true
        
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 6
        containerView.layer?.cornerCurve = .continuous
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        let config = NSImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        iconView.image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: nil)?.withSymbolConfiguration(config)
        iconView.contentTintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)
        
        textLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .bold)
        textLabel.alignment = .center
        textLabel.isBordered = false
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.drawsBackground = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 60),
            containerView.heightAnchor.constraint(equalToConstant: 22),
            
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            
            textLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            textLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6)
        ])
    }"""

content = content.replace(setupUI_old, setupUI_new)

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'w') as f:
    f.write(content)

