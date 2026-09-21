# Dock Layout Instability — Phase 0 Investigation

**Scope:** v1.9.2 (`7cd3769`). Phase 1–4 fix plan at the bottom.

---

## 1. Zone Architecture and Width Computation

### Zone Layout (left → right in `zonesStackView`, an `NSStackView`)

```
zonesStackView
  ├── launcherZoneView        (Launchpick / app-launcher icon)
  ├── taskZoneContainer       (NSView with constraint: taskZoneContainerWidthConstraint)
  │     ├── leftTaskZoneStackView
  │     ├── leftTaskZoneSeparatorView
  │     ├── neutralTaskZoneStackView
  │     ├── rightTaskZoneSeparatorView
  │     └── rightTaskZoneStackView
  ├── clusterDivider          (a thin separator NSView)
  ├── connectivityTrayView    (CalendarTrayButton + Quick Settings popover)
  └── systemResourceWidgetView
```

The panel (`TaskbarPanel`) spans the full screen width. In compact modes
(`compact` / `compactGlass`) it shrinks to fit content; in full-width modes
it fills the screen.

### Width Computation Paths

Three independent functions compute "how wide is fixed content" — the same
expression duplicated four times (lines 180, 1607, 1623, 1653, 1662):

```swift
launcherZoneView.preferredContentWidth() +
(settings.systemResourceWidgetLocation == .dock ? systemResourceWidgetView.preferredContentWidth() : 0) +
(settings.connectivityTrayLocation == .dock     ? connectivityTrayView.preferredContentWidth()     : 0) + 1 +
zoneEdgeInsetsWidth(...)
```

**`preferredCompactWidth()`** (line 173) — called by `TaskbarPanel.updateChromeLayout()`
to size the glass pill. Calls `layoutSubtreeIfNeeded()` synchronously before
measuring (line 174). Returns the ideal content width.

**`applyResponsiveWidthCaps()`** (line 1598) — called by `viewWillDraw` →
`applyResponsiveWidthCapsNowOrSchedule()`. Decides whether to switch to
adaptive (compressed) task-button widths, and updates
`taskZoneContainerWidthConstraint`. If layout state changes it may call
`schedulePreferredWidthNotification()`.

**`TaskbarWidthPlanner.uniformWidthCap()`** — stateless utility; takes the
fixed width + task items, returns the per-button uniform width cap.

---

## 2. The Feedback Loop (Root Cause of Oscillation)

### The Chain on Widget Location Toggle

When the user moves a widget between Dock and Menu Bar the Combine sink fires
immediately:

```
settings.$connectivityTrayLocation publisher fires
  → connectivityTrayView.isHidden = (location != .dock)     [line 412]
  → updateClusterDividerVisibility()                         [line 413]
  → scheduleRebuildTaskZone()                                [line 414]
```

`scheduleRebuildTaskZone()` posts to `DispatchQueue.main.async`; when it
fires it calls `rebuildTaskZone()` → `schedulePreferredWidthNotification()`.

`schedulePreferredWidthNotification()` also posts `DispatchQueue.main.async`.
When *that* fires:

```
preferredCompactWidth()
  → layoutSubtreeIfNeeded()              ← FORCES SYNCHRONOUS RELAYOUT
  → reads systemResourceWidgetView.preferredContentWidth()
  → reads connectivityTrayView.preferredContentWidth()
```

`preferredCompactWidth` reads `connectivityTrayView.preferredContentWidth()`
which returns `quickSettingsButton.fittingSize.width + 8`. But
`isHidden = true` does NOT zero out an NSStackView/NSView's `fittingSize`.
The view is laid out as if it still has content, so the measurement is WRONG.

**The hidden view still reports a non-zero `fittingSize` for one or more
runloop passes** because AppKit only zeroes the fitting size after the next
committed layout pass. The width check in `schedulePreferredWidthNotification`
(`abs(last - width) < 0.5`) succeeds, so `preferredWidthDidChange?()` fires
and `TaskbarPanel.requestLayoutUpdate()` → `updateFrameForCurrentState()` →
`updateChromeLayout()` → reads `preferredCompactWidth()` again (calling
`layoutSubtreeIfNeeded()` again mid-chrome-layout). This causes:

