#!/bin/bash
cat << 'PATCH' > stats2.patch
--- Sources/DeskBar/Views/SystemResourceWidgetView.swift
+++ Sources/DeskBar/Views/SystemResourceWidgetView.swift
@@ -83,7 +83,9 @@
         
         let newPopover = NSPopover()
         newPopover.behavior = .transient
-        newPopover.contentViewController = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor).fixedSize())
+        let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor))
+        controller.preferredContentSize = NSSize(width: 320, height: 380)
+        newPopover.contentViewController = controller
         newPopover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
         self.popover = newPopover
     }
PATCH
patch -p0 < stats2.patch
