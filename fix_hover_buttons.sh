#!/bin/bash
cat << 'PATCH' > hover_buttons.patch
--- Sources/DeskBar/Views/GroupThumbnailPopover.swift
+++ Sources/DeskBar/Views/GroupThumbnailPopover.swift
@@ -214,7 +214,7 @@
     private var isHovered = false
     private var peekWorkItem: DispatchWorkItem?
     
-    private let actionBar = NSVisualEffectView()
+    private let actionBar = NSView()
     
     init(item: WindowThumbnailItem, size: CGFloat, dismissHandler: @escaping () -> Void) {
         self.item = item
@@ -233,11 +233,6 @@
         
         let resolvedSize = resolvedSize(for: item.thumbnail, boundingSize: size)
         
-        let controlsContainer = NSView()
-        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
-        controlsContainer.wantsLayer = true
-        controlsContainer.alphaValue = 0
-        self.actionBar = controlsContainer // reuse the property name for ease
+        actionBar.translatesAutoresizingMaskIntoConstraints = false
+        actionBar.wantsLayer = true
+        actionBar.alphaValue = 0
         
         func makeTrafficLight(color: NSColor, icon: String, action: Selector) -> NSButton {
             let btn = NSButton(title: "", target: self, action: action)
@@ -258,10 +253,10 @@
         actionStack.orientation = .horizontal
         actionStack.spacing = 8
         actionStack.translatesAutoresizingMaskIntoConstraints = false
-        controlsContainer.addSubview(actionStack)
+        actionBar.addSubview(actionStack)
         
         addSubview(titleLabel)
         addSubview(imageView)
-        addSubview(controlsContainer)
+        addSubview(actionBar)
         
         NSLayoutConstraint.activate([
             titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
@@ -276,13 +271,13 @@
             imageView.heightAnchor.constraint(equalToConstant: resolvedSize.height),
             widthAnchor.constraint(equalToConstant: max(resolvedSize.width + 8, 100)),
             
-            actionStack.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor),
-            actionStack.topAnchor.constraint(equalTo: controlsContainer.topAnchor),
-            actionStack.bottomAnchor.constraint(equalTo: controlsContainer.bottomAnchor),
-            actionStack.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor),
+            actionStack.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor),
+            actionStack.topAnchor.constraint(equalTo: actionBar.topAnchor),
+            actionStack.bottomAnchor.constraint(equalTo: actionBar.bottomAnchor),
+            actionStack.trailingAnchor.constraint(equalTo: actionBar.trailingAnchor),
             
-            controlsContainer.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
-            controlsContainer.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8)
+            actionBar.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
+            actionBar.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8)
         ])
PATCH
patch -p0 < hover_buttons.patch
