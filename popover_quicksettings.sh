#!/bin/bash
cat << 'PATCH' > qs.patch
--- Sources/DeskBar/Views/QuickSettingsFlyoutPanel.swift
+++ Sources/DeskBar/Views/QuickSettingsFlyoutPanel.swift
@@ -4,7 +4,7 @@
 import SwiftUI
 import CoreAudio
 
-final class QuickSettingsFlyoutPanel: NSPanel {
+final class QuickSettingsViewController: NSViewController {
     private let settings: TaskbarSettings
     private let manager: QuickSettingsManager
     private let blurView = NSVisualEffectView()
@@ -15,58 +15,22 @@
 
     init(settings: TaskbarSettings, manager: QuickSettingsManager) {
         self.settings = settings
         self.manager = manager
-        super.init(
-            contentRect: NSRect(x: 0, y: 0, width: 340, height: 200),
-            styleMask: [.borderless, .nonactivatingPanel],
-            backing: .buffered,
-            defer: false
-        )
-        isFloatingPanel = true
-        level = .popUpMenu
-        backgroundColor = .clear
-        isOpaque = false
-        hasShadow = true
-        collectionBehavior = [.canJoinAllSpaces, .transient]
-
+        super.init(nibName: nil, bundle: nil)
+    }
+    
+    required init?(coder: NSCoder) { fatalError() }
+    
+    override func loadView() {
         setupUI()
-
-        // Close on Escape or click outside
-        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
-            if event.keyCode == 53 { self?.close(); return nil }
-            return event
-        }
+        self.view = blurView
     }
 
-    // MARK: - Lifecycle
-    
-    override func makeKeyAndOrderFront(_ sender: Any?) {
-        super.makeKeyAndOrderFront(sender)
-        if localMonitor == nil {
-            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
-                guard let self = self else { return event }
-                if !self.frame.contains(event.locationInWindow) {
-                    self.close()
-                }
-                return event
-            }
-        }
-        if globalMonitor == nil {
-            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
-                self?.close()
-            }
-        }
-    }
-    
-    override func close() {
-        super.close()
-        if let local = localMonitor {
-            NSEvent.removeMonitor(local)
-            localMonitor = nil
-        }
-        if let global = globalMonitor {
-            NSEvent.removeMonitor(global)
-            globalMonitor = nil
-        }
+    override func viewWillAppear() {
+        super.viewWillAppear()
+        refreshOnOpen()
     }
 
     // MARK: - UI Setup
@@ -82,7 +46,6 @@
         blurView.layer?.cornerCurve = .continuous
         blurView.layer?.masksToBounds = true
-        contentView = blurView
     }
 
     func refreshOnOpen() {
@@ -165,18 +128,8 @@
         // Compute size then clamp to screen
         outer.layoutSubtreeIfNeeded()
         let fit = outer.fittingSize
-        let panelW = fit.width + 28
-        let panelH = fit.height + 28
-
-        // keep current origin but clamp
-        let origin = self.frame.origin
-        var newFrame = NSRect(x: origin.x, y: origin.y, width: panelW, height: panelH)
-        if let screen = self.screen ?? NSScreen.main {
-            let vis = screen.visibleFrame
-            if newFrame.maxX > vis.maxX - 8 { newFrame.origin.x = vis.maxX - newFrame.width - 8 }
-            if newFrame.minX < vis.minX + 8  { newFrame.origin.x = vis.minX + 8 }
-            if newFrame.maxY > vis.maxY - 8  { newFrame.origin.y = vis.maxY - newFrame.height - 8 }
-            if newFrame.minY < vis.minY + 8  { newFrame.origin.y = vis.minY + 8 }
-        }
-        setFrame(newFrame, display: false)
+        let popoverW = fit.width + 28
+        let popoverH = fit.height + 28
+        self.preferredContentSize = NSSize(width: popoverW, height: popoverH)
+        self.view.frame.size = self.preferredContentSize
     }
 
PATCH
patch -p0 < qs.patch
