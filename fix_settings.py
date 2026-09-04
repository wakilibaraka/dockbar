import sys

file_path = "Sources/DeskBar/Views/SettingsView.swift"
with open(file_path, "r") as f:
    content = f.read()

# 1. Properties
props = """
    private let clockThemePopupButton = NSPopUpButton()
    private let showClockEventsCheckbox = NSButton(checkboxWithTitle: "Show next event in clock", target: nil, action: nil)
    private let showQuickSettingsCheckbox = NSButton(checkboxWithTitle: "Show Quick Settings button", target: nil, action: nil)
    private let useAppIconAsLauncherButtonCheckbox = NSButton(checkboxWithTitle: "Use app icon as launcher button", target: nil, action: nil)
"""
content = content.replace("private let clockTargetAppTextField = NSTextField()", "private let clockTargetAppTextField = NSTextField()\n" + props)

# 2. configureLayout - clock theme options
content = content.replace("widgetsTab.view = makeFormView(rows: [", "clockThemePopupButton.addItems(withTitles: ClockTheme.allCases.map { $0.displayName })\n        widgetsTab.view = makeFormView(rows: [")

# 3. configureLayout - widgetsTab rows
widgets_old = """        widgetsTab.view = makeFormView(rows: [
            makeCheckboxRow(showClockCheckbox),
            makeLabeledControlRow(label: "Clock click app", control: clockTargetAppTextField),
"""
widgets_new = """        widgetsTab.view = makeFormView(rows: [
            makeCheckboxRow(showClockCheckbox),
            makeLabeledControlRow(label: "Clock theme", control: clockThemePopupButton),
            makeCheckboxRow(showClockEventsCheckbox),
            makeLabeledControlRow(label: "Clock click app", control: clockTargetAppTextField),
            makeCheckboxRow(showQuickSettingsCheckbox),
"""
content = content.replace(widgets_old, widgets_new)

# 4. configureLayout - appearanceTab rows
appearance_old = """            makeLabeledControlRow(label: "DeskBar layout", control: layoutModePopupButton),"""
appearance_new = """            makeLabeledControlRow(label: "DeskBar layout", control: layoutModePopupButton),
            makeCheckboxRow(useAppIconAsLauncherButtonCheckbox),"""
content = content.replace(appearance_old, appearance_new)

# 5. configureActions
actions_new = """
        clockThemePopupButton.target = self
        clockThemePopupButton.action = #selector(clockThemeChanged(_:))
        showClockEventsCheckbox.target = self
        showClockEventsCheckbox.action = #selector(showClockEventsChanged(_:))
        showQuickSettingsCheckbox.target = self
        showQuickSettingsCheckbox.action = #selector(showQuickSettingsChanged(_:))
        useAppIconAsLauncherButtonCheckbox.target = self
        useAppIconAsLauncherButtonCheckbox.action = #selector(useAppIconAsLauncherButtonChanged(_:))
"""
content = content.replace("showClockCheckbox.action = #selector(showClockChanged(_:))", "showClockCheckbox.action = #selector(showClockChanged(_:))" + actions_new)

# 6. bindSettings
bind_new = """
        settings.$clockTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self else { return }
                if let idx = ClockTheme.allCases.firstIndex(of: theme) {
                    self.clockThemePopupButton.selectItem(at: idx)
                }
            }
            .store(in: &cancellables)
        
        settings.$showClockEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.showClockEventsCheckbox.state = value ? .on : .off
            }
            .store(in: &cancellables)
        
        settings.$showQuickSettings
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.showQuickSettingsCheckbox.state = value ? .on : .off
            }
            .store(in: &cancellables)
        
        settings.$useAppIconAsLauncherButton
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.useAppIconAsLauncherButtonCheckbox.state = value ? .on : .off
            }
            .store(in: &cancellables)
"""
content = content.replace("settings.$showClock", bind_new + "\n        settings.$showClock")

# 7. Actions methods
methods_new = """
    @objc private func clockThemeChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        let cases = ClockTheme.allCases
        if idx >= 0 && idx < cases.count {
            settings.clockTheme = cases[idx]
        }
    }
    
    @objc private func showClockEventsChanged(_ sender: NSButton) {
        settings.showClockEvents = sender.state == .on
    }
    
    @objc private func showQuickSettingsChanged(_ sender: NSButton) {
        settings.showQuickSettings = sender.state == .on
    }
    
    @objc private func useAppIconAsLauncherButtonChanged(_ sender: NSButton) {
        settings.useAppIconAsLauncherButton = sender.state == .on
    }
"""
content = content.replace("@objc private func showClockChanged(_ sender: NSButton) {", methods_new + "\n    @objc private func showClockChanged(_ sender: NSButton) {")

with open(file_path, "w") as f:
    f.write(content)
