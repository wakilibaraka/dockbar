import sys, re

def modify_file():
    with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
        content = f.read()
        
    content = content.replace("    private let runningAppTrayView: RunningAppTrayView\n", "")
    
    content = re.sub(r"\s*runningAppTrayView = RunningAppTrayView\([^)]+\)\n", "", content)
    
    content = content.replace("        zonesStackView.addArrangedSubview(runningAppTrayView)\n", "")
    content = content.replace("            runningAppTrayView,\n", "")
    
    content = re.sub(r"\s*runningAppTrayView\.preferredWidthDidChange = \{\s*\[weak self\] in\n\s*self\?\.schedulePreferredWidthNotification\(\)\n\s*self\?\.applyResponsiveWidthCapsNowOrSchedule\(\)\n\s*\}\n", "", content)
    
    content = content.replace("        runningAppTrayView.refresh()\n", "")
    content = content.replace("            runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) +\n", "")
    content = content.replace("            runningAppTrayView.minimumOverflowContentWidth() + 1 +\n", "1 +\n")
    content = content.replace("            runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) + 1 +\n", "1 +\n")
    
    adaptive_block = """        if usesAdaptiveTaskLayout {
            let nonTrayFixedWidth =
                launcherZoneView.preferredContentWidth() +
                (sessionManagerWidgetView?.preferredContentWidth() ?? 0) +
                systemResourceWidgetView.preferredContentWidth() + connectivityTrayView.preferredContentWidth() +
                zoneEdgeInsetsWidth(compactZoneEdgeInsets) + 1
            let availableTrayWidth = layoutBudgetContentWidth - nonTrayFixedWidth - taskMinimumWidth
            trayVisibleApplicationCapacity = runningAppTrayView.visibleApplicationCapacity(
                fitting: availableTrayWidth
            )
            effectiveFixedZoneWidth =
                nonTrayFixedWidth +
                runningAppTrayView.plannedContentWidth(
                    visibleApplicationCapacity: trayVisibleApplicationCapacity
                )
        } else {
            trayVisibleApplicationCapacity = nil
            effectiveFixedZoneWidth =
                launcherZoneView.preferredContentWidth() +
                (sessionManagerWidgetView?.preferredContentWidth() ?? 0) +
                systemResourceWidgetView.preferredContentWidth() + connectivityTrayView.preferredContentWidth() +
                runningAppTrayView.plannedContentWidth(visibleApplicationCapacity: nil) + 1 +
                zoneEdgeInsetsWidth(usesCompactOuterInsets ? compactZoneEdgeInsets : regularZoneEdgeInsets)
        }"""
        
    replacement_block = """        if usesAdaptiveTaskLayout {
            let nonTrayFixedWidth =
                launcherZoneView.preferredContentWidth() +
                (sessionManagerWidgetView?.preferredContentWidth() ?? 0) +
                systemResourceWidgetView.preferredContentWidth() + connectivityTrayView.preferredContentWidth() +
                zoneEdgeInsetsWidth(compactZoneEdgeInsets) + 1
            effectiveFixedZoneWidth = nonTrayFixedWidth
        } else {
            effectiveFixedZoneWidth =
                launcherZoneView.preferredContentWidth() +
                (sessionManagerWidgetView?.preferredContentWidth() ?? 0) +
                systemResourceWidgetView.preferredContentWidth() + connectivityTrayView.preferredContentWidth() +
                1 +
                zoneEdgeInsetsWidth(usesCompactOuterInsets ? compactZoneEdgeInsets : regularZoneEdgeInsets)
        }"""
    content = content.replace(adaptive_block, replacement_block)
    
    content = content.replace("        let trayVisibleApplicationCapacity: Int?\n", "")
    content = content.replace("""        let preferredWidthAffectingStateChanged =
            lastAppliedTrayVisibleApplicationCapacity != trayVisibleApplicationCapacity ||
            lastAppliedUsesCompactOuterInsets != usesCompactOuterInsets""", "        let preferredWidthAffectingStateChanged = lastAppliedUsesCompactOuterInsets != usesCompactOuterInsets")
    
    content = content.replace("        lastAppliedTrayVisibleApplicationCapacity = trayVisibleApplicationCapacity\n", "")
    
    content = re.sub(r"\s*runningAppTrayView\.setVisibleApplicationCapacity\(\n\s*trayVisibleApplicationCapacity,\n\s*notifiesPreferredWidthChange: false\n\s*\)\n", "", content)
    
    content = content.replace("    private var lastAppliedTrayVisibleApplicationCapacity: Int? = nil\n", "")
    
    with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
        f.write(content)

modify_file()