1. Chrome resizes to a width that includes the now-hidden widget.
2. The new chrome width triggers a bounds change → `layout()` override fires
   → `scheduleResponsiveWidthUpdate()` → next runloop: `applyResponsiveWidthCaps()`.
3. `applyResponsiveWidthCaps()` sees a different `contentWidth`, recomputes
   `usesAdaptiveTaskLayout`, may set `schedulePreferredWidthNotification()`
   again. If the result differs by ≥ 0.5 → another `preferredWidthDidChange?()`
   → loop restarts.

### Why `isHidden` Alone Is Not Enough

`NSStackView` ignores hidden arranged subviews in its layout pass, but:
- `fittingSize` of the *hidden view itself* is still cached until layout.
- The width formula in `preferredCompactWidth` guards on
  `settings.X == .dock` (the setting), NOT on `connectivityTrayView.isHidden`
  (the view). This guard is correct. **However**, `layoutSubtreeIfNeeded()`
  is called inside `preferredCompactWidth` — this forces AppKit to run a full
  subtree layout synchronously *in the middle of* the chrome-sizing call. If
  AppKit's layout engine decides the parent needs to be re-laid-out too, it
  triggers a recursive layout → oscillation.

### Secondary Source: `scheduleRebuildTaskZone()` on Every Location Toggle

The location sinks call `scheduleRebuildTaskZone()` (lines 414, 424). Rebuild
is needed for window grouping state, but it ALSO unconditionally calls
`schedulePreferredWidthNotification()` at the end (lines 698, 722). This
means every widget toggle fires at minimum TWO separate
`schedulePreferredWidthNotification` calls (one from the sink directly via the
rebuild, and another from `applyResponsiveWidthCaps` if layout state changed).

---

## 3. Calendar / `ConnectivityTrayView` Flicker

`CalendarTrayButton` has a 60-second `Timer` (line 57 of
`CalendarTrayButton.swift`) that calls `updateDate()` → `needsDisplay = true`.
This schedules a redraw, which triggers `viewWillDraw()` →
`applyResponsiveWidthCapsNowOrSchedule()`.

When `applyResponsiveWidthCaps()` runs during this redraw:
- It re-evaluates `usesAdaptiveTaskLayout`.
- If any of the last-applied cached values differ (e.g. because a prior
  toggle left the system in a transitional state), it sets new constraints and
  may call `schedulePreferredWidthNotification()` again.
- This fires `preferredWidthDidChange?()` → `requestLayoutUpdate(animated: false)`
  → `updateChromeLayout()` → reads `preferredCompactWidth()` →
  `layoutSubtreeIfNeeded()` synchronously.

**The timer fires `needsDisplay`, which pulls `preferredCompactWidth()` through
`viewWillDraw`, which calls `layoutSubtreeIfNeeded()`, which re-lays out the
`ConnectivityTrayView` → CalendarTrayButton visually redraws, potentially
resizing or re-rendering mid-frame → visible flicker.**

The `SystemResourceWidgetView.preferredWidthDidChange` callback (line 97 of
`SystemResourceWidgetView.swift`) also fires whenever the widget's width
changes (e.g. when CPU values change the label width). When wired in
`TaskbarContentView` (line 137–139) it calls both
`schedulePreferredWidthNotification()` AND `applyResponsiveWidthCapsNowOrSchedule()`
— a double-trigger on every CPU tick.

---

## 4. Proposed Deterministic Single-Pass Layout Model

### Core Principle

> **Measure once. Commit once. Never call `layoutSubtreeIfNeeded()` from
> inside a measurement function.**

### Specific Fixes

#### Fix A — Remove `layoutSubtreeIfNeeded()` from `preferredCompactWidth()`

