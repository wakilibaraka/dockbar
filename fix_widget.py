import re

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'r') as f:
    content = f.read()

# Revert setupUI to remove the icon
setupUI_with_icon = """    private let iconView = NSImageView()

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

setupUI_original = """    private func setupUI() {
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

content = content.replace(setupUI_with_icon, setupUI_original)
content = content.replace("return isHidden ? 0 : 72", "return isHidden ? 0 : 56")

# Remove systemResourceWidgetCollapsed completely!
content = re.sub(r"\s*\.combineLatest\(settings\.\$systemResourceWidgetCollapsed\)", "", content)
content = re.sub(r"\s*\.sink \{ \[weak self\] _, _ in", "\n            .sink { [weak self] _ in", content)
content = content.replace("settings.showSystemResourceWidget && !settings.systemResourceWidgetCollapsed", "settings.showSystemResourceWidget")

with open('Sources/DeskBar/Views/SystemResourceWidgetView.swift', 'w') as f:
    f.write(content)

