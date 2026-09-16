#!/bin/bash
cat << 'PATCH' > manager.patch
--- Sources/DeskBar/Launchpick/LaunchpickManager.swift
+++ Sources/DeskBar/Launchpick/LaunchpickManager.swift
@@ -64,6 +64,7 @@
                 newPopover.behavior = .transient
                 let vc = NSViewController()
                 vc.view = hostingView
+                vc.preferredContentSize = NSSize(width: 680, height: 480)
                 newPopover.contentViewController = vc
                 self.popover = newPopover
             }
PATCH
patch -p0 < manager.patch
