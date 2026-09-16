#!/bin/bash
cat << 'PATCH' > stats.patch
--- Sources/DeskBar/Views/SystemResourceWidgetView.swift
+++ Sources/DeskBar/Views/SystemResourceWidgetView.swift
@@ -83,8 +83,9 @@
         let newPopover = NSPopover()
         newPopover.behavior = .transient
         
-        let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor).fixedSize())
+        let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor))
+        controller.preferredContentSize = NSSize(width: 320, height: 380)
         newPopover.contentViewController = controller
         
         newPopover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
PATCH
patch -p0 < stats.patch
