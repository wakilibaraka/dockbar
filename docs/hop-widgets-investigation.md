# DockBar — Hop Features & Widget Dock↔Menu-bar Switching
## Investigation Report (read-only, no code changed)

**Base:** `origin/main` @ `393ee34` (v1.9.1, Sep 18 2026)  
**Date:** Sep 20 2026  
**Status:** Investigation only — STOP for review before any code change.

---

## 1. Local Working-Tree State

`git status` after `git pull` shows **working tree is clean**. All four in-progress edits from the Sep 18 session were lost during the stream interruptions and were **never committed**. They need to be re-applied before merging anything:

| File | Change | Impact if missing |
|------|--------|-------------------|
| `Launchpick/AppScanner.swift` | Added `bundleIdentifier: String?` field to `App` struct | Start Menu blacklist silently broken |
| `Launchpick/ContentView.swift` | `systemApps` property filters via `BlacklistManager` | Blacklisted apps still appear in All Apps |
| `Models/TaskbarSettings.swift` | Default `frontmostClickAction` → `.cycle` | Active apps still minimize on click |
| `Views/TaskbarContentView.swift` | `TaskZoneOrderingState.recentlyDepartedItemIDs` 10-second grace window | Finder/apps jump to far-right when minimized |

### Build-Breaking Edit (Blacklist)
The `ContentView.swift` edit called `BlacklistManager.shared.isBlacklisted(...)` but `BlacklistManager` has **no `shared` singleton**. The compiler error was:
```
error: type 'BlacklistManager' has no member 'shared'
```
**Fix:** Add `static let shared = BlacklistManager()` to `BlacklistManager`. Every other major service (`QuickSettingsManager`, `RecentlyClosedTracker`) follows this singleton pattern. Correct and safe.

### Two Safe Uncommitted Edits (safe to re-apply)
1. **`frontmostClickAction` default `.cycle`** — one-liner in `TaskbarSettings.swift` init. Zero risk.
2. **`recentlyDepartedItemIDs` minimize fix** — pure additive logic in a private struct. 10-second window prevents icon jumping; no regressions possible.

---

## 2. Widget Architecture (Dock↔Menu-bar Switching)

### How Dock Widgets Render Today

All right-side dock widgets live inside `TaskbarContentView` in a horizontal `NSStackView` called `zonesStackView`:

```
zonesStackView (NSStackView, horizontal)
├── launcherZoneView       (NSView)
├── taskZoneContainer      (NSView)
├── clusterDivider         (NSView — 1pt separator)  ← LOCAL let (bug: can't hide it)
├── connectivityTrayView   (ConnectivityTrayView : NSStackView)   ← pure AppKit
└── systemResourceWidgetView (SystemResourceWidgetView : NSView)  ← AppKit wrapping SwiftUI
```

The **battery** is an entirely separate `NSStatusItem` in the system menu bar managed only by `AppDelegate.configureStatusItem()` — never inside `TaskbarContentView`.

| Widget | Class | Framework | Flyout |
|--------|-------|-----------|--------|
| Calendar + Quick Settings | `ConnectivityTrayView : NSStackView` | AppKit | `NSPopover` |
| CPU/MEM/GPU | `SystemResourceWidgetView : NSView` | AppKit (hosts SwiftUI internally) | `NSPopover` |
| Battery | `NSStatusItem` | AppKit | `NSPopover` (BatteryFlyoutView) |

**Known bug in `main`:** `clusterDivider` is a `local let` inside `setupZonesView()`. It is added to the stack view but there is no ivar to reference it for hiding. Even if both widgets move to the menu bar, the 1pt divider stays visible forever.

### Hosting a Dock Widget in the Menu Bar

`NSStatusItem.button` is a standard `NSButton` (an `NSView`). You can `addSubview(anyNSView)` to it. Both `ConnectivityTrayView` and `SystemResourceWidgetView` are `NSView` subclasses, so they can be embedded directly. `SystemResourceWidgetView` exposes a `preferredWidthDidChange` callback for dynamic width updates, which the menu bar item length can follow.

### What It Takes to Move a Widget (move-not-duplicate)

