#!/bin/bash
cat << 'PATCH' > hover_buttons.patch
--- Sources/DeskBar/Views/GroupThumbnailPopover.swift
+++ Sources/DeskBar/Views/GroupThumbnailPopover.swift
@@ -107,37 +107,45 @@
         
-        actionBar.material = .popover
-        actionBar.blendingMode = .withinWindow
-        actionBar.state = .active
-        actionBar.wantsLayer = true
-        actionBar.layer?.cornerRadius = 6
-        actionBar.translatesAutoresizingMaskIntoConstraints = false
-        actionBar.alphaValue = 0
+        let controlsContainer = NSView()
+        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
+        controlsContainer.wantsLayer = true
+        controlsContainer.alphaValue = 0
         
-        let closeButton = NSButton(image: NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)!, target: self, action: #selector(handleClose))
-        closeButton.isBordered = false
-        closeButton.toolTip = "Close"
+        func makeTrafficLight(color: NSColor, icon: String, action: Selector) -> NSButton {
+            let btn = NSButton(title: "", target: self, action: action)
+            btn.isBordered = false
+            btn.wantsLayer = true
+            btn.layer?.cornerRadius = 6
+            btn.layer?.backgroundColor = color.cgColor
+            
+            let config = NSImage.SymbolConfiguration(pointSize: 7, weight: .bold)
+            if let img = NSImage(systemSymbolName: icon, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
+                let tintImg = NSImage(size: img.size)
+                tintImg.lockFocus()
+                NSColor(white: 0, alpha: 0.5).set()
+                img.draw(at: .zero, from: .zero, operation: .sourceAtop, fraction: 1.0)
+                tintImg.unlockFocus()
+                btn.image = tintImg
+            }
+            btn.imagePosition = .imageOnly
+            btn.translatesAutoresizingMaskIntoConstraints = false
+            NSLayoutConstraint.activate([
+                btn.widthAnchor.constraint(equalToConstant: 12),
+                btn.heightAnchor.constraint(equalToConstant: 12)
+            ])
+            return btn
+        }
         
-        let minimizeButton = NSButton(image: NSImage(systemSymbolName: "minus", accessibilityDescription: nil)!, target: self, action: #selector(handleMinimize))
-        minimizeButton.isBordered = false
-        minimizeButton.toolTip = "Minimize"
-        
-        let zoomButton = NSButton(image: NSImage(systemSymbolName: "plus", accessibilityDescription: nil)!, target: self, action: #selector(handleZoom))
-        zoomButton.isBordered = false
-        zoomButton.toolTip = "Zoom"
+        let closeButton = makeTrafficLight(color: NSColor(red: 1.0, green: 0.37, blue: 0.34, alpha: 1.0), icon: "xmark", action: #selector(handleClose))
+        let minimizeButton = makeTrafficLight(color: NSColor(red: 1.0, green: 0.78, blue: 0.2, alpha: 1.0), icon: "minus", action: #selector(handleMinimize))
+        let zoomButton = makeTrafficLight(color: NSColor(red: 0.15, green: 0.79, blue: 0.31, alpha: 1.0), icon: "plus", action: #selector(handleZoom))
         
         let actionStack = NSStackView(views: [closeButton, minimizeButton, zoomButton])
         actionStack.orientation = .horizontal
         actionStack.spacing = 8
         actionStack.translatesAutoresizingMaskIntoConstraints = false
-        
-        actionBar.addSubview(actionStack)
+        controlsContainer.addSubview(actionStack)
         
         addSubview(titleLabel)
         addSubview(imageView)
-        addSubview(actionBar)
+        addSubview(controlsContainer)
         
         NSLayoutConstraint.activate([
             titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
@@ -148,15 +156,12 @@
             imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
             imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
             imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
             
             imageView.widthAnchor.constraint(equalToConstant: resolvedSize.width),
             imageView.heightAnchor.constraint(equalToConstant: resolvedSize.height),
             widthAnchor.constraint(equalToConstant: max(resolvedSize.width + 8, 100)),
             
-            actionStack.centerXAnchor.constraint(equalTo: actionBar.centerXAnchor),
-            actionStack.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor),
-            
-            actionBar.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
-            actionBar.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
-            actionBar.widthAnchor.constraint(equalToConstant: 100),
-            actionBar.heightAnchor.constraint(equalToConstant: 28)
+            actionStack.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor),
+            actionStack.topAnchor.constraint(equalTo: controlsContainer.topAnchor),
+            actionStack.bottomAnchor.constraint(equalTo: controlsContainer.bottomAnchor),
+            actionStack.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor),
+            
+            controlsContainer.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
+            controlsContainer.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8)
         ])
         
         let trackingArea = NSTrackingArea(rect: NSRect(origin: .zero, size: NSSize(width: 1000, height: 1000)), options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
@@ -171,7 +176,7 @@
     override func mouseEntered(with event: NSEvent) {
         isHovered = true
         layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.1).cgColor
-        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; actionBar.animator().alphaValue = 1 }
+        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; controlsContainer.animator().alphaValue = 1 }
         
         let workItem = DispatchWorkItem { [weak self] in
             self?.item.peekHandler()
@@ -183,7 +188,7 @@
     override func mouseExited(with event: NSEvent) {
         isHovered = false
         layer?.backgroundColor = .clear
-        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; actionBar.animator().alphaValue = 0 }
+        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; controlsContainer.animator().alphaValue = 0 }
         
         peekWorkItem?.cancel()
         peekWorkItem = nil
PATCH
patch -p0 < hover_buttons.patch
