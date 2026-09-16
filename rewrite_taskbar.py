import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    lines = f.readlines()

new_lines = []
skip = False
for i, line in enumerate(lines):
    if "private let runningAppTrayView: RunningAppTrayView" in line:
        continue
    if "runningAppTrayView = RunningAppTrayView(" in line:
        skip = True
        continue
    if skip:
        if ")" in line and "displayID: displayID" in line:
            skip = False
            continue
        elif "displayID: displayID" in line or "settings: settings" in line or "appGroupManager: appGroupManager" in line or "windowManager: windowManager" in line:
            continue
    if "runningAppTrayView.preferredWidthDidChange" in line:
        skip = True
        continue
    if skip and "}" in line:
        skip = False
        continue
    if "runningAppTrayView.refresh()" in line:
        continue
    if "zonesStackView.addArrangedSubview(runningAppTrayView)" in line:
        continue
    if "runningAppTrayView," in line:
        continue
    if "runningAppTrayView.preferredContentWidth() +" in line:
        line = line.replace("runningAppTrayView.preferredContentWidth() + ", "")
    
    # modify applyResponsiveWidthCaps math
    if "runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) + 1 +" in line:
        line = line.replace("runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) + 1 +", "1 +")
    
    if "runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) +" in line:
        line = line.replace("runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) +", "")

    if "runningAppTrayView.minimumOverflowContentWidth() + 1 +" in line:
        line = line.replace("runningAppTrayView.minimumOverflowContentWidth() + 1 +", "1 +")
        
    if "let trayVisibleApplicationCapacity: Int?" in line:
        continue
    if "trayVisibleApplicationCapacity = runningAppTrayView.visibleApplicationCapacity(" in line:
        skip = True
        continue
    if skip and "fitting: availableTrayWidth" in line:
        continue
    if skip and ")" in line:
        skip = False
        continue
    
    if "effectiveFixedZoneWidth =" in line and "nonTrayFixedWidth +" in lines[i+1]:
        skip = True
        continue
    if skip and "runningAppTrayView.plannedContentWidth(" in line:
        continue
    if skip and "visibleApplicationCapacity: trayVisibleApplicationCapacity" in line:
        continue
    if skip and "effectiveFixedZoneWidth =" in line and "launcherZoneView" in lines[i+1]:
        skip = False
        # this is the `else` block
        pass
    
    if "let availableTrayWidth = layoutBudgetContentWidth - nonTrayFixedWidth - taskMinimumWidth" in line:
        new_lines.append("            effectiveFixedZoneWidth = nonTrayFixedWidth\n")
        continue

    if "trayVisibleApplicationCapacity = nil" in line:
        continue
    
    if "lastAppliedTrayVisibleApplicationCapacity != trayVisibleApplicationCapacity ||" in line:
        continue
        
    if "lastAppliedTrayVisibleApplicationCapacity = trayVisibleApplicationCapacity" in line:
        continue
        
    if "runningAppTrayView.setVisibleApplicationCapacity(" in line:
        skip = True
        continue
    if skip and "trayVisibleApplicationCapacity," in line:
        continue
    if skip and "notifiesPreferredWidthChange: false" in line:
        continue
        
    if "private var lastAppliedTrayVisibleApplicationCapacity: Int? = nil" in line:
        continue

    new_lines.append(line)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.writelines(new_lines)
