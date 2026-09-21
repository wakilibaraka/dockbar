# DockBar — Project Status Audit

**Generated:** 2026-09-21 from `git log`, source code, and commit diffs.
**HEAD:** `b99c7c1` → `824e1d7` (after release-files commit)

---

## 1. Shipped Features (verified against code)

| Feature | Files / Services | Commit |
|---------|-----------------|--------|
| Native macOS taskbar (AppKit panel, full-width & compact glass modes) | `TaskbarPanel.swift`, `TaskbarContentView.swift`, `AppDelegate.swift` | Pre-v1.8 |
| Window grouping (never / smart / always) | `TaskbarContentView.swift`, `WindowManager.swift` | Pre-v1.8 |
| Drag-reorder task buttons | `TaskbarContentView.swift` | Pre-v1.8 |
| Pinned apps / launcher zone | `LauncherZoneView.swift`, `PinnedAppManager.swift` | Pre-v1.8 |
| Launchpick (fuzzy app launcher) | `Sources/DeskBar/Launchpick/` | Pre-v1.8 |
| Launchpick — hardened launch (direct Process, no `sh -c`) | `LaunchpickManager.swift` | `8e4a2b2` |
| Launchpick — blacklist manager singleton | `BlacklistManager.swift`, `ContentView.swift` | `7cd3769` |
| Battery widget (dock / menu-bar, %, icon styles) | `BatteryMonitor.swift`, `BatteryStatusRenderer.swift` | Pre-v1.8 |
| System Resource widget (CPU / RAM / disk, dock / menu-bar) | `SystemResourceWidgetView.swift`, `SystemResourceDashboardView.swift` | Pre-v1.8 |
| System Resource — `.bar` / `.graph` toggle | `SystemResourceDashboardView.swift`, `MetricGraphView.swift`, `TaskbarSettings.resourceDisplayStyle` | `28bde6e` |
| Network Throughput flyout | `NetworkFlyoutView.swift`, `NetworkThroughputMonitor.swift` | `28bde6e` |
| Keyboard Lock Quick Setting + flyout | `KeyboardLockQuickSetting.swift`, `KeyboardLockFlyoutView.swift` | `da0d731` / `28bde6e` |
| Speed Test Quick Setting | `SpeedTestQuickSetting.swift` | `da0d731` |
| Hop Quick Settings (dark mode, mute, mic, keep-awake, BT, hide-desktop, hidden-files) | `QuickSettingsManager.swift`, `Sources/DeskBar/QuickSettings/` | `da0d731` |
| Quick Settings Tile component | `QuickSettingsTileView.swift` | `28bde6e` |
| Calendar + Quick Settings tray (bundled, dock / menu-bar) | `ConnectivityTrayView.swift`, `CalendarTrayButton.swift` | `da0d731` |
| **Weather widget** (Open-Meteo, CoreLocation, dock / menu-bar, flyout) | `WeatherService.swift`, `WeatherWidgetView.swift`, `WeatherFlyoutView.swift` | `049a075` |
| Hold-to-quit (⌘Q intercept overlay) | `HoldToQuitOverlay.swift`, `TaskbarSettings.enableHoldToQuit` | Pre-v1.8 |
| Session Manager plugin | `SMTaskWindowPlanner.swift`, `Sources/DeskBar/SM/` | Pre-v1.8 |
| Connections (Wi-Fi / Bluetooth tracking, notifications) | `ConnectionsService.swift` | Pre-v1.8 |
| Attention flash + progress indicators | `TaskButtonView.swift` | Pre-v1.8 |
| "Restore Windows From Last Sleep" (`RecentlyClosedTracker`) | `RecentlyClosedTracker.swift` | Pre-v1.8 |
| Multi-monitor support | `ScreenGeometry.swift`, `AppDelegate.swift` | Pre-v1.8 |
| Dock → Menu-bar widget switching (move-not-duplicate) | `AppDelegate.swift`, `TaskbarContentView.swift` | `da0d731` |
| **Deterministic single-pass dock layout** (no oscillation / flicker) | `TaskbarContentView.dockWidgetFixedWidth`, `TaskbarPanel.normalizeFrame` | `63ab794` |
| Settings window (native SwiftUI, tabbed) | `Sources/DeskBar/Views/Settings/` | Pre-v1.8 |
| Dead-code removal (5 unused methods) | `TaskbarContentView.swift`, `WindowManager.swift` | `8e4a2b2` |

