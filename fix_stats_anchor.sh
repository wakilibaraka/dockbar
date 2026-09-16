#!/bin/bash
cat << 'PATCH' > stats_anchor.patch
--- Sources/DeskBar/Views/SystemResourceWidgetView.swift
+++ Sources/DeskBar/Views/SystemResourceWidgetView.swift
@@ -86,7 +86,11 @@
         let controller = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor))
         controller.preferredContentSize = NSSize(width: 320, height: 380)
         newPopover.contentViewController = controller
-        newPopover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
+        
+        var anchorRect = self.bounds
+        anchorRect.size.width = min(self.bounds.width, 44)
+        
+        newPopover.show(relativeTo: anchorRect, of: self, preferredEdge: .maxY)
         self.popover = newPopover
     }
 }
PATCH
patch -p0 < stats_anchor.patch
