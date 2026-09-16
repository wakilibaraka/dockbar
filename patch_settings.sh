#!/bin/bash
cat << 'PATCH' > settings.patch
--- Sources/DeskBar/Models/TaskbarSettings.swift
+++ Sources/DeskBar/Models/TaskbarSettings.swift
@@ -52,6 +52,10 @@
         didSet { defaults.set(useAppIconAsLauncherButton, forKey: "useAppIconAsLauncherButton") }
     }
 
+    @Published var showRingCharts: Bool {
+        didSet { defaults.set(showRingCharts, forKey: "showRingCharts") }
+    }
+
     @Published var taskbarHeight: CGFloat {
         didSet { defaults.set(taskbarHeight, forKey: "taskbarHeight") }
     }
@@ -107,6 +111,7 @@
         showQuickSettings = defaults.object(forKey: "showQuickSettings") as? Bool ?? false
         enabledQuickSettings = defaults.stringArray(forKey: "enabledQuickSettings") ?? ["darkMode", "mute", "muteMic", "keepAwake", "bluetooth"]
         useAppIconAsLauncherButton = defaults.object(forKey: "useAppIconAsLauncherButton") as? Bool ?? false
+        showRingCharts = defaults.object(forKey: "showRingCharts") as? Bool ?? true
         
         taskbarHeight = defaults.object(forKey: "taskbarHeight") as? CGFloat ?? Self.defaultTaskbarHeight
         iconSize = defaults.object(forKey: "iconSize") as? CGFloat ?? 24
PATCH
patch -p0 < settings.patch
