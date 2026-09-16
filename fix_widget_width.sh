#!/bin/bash
cat << 'PATCH' > widget_width.patch
--- Sources/DeskBar/Views/SystemResourceWidgetView.swift
+++ Sources/DeskBar/Views/SystemResourceWidgetView.swift
@@ -28,7 +28,7 @@
         if isHidden { return 0 }
         let hasBattery = SystemStatsService.shared.batteryStats != nil
         let base = settings.showRingCharts ? 44.0 : 56.0
-        return base + (hasBattery ? 28.0 : 0.0)
+        return base + (hasBattery ? 34.0 : 0.0)
     }
     
     private func setupUI() {
PATCH
patch -p0 < widget_width.patch
