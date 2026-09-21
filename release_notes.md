# DockBar v1.9.4 Beta

This release delivers the native weather widget, reusable metric graphs, Hop feature flyouts, a bar/graph resource-display toggle, hardened Launchpick launching, and targeted dead-code cleanup.

---

## 🌤 Weather Widget (new)
- Native weather widget powered by Open-Meteo (no API key required).
- Shows current temperature and condition icon in a compact dock or menu-bar tile.
- Tap to open a **Weather Flyout** with hourly/daily forecast and feels-like temperature.
- Location resolved via CoreLocation; updates on a configurable interval.
- Placeable in **Dock** or **Menu Bar** (same move-not-duplicate mechanism as other widgets).
- New setting: `weatherWidgetLocation` (default: Menu Bar).

## 📊 Metric Graphs + Flyouts (Phase 3)
- **Reusable `MetricGraphView`**: a compact rolling-line graph component used across CPU, RAM, network throughput, and any future metrics.
- **System Resource Dashboard** gains a `.bar` / `.graph` toggle (`resourceDisplayStyle` setting, default: bar) — switch between numeric bar gauges and the new sparkline graph view.
- **Network Throughput Flyout** (`NetworkFlyoutView`): live ↓/↑ Mbps charts via the new `NetworkThroughputMonitor` service, shown from the System Resource widget.
- **Keyboard Lock Flyout** (`KeyboardLockFlyoutView`): clear locked/unlocked indicator with an in-flyout unlock affordance — replaces the bare Quick Settings tile for the lock feature.
- **Quick Settings Tile View** (`QuickSettingsTileView`): reusable tile component shared between the grid and future flyout surfaces.

## 🔒 Launchpick Security Hardening (Tier-1)
- Eliminated command-injection via `LaunchpickManager.launch()`: replaced `/bin/sh -c exec_string` with direct `Process` argument-array execution.
- Removed 5 dead/unused methods from `TaskbarContentView` and `WindowManager`.

## 🐛 Fixes
- Fixed compile errors introduced by Phase 3 PR: replaced unsupported Swift state property-wrapper macros (`#state`) with explicit `@State` properties in `KeyboardLockFlyoutView` and `SystemResourceDashboardView`.
- Fixed memberwise-init variance in Launchpick `ContentView` (`var` fields, non-exiting guards).

---

## Files Changed Since v1.9.3
| File | What Changed |
|------|-------------|
| `WeatherService.swift` | New — Open-Meteo fetch + CoreLocation |
| `WeatherWidgetView.swift` | New — dock/menu-bar weather tile |
| `WeatherFlyoutView.swift` | New — hourly/daily forecast popover |
| `MetricGraphView.swift` | New — rolling sparkline graph component |
| `NetworkThroughputMonitor.swift` | New — live ↓/↑ network service |
| `NetworkFlyoutView.swift` | New — network throughput flyout |
| `KeyboardLockFlyoutView.swift` | New — keyboard lock status flyout |
| `QuickSettingsTileView.swift` | New — reusable tile component |
| `SystemResourceDashboardView.swift` | Bar/graph toggle + MetricGraphView integration |
| `SystemResourceWidgetView.swift` | Wires flyout + new display style |
| `TaskbarSettings.swift` | `resourceDisplayStyle`, `weatherWidgetLocation` |
| `LaunchpickManager.swift` | Direct Process launch (no sh -c) |
| `KeyboardLockQuickSetting.swift` | Flyout wiring |
| `SpeedTestQuickSetting.swift` | Minor wiring update |
| `TaskbarContentView.swift` | 45 lines of dead code removed |
| `WindowManager.swift` | 6 lines of dead code removed |
| `TaskbarElementsTab.swift` | Bar/graph style picker |