---

## 2. Phase Status (verified)

### ✅ Phase 0 — Dock-layout investigation
Written to `docs/dock-layout-investigation.md`. Root causes mapped (feedback loop via `layoutSubtreeIfNeeded` inside `preferredCompactWidth`, double-trigger from CPU-tick callback, unconditional `needsLayout = true` in `normalizeFrame`).

### ✅ Phase 1 — Deterministic single-pass dock layout (v1.9.3)
**Commit:** `63ab794`

Five targeted fixes:
- **A** Removed `layoutSubtreeIfNeeded()` from `preferredCompactWidth()` (`TaskbarContentView.swift:172`).
- **B** Location Combine sinks replaced `scheduleRebuildTaskZone()` → `schedulePreferredWidthNotification()` (`TaskbarContentView.swift:421, 431`).
- **C** Removed redundant `applyResponsiveWidthCapsNowOrSchedule()` from `systemResourceWidgetView.preferredWidthDidChange` (`TaskbarContentView.swift:138`).
- **D** `normalizeFrame` guards `needsLayout = true` behind actual frame change (`TaskbarPanel.swift:272`).
- **E** Extracted `dockWidgetFixedWidth` computed property; used at 5 sites (`TaskbarContentView.swift:174`).

### ❌ Phase 2 — User-selectable split/bundle of Calendar + Quick Settings
**Status: NOT ON `main`.**

Work was started in the Antigravity session (settings model additions, new `CalendarWidgetView`/`QuickSettingsWidgetView` types, dock view wiring) but the session was interrupted before the Combine sinks, `dockWidgetFixedWidth` update, AppDelegate menu-bar wiring, and Settings UI tab were finished. **No split code exists on `main` or in any pushed branch.** Stash exists only in local Antigravity conversation context.

**Remaining work to complete Phase 2:**
1. Persist `splitCalendarAndQuickSettings`, `calendarLocation`, `quickSettingsLocation` in `TaskbarSettings`.
2. Add `CalendarWidgetView` / `QuickSettingsWidgetView` to dock (`TaskbarContentView`).
3. Update `dockWidgetFixedWidth` to account for split-mode widgets.
4. Update location Combine sinks in `TaskbarContentView` and `AppDelegate` status items.
5. Add split-mode toggle + pickers to `TaskbarElementsTab`.
6. Build + DMG → v1.9.5.

### ✅ Phase 3 — Metric graphs, Hop flyouts, bar/graph toggle (v1.9.4)
**Commits:** `28bde6e` (feature), `b99c7c1` (compile fix), `e826004` (Launchpick compile fix)

Delivered:
- `MetricGraphView` rolling sparkline component.
- `NetworkThroughputMonitor` + `NetworkFlyoutView`.
- `KeyboardLockFlyoutView`.
- `QuickSettingsTileView`.
- `resourceDisplayStyle` `.bar` / `.graph` toggle in `SystemResourceDashboardView`.
- Weather widget (`WeatherService`, `WeatherWidgetView`, `WeatherFlyoutView`) — note: shipped in `049a075`, merged between Phase 1 and Phase 3.

### ❌ Phase 4 — Expanded Settings UI (up to 8 tabs)
**Status: NOT STARTED.** Current settings window has 7 tabs (General, Dock Behavior, Elements, Flyouts, Connections, About). Planned expansion: add Quick Settings tab, Hold-to-Quit tab, widget-locations as first-class controls. Requires window resize (target ~1100×860).

---

## 3. Commit Log Since `63ab794` (inclusive)