1. **Settings:** `WidgetLocation` enum (`.dock` / `.menuBar`) + three `@Published` properties in `TaskbarSettings`. Defaults from `UserDefaults`.
2. **Dock side (`TaskbarContentView`):** Combine sink → `widget.isHidden = location != .dock`. Gate all 4 `preferredContentWidth()` calls on `location == .dock`. Hide `clusterDivider` when both widgets are off dock.
3. **Menu-bar side (`AppDelegate`):** Create two new dedicated `NSStatusItem` instances. When location → `.menuBar`, create a new view instance, embed in `statusItem.button`, set `isVisible = true`. When switching back → `.dock`, remove view from button subviews, set `isVisible = false`. The dock Combine sink then un-hides the original dock view automatically.
4. **Battery:** Already exclusively in menu bar. Moving to dock is out of scope for now.

---

## 3. Hop Features Analysis

### Already in DockBar (skip these)
| Hop Feature | DockBar Equivalent |
|-------------|-------------------|
| Keep-Awake | `KeepAwakeQuickSetting.swift` |
| Pomodoro | `PomodoroQuickSetting.swift` |
| System Monitor | `SystemResourceWidgetView` |
| Screenshots | `ScreenshotQuickSetting.swift` |
| Wi-Fi / Bluetooth / Dark Mode toggles | Existing QuickSettings |

### Keyboard Lock (Cleaning Mode)

**Hop's approach** (`KeyboardLockController.swift`, MIT licensed):
- `CGEventTap` at `.cghidEventTap / .headInsertEventTap` swallows `keyDown`, `keyUp`, `flagsChanged`.
- **Prove-before-display:** Installs tap, sends a synthetic probe event, verifies the tap actually suppressed it. Only shows the lock screen if proven. Prevents false-lock on stale AX permission.
- **Full-screen overlay** (the "cover") — NSWindow covering entire screen. Shows "Keyboard Locked" with an unlock button. Exit = mouse click OR Esc+Shift chord held 2 seconds.
- Configurable auto-unlock timer (60s / 5min / 15min / forever).
- Uses `AXIsProcessTrusted()` — DockBar already has this permission.

**Jules PR's approach** (`KeyboardLockQuickSetting.swift`):
- Same `CGEventTap` swallow (correct).
- **No overlay** — keyboard is silently blocked with zero visual indicator.
- **No proof step** — assumes the tap worked.
- **No timer** — locked until user mouses to QuickSettings panel and clicks again.
- Registered in `QuickSettingsManager` (correct).

**Assessment:** Jules' version is functional but user-hostile. Minimum safe version needs: (a) a visible lock indicator (at minimum the Quick Settings button changes to a lock icon while active), (b) `AXIsProcessTrusted()` guard, (c) auto-unlock timer. Full Hop-style overlay is ideal for v2.

### Speed Test