`preferredCompactWidth()` (line 174) must NOT force a layout. The measurement
must read from already-committed layout state. The call should be removed.
The one caller that needs fresh layout state (`TaskbarPanel.updateChromeLayout`)
should call `layoutSubtreeIfNeeded()` on itself *before* asking for the width,
not the other way round.

#### Fix B — Location Sinks: Don't Trigger `scheduleRebuildTaskZone()`

Widget visibility changes do not change the set of task items — only the task
zone items change. The location sinks should:
1. Set `isHidden`.
2. Update `clusterDivider` visibility.
3. Call `schedulePreferredWidthNotification()` directly (width changed).
4. Call `applyResponsiveWidthCapsNowOrSchedule()` (budget changed).
5. NOT call `scheduleRebuildTaskZone()`.

`scheduleRebuildTaskZone()` will be called naturally when the window list
changes; there is no reason to rebuild on widget location change.

#### Fix C — Debounce `systemResourceWidgetView.preferredWidthDidChange`

The CPU-tick-driven width callback in `SystemResourceWidgetView` already fires
frequently. The wiring in `TaskbarContentView` (lines 137–139) calls both
`schedulePreferredWidthNotification()` and `applyResponsiveWidthCapsNowOrSchedule()`
— but `applyResponsiveWidthCapsNowOrSchedule()` is only needed if the capsule
layout state (adaptive vs. non-adaptive) actually changed. It should be
conditional: only call it if `usesAdaptiveTaskLayout` might flip. In practice,
a CPU tick won't flip adaptive mode; only a significant content change would.
**Remove the direct `applyResponsiveWidthCapsNowOrSchedule()` call from the
callback; leave only `schedulePreferredWidthNotification()`.**

#### Fix D — `normalizeFrame` Sets `needsLayout = true`

In `TaskbarPanel.normalizeFrame()` (line 283), `hostedView?.needsLayout = true`
is set AFTER `setFrame`. This triggers `layout()` → `scheduleResponsiveWidthUpdate()`
→ `applyResponsiveWidthCaps()` → potential `schedulePreferredWidthNotification()`
→ `preferredWidthDidChange?()` → `requestLayoutUpdate()` → loop. 

**Guard: `normalizeFrame` should set `needsLayout` only when the frame
actually changed,** which is already half-guarded by the equality check on
line 273, but `rootView.frame = rootFrame` on line 278 always fires. Remove
the `needsLayout = true` line (or add a change guard); the frame assignment
itself already causes AppKit to schedule a layout pass.

#### Fix E — Dedup the Fixed-Width Expression

The expression computing widget fixed widths is copy-pasted 5 times (lines
180, 1607, 1623, 1653, 1662). Extract it to a private computed property:

```swift
private var dockWidgetFixedWidth: CGFloat {
    (settings.systemResourceWidgetLocation == .dock ? systemResourceWidgetView.preferredContentWidth() : 0)
    + (settings.connectivityTrayLocation == .dock     ? connectivityTrayView.preferredContentWidth()    : 0)
    + 1  // clusterDivider spacer
}
```

This ensures any single correction propagates everywhere automatically.

---

## 5. Phase Plan

### Phase 1 — Deterministic Dock Layout (target: v1.9.3)
- **Files:** `TaskbarContentView.swift`, `TaskbarPanel.swift`
- Fix A: Remove `layoutSubtreeIfNeeded()` from `preferredCompactWidth()`.
- Fix B: Remove `scheduleRebuildTaskZone()` from location Combine sinks; replace
  with `schedulePreferredWidthNotification()` + direct `applyResponsiveWidthCapsNowOrSchedule()`.
- Fix C: Remove redundant `applyResponsiveWidthCapsNowOrSchedule()` from
  `systemResourceWidgetView.preferredWidthDidChange`.
- Fix D: Guard `normalizeFrame`'s `needsLayout = true` behind an actual
  content-change check.