| SHA | Description |
|-----|-------------|
| `63ab794` | fix(layout): deterministic single-pass dock layout — removes oscillation, flicker, overflow (Phase 1) |
| `7cd3769` | fix: restore blacklist filter (BlacklistManager singleton), frontmost-click default `.cycle`, minimize stability (grace window for Finder jump) |
| `8e4a2b2` | feat(#2): harden Launchpick execution (direct Process launch, no `sh -c`); remove 5 dead methods from `TaskbarContentView` + `WindowManager` |
| `e826004` | fix(launchpick): PR #2 compile fixes — `var` fields for memberwise init, convert non-exiting `guard` to `if` |
| `049a075` | feat(#3): native weather widget — Open-Meteo, CoreLocation, dock/menu-bar tile, hourly/daily flyout |
| `28bde6e` | feat(#4): Phase 3 metric graphs + flyouts — `MetricGraphView`, `NetworkThroughputMonitor`, `NetworkFlyoutView`, `KeyboardLockFlyoutView`, `QuickSettingsTileView`, `.bar`/`.graph` toggle, `resourceDisplayStyle` setting |
| `b99c7c1` | fix(#5): replace unsupported `#state` macro with explicit `@State` in `KeyboardLockFlyoutView` + `SystemResourceDashboardView` |
| `824e1d7` | chore: v1.9.4 release files (`release_refined.sh`, `release_notes.md`) |

---

## 4. Known Tech Debt

### Swift 6 Strict-Concurrency Warnings (will become errors under `-strict-concurrency=complete`)

| Location | Warning Class | Detail |
|----------|---------------|--------|
| `QuickSettingsManager.swift` | `@MainActor` isolation | Class marked `@MainActor` but several callbacks cross actor boundaries without `await` |
| `WeatherService.swift` | `CLLocationManagerDelegate` conformance | Delegate callbacks are not isolated; `CLLocationManagerDelegate` is not `Sendable` — will be a strict-concurrency error in Swift 6 mode |
| `BatteryMonitor.swift` | Non-isolated timer callbacks | `Timer` publish crosses thread boundary into `@Published` properties without explicit actor hop |
| `BluetoothStatsService.swift` | `CBCentralManagerDelegate` conformance | Delegate methods called on arbitrary thread; `@Published` mutation not isolated |
| `KeyboardLockQuickSetting.swift` | `nonisolated(unsafe)` | Properties marked `nonisolated(unsafe)` as a workaround — correct fix is a dedicated non-isolated wrapper |

**These are today warnings only; the current toolchain does not enforce strict concurrency. They will become hard errors if the project ever sets `-strict-concurrency=complete`.**

### Other Debt

| Item | Priority | Notes |
|------|----------|-------|
| Replace `print` with a unified logger (`os.Logger`) | Medium | Many `print(...)` calls remain throughout services and views |
| `http://127.0.0.1:8420` localhost endpoint | Low | Intentionally kept (dev/local testing); document or gate behind `#if DEBUG` |
| Phase 2 split Calendar/Quick Settings | High | Not started on `main`; detailed work plan in §2 above |
| Phase 4 expanded Settings UI | Medium | Not started |
| Windows 11 Mode | Low | Planned but not designed — no spec or branch |

---

## 5. Release History

| Tag | Commit | Status | Notes |
|-----|--------|--------|-------|
| `v1.8.0` | `b5bf97f` | ✅ Released | Pre-investigation baseline |
| `v1.9.1` | `393ee34` | ✅ Released | Settings refactor, flyout fixes, window grouping |
| `v1.9.2` | `7cd3769` | ✅ Released | Hop features + widget switching (PR #1 squash) + stabilization edits |
| `v1.9.3` | `7cd3769` *(same commit, additional tag)* | ✅ Released | Phase 1 deterministic layout |
| `v1.9.4` | `824e1d7` | ✅ Released (pre-release) | Weather widget + Phase 3 graphs/flyouts + Launchpick hardening |
