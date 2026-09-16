#!/bin/bash
cat << 'PATCH' > panel.patch
--- Sources/DeskBar/Views/TaskbarPanel.swift
+++ Sources/DeskBar/Views/TaskbarPanel.swift
@@ -69,9 +69,11 @@
         chromeShadowView.wantsLayer = true
         chromeShadowView.layer?.backgroundColor = NSColor.clear.cgColor
 
-        visualEffectView.material = .hudWindow
+        visualEffectView.material = .popover
         visualEffectView.blendingMode = .behindWindow
         visualEffectView.state = .active
         visualEffectView.autoresizingMask = [.width, .height]
         visualEffectView.wantsLayer = true
+        visualEffectView.layer?.borderWidth = 0.5
+        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
         chromeShadowView.addSubview(visualEffectView)
PATCH
patch -p0 < panel.patch
