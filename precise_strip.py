with open("Sources/DeskBar/Views/TaskbarContentView.swift", "r") as f:
    lines = f.readlines()

out = []
i = 0
while i < len(lines):
    l = lines[i]
    
    if "smPluginService?.$agentTabs" in l or "smPluginService?.$terminalTabCountByWindowID" in l or "smPluginService?.$watchWindows" in l:
        i += 4
        continue
        
    if "let smPluginService," in l:
        # Skip down to "return windows"
        while i < len(lines) and "return windows" not in lines[i]:
            i += 1
        # skip the line with return windows
        i += 1
        # skip the closing brace
        i += 1
        out.append("        let desiredWindows = windows\n")
        continue

    if "guard let smPluginService else {" in l:
        if "return 0" in lines[i+1]:
            # This is agentTabCount
            while i < len(lines) and "}.count" not in lines[i]:
                i += 1
            i += 1
            out.append("        let agentTabCount = 0\n")
            continue
            
    if "guard let terminalTabCount = smPluginService" in l:
        i += 3
        out.append("        let terminalTabCount = 0\n")
        continue
        
    if "let agentAnnotationProvider:" in l:
        while i < len(lines) and "pluginMenuConfigurationProvider = nil" not in lines[i]:
            i += 1
        i += 2
        continue
        
    if "pluginMenuConfiguration: smPluginMenuConfiguration(for: window)" in l:
        i += 1; continue
    if "agentAnnotation: agentAnnotationProvider?(window)" in l:
        i += 1; continue
    if "pluginMenuConfiguration: pluginMenuConfigurationProvider?(window)" in l:
        i += 1; continue
        
    if "showsPluginActionButton: smPluginMenuConfiguration" in l:
        out.append("                showsPluginActionButton: false,\n")
        i += 1
        continue
        
    if "private func smAnnotation(for window:" in l:
        while i < len(lines) and "private func smPluginMenuConfiguration" not in lines[i]:
            i += 1
        continue
        
    if "private func smPluginMenuConfiguration" in l:
        while i < len(lines) and "private func makeSMWatchMenu" not in lines[i]:
            i += 1
        continue

    if "private func makeSMWatchMenu" in l:
        while i < len(lines) and "private func refreshSMPlugin" not in lines[i]:
            i += 1
        continue
        
    if "private func refreshSMPlugin" in l:
        while i < len(lines) and "func taskButtonView" not in lines[i]:
            i += 1
        continue
        
    if "func taskButtonView(_ view: TaskButtonView, makePluginMenuFor annotation:" in l:
        while i < len(lines) and "private func handleSMPluginMenuCommand" not in lines[i]:
            i += 1
        continue
        
    if "private func handleSMPluginMenuCommand" in l:
        while i < len(lines) and "private func startApp(_ url:" not in lines[i]:
            i += 1
        continue
        
    if "if window.bundleIdentifier == SMPluginService.terminalBundleIdentifier," in l:
        if "settings.enableSessionManagerPlugin" in lines[i+1]:
            while i < len(lines) and "menu.addItem(newWatchItem)" not in lines[i]:
                i += 1
            i += 2
            continue
            
    if "@objc\n" == l and "private func openWatchWindow" in lines[i+1]:
        i += 8
        continue
        
    if "if let annotation = view.model.agentAnnotation {" in l:
        i += 3
        continue
        
    if "agentAnnotation: smPluginService?.agentTabs" in l:
        i += 1; continue
        
    out.append(l)
    i += 1

with open("Sources/DeskBar/Views/TaskbarContentView.swift", "w") as f:
    f.writelines(out)
