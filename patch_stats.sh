#!/bin/bash
cat << 'PATCH' > stats.patch
--- Sources/DeskBar/Views/SystemResourceWidgetView.swift
+++ Sources/DeskBar/Views/SystemResourceWidgetView.swift
@@ -10,7 +10,7 @@
     
     private var hostingView: NSHostingView<UnifiedSystemResourceWidgetView>?
     
-    private lazy var flyoutPanel = SystemResourceFlyoutPanel(monitor: monitor)
+    private var popover: NSPopover?
     private var cancellables = Set<AnyCancellable>()
     
     var preferredWidthDidChange: (() -> Void)?
@@ -77,18 +77,14 @@
     // MARK: - Interaction
     
     override func mouseDown(with event: NSEvent) {
-        if flyoutPanel.isVisible {
-            flyoutPanel.close()
+        if let popover = popover, popover.isShown {
+            popover.performClose(nil)
+            self.popover = nil
             return
         }
         
-        guard let window = self.window else { return }
-        let screenRect = window.convertToScreen(self.convert(self.bounds, to: nil))
-        let panelSize = flyoutPanel.frame.size
-        
-        let margin: CGFloat = 8
-        let originX = max(8, screenRect.midX - (panelSize.width / 2))
-        let originY = screenRect.maxY + margin
-        
-        flyoutPanel.setFrameOrigin(NSPoint(x: originX, y: originY))
-        flyoutPanel.makeKeyAndOrderFront(nil)
+        let newPopover = NSPopover()
+        newPopover.behavior = .transient
+        newPopover.contentViewController = NSHostingController(rootView: SystemResourceDashboardView(monitor: monitor))
+        newPopover.show(relativeTo: self.bounds, of: self, preferredEdge: .maxY)
+        self.popover = newPopover
     }
 }
PATCH
patch -p0 < stats.patch
