#!/bin/bash
cat << 'PATCH' > manager.patch
--- Sources/DeskBar/Launchpick/LaunchpickManager.swift
+++ Sources/DeskBar/Launchpick/LaunchpickManager.swift
@@ -74,7 +74,9 @@
             
             if panel == nil {
                 let newPanel = LaunchpickPanel()
-                newPanel.contentView = hostingView
+                hostingView.frame = newPanel.contentView!.bounds
+                hostingView.autoresizingMask = [.width, .height]
+                newPanel.contentView?.addSubview(hostingView)
                 self.panel = newPanel
             }
             
PATCH
patch -p0 < manager.patch
