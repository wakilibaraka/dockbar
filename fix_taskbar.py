import sys

file_path = "Sources/DeskBar/Views/TaskbarContentView.swift"
with open(file_path, "r") as f:
    content = f.read()

# 1. Properties
content = content.replace("private let clockWidgetView: ClockWidgetView", 
"""private let clockWidgetView: EnhancedClockWidgetView
    private let quickSettingsButtonView: QuickSettingsButtonView
    private let calendarEventService = CalendarEventService()""")

# 2. Init
content = content.replace("clockWidgetView = ClockWidgetView(settings: settings)",
"""clockWidgetView = EnhancedClockWidgetView(settings: settings, calendarService: calendarEventService)
        quickSettingsButtonView = QuickSettingsButtonView(settings: settings, manager: QuickSettingsManager.shared)""")

# 3. Layout constraints
content = content.replace("rootStackView.addArrangedSubview(bannerButton)", "addSubview(bannerButton)")
content = content.replace("bannerButton.leadingAnchor.constraint(equalTo: rootStackView.leadingAnchor)", "bannerButton.leadingAnchor.constraint(equalTo: leadingAnchor)")
content = content.replace("bannerButton.trailingAnchor.constraint(equalTo: rootStackView.trailingAnchor)", "bannerButton.trailingAnchor.constraint(equalTo: trailingAnchor),\n            bannerButton.bottomAnchor.constraint(equalTo: bottomAnchor)")

# 4. Add to zonesStackView
content = content.replace("zonesStackView.addArrangedSubview(clockWidgetView)",
"""zonesStackView.addArrangedSubview(quickSettingsButtonView)
        zonesStackView.addArrangedSubview(clockWidgetView)""")

# 5. bindState
bind_state_str = "private func bindState() {"
content = content.replace(bind_state_str, bind_state_str + """
        permissionsManager.$isAccessibilityGranted
            .receive(on: RunLoop.main)
            .sink { [weak self] granted in
                self?.bannerButton.isHidden = granted
            }
            .store(in: &cancellables)
""")

# 6. rebuildTaskZone
content = content.replace("bannerButton.isHidden = permissionsManager.isAccessibilityGranted", "")

# 7. Widths
content = content.replace("runningAppTrayView.preferredContentWidth() +", "(settings.showQuickSettings ? 36 : 0) + (settings.showClock ? 60 : 0) + runningAppTrayView.preferredContentWidth() +")
content = content.replace("runningAppTrayView.minimumOverflowContentWidth() +", "(settings.showQuickSettings ? 36 : 0) + (settings.showClock ? 60 : 0) + runningAppTrayView.minimumOverflowContentWidth() +")
content = content.replace("runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) +", "(settings.showQuickSettings ? 36 : 0) + (settings.showClock ? 60 : 0) + runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) +")

with open(file_path, "w") as f:
    f.write(content)
