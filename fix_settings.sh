#!/bin/bash
cat << 'PATCH' > settings.patch
--- Sources/DeskBar/Views/SettingsView.swift
+++ Sources/DeskBar/Views/SettingsView.swift
@@ -60,7 +60,6 @@
     private let showOnAllMonitorsCheckbox = NSButton(checkboxWithTitle: "Show on all monitors", target: nil, action: nil)
     
     // System Resources
-    private let showRingChartsCheckbox = NSButton(checkboxWithTitle: "Use Ring Charts (instead of text)", target: nil, action: nil)
     private let trackBluetoothDevicesCheckbox = NSButton(checkboxWithTitle: "Track Bluetooth device batteries", target: nil, action: nil)
     private let showSystemResourceMemoryMetricCheckbox = NSButton(checkboxWithTitle: "Memory pressure", target: nil, action: nil)
     private let showSystemResourceCPUMetricCheckbox = NSButton(checkboxWithTitle: "CPU usage", target: nil, action: nil)
@@ -196,7 +195,6 @@
                 subviews: [
                     makeCheckboxRow(showSystemResourceWidgetCheckbox),
                     makeCheckboxRow(trackBluetoothDevicesCheckbox),
-                    makeCheckboxRow(showRingChartsCheckbox),
                     makeLabeledControlRow(label: "Show on", control: systemResourceWidgetDisplayPopupButton),
                     makeCheckboxRow(showSystemResourceMemoryMetricCheckbox),
                     makeCheckboxRow(showSystemResourceCPUMetricCheckbox),
@@ -404,9 +402,6 @@
         showOnAllMonitorsCheckbox.target = self
         showOnAllMonitorsCheckbox.action = #selector(showOnAllMonitorsChanged(_:))
 
-        showRingChartsCheckbox.target = self
-        showRingChartsCheckbox.action = #selector(showRingChartsChanged(_:))
-
         showSystemResourceWidgetCheckbox.target = self
         showSystemResourceWidgetCheckbox.action = #selector(showSystemResourceWidgetChanged(_:))
 
@@ -689,13 +684,6 @@
             }
             .store(in: &cancellables)
 
-        settings.$showRingCharts
-            .receive(on: RunLoop.main)
-            .sink { [weak self] value in
-                self?.showRingChartsCheckbox.state = value ? .on : .off
-            }
-            .store(in: &cancellables)
-
         settings.$showSystemResourceWidget
             .receive(on: RunLoop.main)
             .sink { [weak self] value in
@@ -1517,11 +1505,6 @@
     }
 
     @objc
-    private func showRingChartsChanged(_ sender: NSButton) {
-        settings.showRingCharts = sender.state == .on
-    }
-
-    @objc
     private func showSystemResourceWidgetChanged(_ sender: NSButton) {
         settings.showSystemResourceWidget = sender.state == .on
     }
PATCH
patch -p0 < settings.patch