**Hop's approach** (`SpeedTest.swift`, MIT licensed):
- Runs `/usr/bin/networkQuality` (ships with macOS 12+, available on DockBar's macOS 14 minimum).
- Attaches to a **pseudo-TTY** (`openpty`) because `networkQuality` only streams live numbers to a terminal — without a TTY it silently waits until the final SUMMARY.
- Reads `Downlink:` and `Uplink:` live from the master fd while running.
- 90-second watchdog. Stores last result in `UserDefaults` with SSID + timestamp (marks stale if >30 min or SSID changed).
- No external dependencies. No entitlements beyond what DockBar already has.

**Jules PR's approach** (`SpeedTestController.swift`):
- **Exact faithful copy** of Hop's `SpeedTest.swift` — including comments referencing `SPEC: docs/spec.md`. This is correct and complete.
- `SpeedTestQuickSetting.swift` wraps it in the QuickSetting protocol (`isAction = true`, `toggle()` calls `controller.run()`).
- **Gap:** Results are never surfaced. After the test completes, `controller.last` has the numbers but nothing shows them to the user.

---

## 4. Jules PR #1 — Full Audit

**PR:** #1, branch `integrate-hop-feature...`, created Sep 19 2026  
**Commits:** `409df38` + `67a5c31` (10 files changed: +488 / -32)  
**Merge test:** `git merge --no-commit --no-ff pr-1` → **no text conflicts** (clean against v1.9.1)

### File-by-File Verdict

| File | What PR Does | Verdict |
|------|-------------|---------|
| `Models/TaskbarSettings.swift` | +31 lines: `WidgetLocation` enum, 3 `@Published` location properties + UserDefaults init | ✅ **Salvage** |
| `QuickSettings/KeyboardLockQuickSetting.swift` | New 68-line file: `CGEventTap` swallow, no overlay | ⚠️ **Salvage with overlay fix** |
| `QuickSettings/SpeedTestController.swift` | New 206-line file: faithful Hop port | ✅ **Salvage** |
| `QuickSettings/SpeedTestQuickSetting.swift` | New 45-line file: protocol wrapper, results not shown | ⚠️ **Salvage with results UI fix** |
| `Services/QuickSettingsManager.swift` | +2 lines: registers both new QuickSettings | ✅ **Salvage** |
| `App/AppDelegate.swift` | +58 lines: 2 new NSStatusItem ivars, Combine sinks for widget location | ✅ **Salvage** |
| `Views/TaskbarContentView.swift` | +39 lines: promotes `clusterDivider` to ivar, hides widgets, gates width calculations | ✅ **Salvage — fixes real bug** |
| `Views/Settings/TaskbarElementsTab.swift` | +35/-67 lines: adds 3 `Picker` controls for widget location | ✅ **Salvage** |
| `release_notes.md` | Overwrites v1.5.0 notes with confusingly labelled "v1.7.0" notes | 🚫 **Reject — write fresh** |
| `release_refined.sh` | Guts the entire script body, replaces with 2-line sandbox excuse comment | 🚫 **REJECT — do not merge** |

### Reviewer-Flagged Issues — Ground-Truth Verification

**Claim: "RecentlyClosedTracker deleted and Restore Windows menu removed"**  
**VERDICT: FALSE.** The PR's `AppDelegate.swift` is 663 lines (vs 605 in main = +58 lines added). Grep confirms `RecentlyClosedTracker` appears **11 times** and `restoreWindows` / "Restore Windows" appear **10 times** in the PR branch — same or more than `main`. This claim was a false positive from Jules' automated reviewer.

**Claim: "Widgets duplicated instead of hidden from dock"**  
**VERDICT: PARTIALLY TRUE but acceptable.** When set to `.menuBar`, the dock correctly hides the widget (`widget.isHidden = true` via Combine sink in `TaskbarContentView`). The menu bar creates a *new* instance. When switching back to `.dock`, the menu bar removes its view (`item.button?.subviews.forEach { $0.removeFromSuperview() }`) and the dock Combine sink un-hides the original. The move-not-duplicate contract is upheld, but transient state (open popover, etc.) in the new menu-bar instance is lost on switch-back. Acceptable for v1.

**Claim: "Dead `updateClusterDividerVisibility()`"**  
**VERDICT: FALSE.** The function is called in `init` (L121) and in both Combine sinks (after location change for connectivity and system resource). It is live and correct.

**Claim: "Gutted `release_refined.sh`"**  
**VERDICT: TRUE.** Jules stripped the entire script and left only:
```bash
#!/bin/bash
set -e
# Not building locally since sandbox doesn't have macOS swift build tools.
# CI will handle the build after we push.
```
**Do not merge this.** The real script must be preserved and properly parameterized.

### AppDelegate `configureStatusItem()` — Real Issue Found

The PR wraps the Combine sink setup in `if let settings = self.settings { ... }`. Since `configureStatusItem()` is called from inside `taskbar(settings:...)` after `self.settings` is set, this guard is always true and the sinks are always registered. Low risk but slightly confusing — could be written more clearly with a direct reference.

### Merge-Risk Hotspots

Three files were modified in both v1.9.1 and the PR:

| File | `git merge` result |
|------|--------------------|
| `AppDelegate.swift` | **Clean** — PR adds new ivars/sinks in non-overlapping locations |
| `TaskbarSettings.swift` | **Clean** — PR adds new properties after existing ones |
| `TaskbarContentView.swift` | **Clean** — changes are in different line ranges |

---

## 5. Phased Implementation Plan

> **Hard guardrails:**
> - `RecentlyClosedTracker` and "Restore Windows From Last Sleep" are **never deleted**.
> - `release_refined.sh` is **updated/parameterized, never gutted**.
> - Widget switching = **move** (hide from dock + show in menu bar). Never two live visible instances.
> - Every function must be reachable from a user action. No dead code.
> - `swift build -c release` must pass (0 errors, 0 unresolved warnings) before each commit.

---

### Phase 0 — Stabilize `main` (no new features)

Re-apply the 4 uncommitted Sep-18 changes that were lost:

1. `BlacklistManager` → add `static let shared = BlacklistManager()`.
2. `AppScanner.App` → add `bundleIdentifier: String?` field.
3. `LaunchpickContentView.systemApps` → filter by blacklist via `BlacklistManager.shared`.
4. `TaskbarSettings.init` → `frontmostClickAction` default → `.cycle`.
5. `TaskZoneOrderingState` → `recentlyDepartedItemIDs` 10-second grace window.
6. **Build gate:** `swift build -c release 2>&1 | grep -E "error:|warning:" | head -20`
7. Commit: `fix: re-apply lost changes — blacklist filter, minimize stability, cycle default`

---

### Phase 1 — Keyboard Lock QuickSetting

1. Add `KeyboardLockQuickSetting.swift` (from PR, with additions):
   - Keep the `CGEventTap` swallow logic.
   - Add `AXIsProcessTrusted()` guard with user-facing alert if denied.
   - Add `isOn` state driven by whether `eventTap != nil`.
   - When `isOn == true`, show a persistent `NSUserNotification` / lock badge on the Quick Settings button so user knows keyboard is locked.
   - Add auto-unlock after 5 minutes (configurable in Settings tab later).
2. Register in `QuickSettingsManager.allSettings`.
3. **Build gate + manual test:** Lock keyboard → keys blocked → click Quick Settings tile again → unlock.
4. Commit: `feat(quick-settings): add Keyboard Lock (Cleaning Mode) with visual indicator and 5-min auto-unlock`

---

### Phase 2 — Speed Test QuickSetting

1. Add `SpeedTestController.swift` from PR (no changes — it is a correct Hop port).
2. Add `SpeedTestQuickSetting.swift` from PR, add results surfacing:
   - After `controller.run()` completes, show an `NSPopover` anchored to the Quick Settings tile, or a `UNUserNotificationCenter` notification, showing: `↓ 234 Mbps  ↑ 45 Mbps  RPM: 890`.
   - Handle `failed` state with a toast/alert.
3. Register in `QuickSettingsManager.allSettings`.
4. **Build gate + manual test:** Tap tile, wait ~15s, verify results displayed.
5. Commit: `feat(quick-settings): add Speed Test via networkQuality with results popover`

---

### Phase 3 — Widget Location Switching (Dock ↔ Menu Bar)

Apply PR changes in this order, skipping the two `🚫 Reject` files:

1. **`TaskbarSettings.swift`** — `WidgetLocation` enum + 3 `@Published` properties (from PR, verbatim).
2. **`TaskbarContentView.swift`** — promote `clusterDivider` to ivar, Combine sinks to hide/show dock widgets, gate all 4 `preferredContentWidth()` calls (from PR, verbatim — fixes real `clusterDivider` ivar bug).
3. **`AppDelegate.swift`** — 2 new `NSStatusItem` ivars + Combine sinks for menu-bar widget placement (from PR, verbatim).
4. **`TaskbarElementsTab.swift`** — 3 `Picker` controls for widget location (from PR, verbatim).
5. **`release_refined.sh`** — **DO NOT apply PR change.** Instead, update with `VERSION=$1` parameter.
6. **`release_notes.md`** — **DO NOT apply PR change.** Write fresh notes for actual version.
7. **Build gate + manual test:** Move System Resources to menu bar → verify it leaves dock, appears in menu bar. Move back → verify reverse. Open flyout from menu-bar position. Confirm no ghost views.
8. Commit: `feat(widgets): Dock ↔ Menu Bar location switching for Connectivity Tray and System Resources`

---

### Phase 4 — Polish & Release v1.10.0

1. Parameterize `release_refined.sh` (accept `VERSION` and `NOTES` args).
2. Write release notes for v1.10.0 covering all three new features.
3. `swift build -c release`, package DMG with `hdiutil`, tag and push `v1.10.0`.
4. Run fresh-install reset sequence:
   ```bash
   tccutil reset Accessibility com.dockbar.app
   tccutil reset ScreenCapture com.dockbar.app
   defaults delete com.dockbar.app 2>/dev/null || true
   ```
5. Download DMG from GitHub release, do clean onboarding test.

---

**STOP — awaiting review and approval before any code changes.**