- Fix E: Extract `dockWidgetFixedWidth` computed property.
- **Verification:** Repeatedly toggle each widget between Dock and Menu Bar
  while watching the dock width; confirm no oscillation and calendar doesn't
  flicker. Build gate: `swift build -c release` 0 errors. DMG: v1.9.3.

### Phase 2 — New Default Widget Locations (target: v1.9.4)
- **Files:** `TaskbarSettings.swift`
- Change defaults: Calendar (connectivityTray) → `.dock`; Battery → `.menuBar`;
  SystemResources → `.menuBar`.
- Migration: read saved user default; only apply new defaults if the user has
  not yet saved a preference for each key (use `UserDefaults.object(forKey:) == nil`
  guard, same pattern as existing keys). Never overwrite an existing value.
- **Verification:** Fresh install sees Calendar in dock, battery + sysres in
  menu bar. Existing users keep their choices unchanged. DMG: v1.9.4.

### Phase 3 — Hop Feature Flyouts (target: v1.9.5)
- **Files:** `KeyboardLockFlyoutView.swift` (new), `SpeedTestFlyoutView.swift`
  (new), `ConnectivityTrayView.swift`, `KeyboardLockQuickSetting.swift`,
  `SpeedTestQuickSetting.swift`.
- Speed Test: replace `UNUserNotificationCenter` result with a popover showing
  live ↓/↑ Mbps bars, last result, and a Run button.
- Keyboard Lock: a thin status banner or popover (shown when locked) with an
  "Unlock" button and countdown timer remaining.
- Both surface from the QuickSettings popover tile long-press or secondary
  click. No new toolbar items needed.
- **Verification:** Speed test result appears inline. Keyboard lock indicator
  visible. DMG: v1.9.5.

### Phase 4 — Settings UI Expansion (target: v1.9.6)
- **Files:** `Settings/*.swift`
- Enlarge the settings window (suggest 1100 × 860).
- New/expanded tabs:
  1. General (existing)
  2. Dock Behavior (existing, expanded)
  3. Elements / Widgets (existing — add Calendar and Battery location pickers)
  4. Flyouts (existing)
  5. Quick Settings (new — enable/disable each Quick Setting; Hop settings)
  6. Hold-to-Quit (existing content, promoted to its own tab)
  7. Connections/About (existing; rename)
- **Verification:** All tabs accessible and scrollable. No content clipping.
  DMG: v1.9.6.

---

## Appendix: Key File/Line Index

| Symbol | File | Line |
|--------|------|------|
| `preferredCompactWidth()` | `TaskbarContentView.swift` | 173 |
| `layoutSubtreeIfNeeded()` in `preferredCompactWidth` | `TaskbarContentView.swift` | 174 |
| `schedulePreferredWidthNotification()` | `TaskbarContentView.swift` | 809 |
| `connectivityTrayLocation` sink | `TaskbarContentView.swift` | 409 |
| `systemResourceWidgetLocation` sink | `TaskbarContentView.swift` | 418 |
| `systemResourceWidgetView.preferredWidthDidChange` wiring | `TaskbarContentView.swift` | 137 |
| `applyResponsiveWidthCaps()` | `TaskbarContentView.swift` | 1598 |
| `dockWidgetFixedWidth` (duplicated 5×) | `TaskbarContentView.swift` | 180, 1607, 1623, 1653, 1662 |
| `updateClusterDividerVisibility()` | `TaskbarContentView.swift` | 402 |
| `requestLayoutUpdate()` → `updateFrameForCurrentState()` | `TaskbarPanel.swift` | 110 |
| `updateChromeLayout()` → calls `preferredCompactWidth()` | `TaskbarPanel.swift` | 155 |
| `normalizeFrame()` → `needsLayout = true` | `TaskbarPanel.swift` | 283 |
| `CalendarTrayButton` 60 s timer | `CalendarTrayButton.swift` | 57 |
| `SystemResourceWidgetView.preferredWidthDidChange` fires | `SystemResourceWidgetView.swift` | 97 |
