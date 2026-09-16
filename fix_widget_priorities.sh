#!/bin/bash
cat << 'PATCH' > systemresourcewidgetview2.patch
--- Sources/DeskBar/Views/SystemResourceWidgetView.swift
+++ Sources/DeskBar/Views/SystemResourceWidgetView.swift
@@ -20,6 +20,8 @@
         self.settings = settings
         self.monitor = monitor
         self.isCollapsedInstance = isCollapsedInstance
         super.init(frame: .zero)
+        setContentHuggingPriority(.required, for: .horizontal)
+        setContentCompressionResistancePriority(.required, for: .horizontal)
         setupUI()
         bindState()
         updateVisibility()
PATCH
patch -p0 < systemresourcewidgetview2.patch
