#!/bin/bash
cat << 'PATCH' > stats.patch
--- Sources/DeskBar/Views/SystemResourceWidgetView.swift
+++ Sources/DeskBar/Views/SystemResourceWidgetView.swift
@@ -83,7 +83,11 @@
         
         let newPopover = NSPopover()
         newPopover.behavior = .transient
-        newPopover.contentViewController = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor))
+        
+        let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor).fixedSize())
+        newPopover.contentViewController = controller
+        
         newPopover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
         self.popover = newPopover
     }
PATCH
patch -p0 < stats.patch
