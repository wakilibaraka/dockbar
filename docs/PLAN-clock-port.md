# DeskBar — Plan: Colourful, Event-Aware Clock/Tray Widget

> **Status:** Investigation & planning only. No source files modified.
> **Date:** 2026-09-04

---

## Part 1 — Root-Cause Analysis of the Clock Glitch

### Observed symptom
The right tray renders the orange "Accessibility permission required" banner **on top of / instead of** the clock. Clock flickers or fails to appear.

### Layout architecture (code facts)

`TaskbarContentView` builds a vertical `rootStackView` with two arranged rows
(TaskbarContentView.swift L320–430):

```
rootStackView (vertical, .fill)
├── bannerButton          ← 32pt tall; hidden when AX is granted (L680)
└── zonesStackView        ← the actual taskbar row
    ├── launcherZoneView
    ├── taskZoneContainer
    ├── sessionManagerWidgetView (optional)
    ├── systemResourceWidgetView
    ├── runningAppTrayView
    └── clockWidgetView   ← rightmost arranged subview (L429)
```

The `bannerButton` is the **first arranged subview** of `rootStackView`, with a hard height constraint of 32 pt (L351):

```swift
bannerButton.heightAnchor.constraint(equalToConstant: 32)
```

`zonesStackView` is the second arranged subview. Because `rootStackView` is `.fill` distributed vertically, when the banner is **visible** the stack allocates 32 pt to the banner and the remainder to `zonesStackView`. **If the panel's total height is set to exactly 32 pt** (which `TaskbarPanel` typically enforces for a compact taskbar), `zonesStackView` gets 0 pt, collapsing everything inside it — including the clock.

### Root Cause #1 — Fixed-height panel collapses `zonesStackView` when banner is shown ★ PRIMARY

- `TaskbarPanel` constrains the window/panel to a fixed content height (confirmed by `minimumZoneContentHeight = 32` at TaskbarContentView.swift L36).
- When the banner is visible it consumes the entire vertical space, leaving `zonesStackView` with zero height.
- All subviews of `zonesStackView` — including `clockWidgetView` — are invisible because their layout height resolves to 0.
- The banner `isHidden` flag is set inside `rebuildTaskZone()` (L680), which is called many times (8 call sites across the file). Each call checks `permissionsManager.isAccessibilityGranted`. If that status is initially `false` before the first AX check completes, the banner is shown, the clock disappears, and then when AX is confirmed the banner hides — this is the "flicker."

### Root Cause #2 — Banner visibility toggled inside `rebuildTaskZone()` on every window event (SECONDARY / flicker)

- Every window update triggers a full zone rebuild during startup, toggling the banner repeatedly and causing layout thrash that makes the clock appear to flicker.
- Fix: bind `bannerButton.isHidden` directly to a `PermissionsManager.$isAccessibilityGranted` publisher in `bindState()`, not inside `rebuildTaskZone()`.

### Root Cause #3 — Per-second timer (minor, NOT the main cause)

`ClockWidgetView` fires a `Timer` every 1 second (ClockWidgetView.swift L29). However, the update method guards against no-op changes (L71–77) by checking `stringValue !=` before assigning, so it does NOT force a full relayout every tick. Not the primary cause.

### Root Cause #4 — No AX coupling (confirmed non-issue)

`ClockWidgetView` has zero dependency on Accessibility permissions — it only uses `DateFormatter`, `Timer`, `NSTextField`, and `NSWorkspace.open(URL)`. It is NOT gated behind AX. The overlap is purely a layout/height issue.

### Verdict

| # | Cause | Responsible? |
|---|-------|-------------|
| 1 | Banner + panel fixed height collapses `zonesStackView` | ✅ PRIMARY |
| 2 | Banner toggled inside `rebuildTaskZone()` on every window event | ✅ SECONDARY (flicker) |
| 3 | Per-second timer forcing full relayout | ❌ Not a cause |
| 4 | Clock depends on AX permission | ❌ Not a cause |

---

## Part 2 — Assessment of `lawand-dot-io/taskbar`

**Honest finding:** The `lawand-dot-io/taskbar` repository is essentially **100% HTML/CSS/JavaScript**. It is a web-based mockup / landing page demonstrating what a Windows-style taskbar might look like in a browser. There is no native macOS Swift code, no AppKit widgets, no `NSView` or `NSPanel` subclasses, and no `Timer`-based clock.

**What is portable:** Only the *design intent and interaction model*:
- Clock format: two-line `HH:mm` / `dd/MM/yyyy` right-aligned in the tray (already implemented)
- Click behavior: clock opens a calendar/agenda flyout
- Colourful tray accent: tinted pill/button style for system-status tray widgets

**Recommendation:** Port the *design philosophy* into a clean native AppKit implementation. No Swift code to copy from this repo.

---

## Part 3 — Proposed Replacement Widget Design

### 3.1 Layout Fix (must ship first)

**Problem:** The `bannerButton` and `zonesStackView` share vertical space of a fixed-height panel.

**Fix plan (two options — pick one):**

**Option A (Preferred — Overlay):**
- Remove `bannerButton` from `rootStackView`'s arranged subviews.
- Add it as a regular subview of `TaskbarContentView` with constraints: pin to top, leading, trailing; fixed height 32 pt.
- Give `zonesStackView` a top inset of 32 pt when banner is visible, 0 when hidden.
- `zonesStackView` always gets the full panel height minus the inset.

**Option B (Simpler — Dynamic panel height):**
- Bind `TaskbarPanel`'s content height to `PermissionsManager.$isAccessibilityGranted`.
- When AX is denied: height = 32 (taskbar) + 32 (banner) = 64 pt.
- When AX granted: height = 32 pt (normal).

**Both options also require:** Bind `bannerButton.isHidden` directly to `PermissionsManager.$isAccessibilityGranted` publisher (in `bindState()` rather than `rebuildTaskZone()`).

### 3.2 New Clock Widget — `EnhancedClockWidgetView`

Replace `ClockWidgetView` with `EnhancedClockWidgetView` — drop-in upgrade, additive and toggle-controlled.

#### Colourful Theming

Add `clockTheme` setting (enum) to `TaskbarSettings`:

```swift
enum ClockTheme: String, CaseIterable {
    case none        // white text on dark-glass (current behavior, default)
    case ocean       // teal/cyan gradient
    case violet      // purple/indigo gradient
    case sunset      // orange/pink gradient
}
```

**Implementation:**
- `wantsLayer = true`; add a `CAGradientLayer` sublayer.
- Layer is transparent for `.none`, shows a subtle pill-shaped gradient for named themes.
- Text colours automatically invert based on `NSApp.effectiveAppearance`.
- Gradient: left→right, 60% opacity over dark-glass — readable at all sizes.
- Exposed in **Settings → Tray Widgets → Clock Theme** as a segmented control.

#### EventKit Integration

**New file:** `Sources/DeskBar/Services/CalendarEventService.swift`

Responsibilities:
- Holds a shared `EKEventStore`.
- On first use: `EKEventStore.requestFullAccessToEvents(completion:)` (macOS 14+).
- Publishes `@Published var upcomingEvents: [EKEvent]` — refreshed every 5 minutes + on `EKEventStoreChanged` notification.
- Fetches today + next 7 days from the user's default calendar set.
- Gracefully handles `.denied` / `.restricted` by publishing empty array + `permissionDenied: Bool` flag.

**`Info.plist` key required:**
```xml
<key>NSCalendarsUsageDescription</key>
<string>DeskBar uses your calendar to show upcoming events in the clock widget.</string>
```

**Clock widget display:**
- Line 1: `HH:mm` (bold, larger)
- Line 2: `dd/MM/yyyy` (regular, smaller)
- Line 3 (new, optional): `• Standup in 12m` — next event title (truncated 20 chars) + time-until. Hidden if no events or `showClockEvents` toggle OFF.

#### Click Behavior (Recommended)

- **Left-click:** Open lightweight `CalendarFlyoutPanel` (new `NSPanel`) anchored above the clock, listing today's events. Dismisses on outside click.
- **Right-click:** Launch Calendar 366 II via `calendar366://` scheme + bundle-name AppleScript fallback (existing path).

This gives "quick glance" (no context switch) on left-click and "full app" on right-click.

#### Agenda Flyout Panel Layout

```
┌────────────────────────────────┐
│  Today · Thu 04 Sep            │
│  ──────────────────────────    │
│  🟦 09:00  Team Standup        │
│  🟩 11:30  1:1 with Alex       │
│  🟥 14:00  Sprint Review       │
│  ──────────────────────────    │
│  No more events today           │
└────────────────────────────────┘
```

Width: ~300 pt. Anchored bottom-right corner above clock widget, 4 pt gap.

#### Tray Order (right side, left → right)

```
[systemResourceWidget] [runningAppTray] [quickSettingsButton*] [clock]
```

*`quickSettingsButton` from the Quick Settings plan (see PLAN-quicksettings-calendar.md). Clock stays rightmost, matching Windows convention.

Gap: `zonesStackView.setCustomSpacing(6, after: quickSettingsButtonView)`.

### 3.3 New Files / Services

| File | Responsibility |
|------|----------------|
| `Sources/DeskBar/Services/CalendarEventService.swift` | `EKEventStore` wrapper, `@Published upcomingEvents`, permission gating |
| `Sources/DeskBar/Views/EnhancedClockWidgetView.swift` | Replaces `ClockWidgetView`; 3-line display, `CAGradientLayer` theming, click routing |
| `Sources/DeskBar/Views/CalendarFlyoutPanel.swift` | `NSPanel` agenda list, today's events, anchored above clock |
| `Sources/DeskBar/Models/ClockTheme.swift` | `enum ClockTheme`, gradient colour pairs |

Existing files modified minimally:
- `TaskbarSettings.swift` — add `clockTheme: ClockTheme`, `showClockEvents: Bool`
- `TaskbarContentView.swift` — swap `ClockWidgetView` → `EnhancedClockWidgetView`, inject `CalendarEventService`, fix banner layout
- `Info.plist` — add `NSCalendarsUsageDescription`
- `SettingsView.swift` — add clock theme and events toggles

### 3.4 Settings Entries

**Settings → Tray Widgets:**

| Setting | Type | Default |
|---------|------|---------|
| Show clock | Toggle (existing) | OFF |
| Clock theme | Segmented: None / Ocean / Violet / Sunset | None |
| Show next event in clock | Toggle | OFF |
| Click opens | Segmented: "App" / "Agenda" / "Agenda+App" | Agenda+App |
| Calendar click app | Text field (existing `clockTargetApp`) | Calendar 366 II |

### 3.5 Implementation Order

1. **Layout fix (blocking):** Decouple banner from `zonesStackView` height + bind directly to `PermissionsManager` publisher.
2. **Timer optimisation:** Fire every 10 s; update labels only when the minute/date string changes.
3. **`EnhancedClockWidgetView`** with theming but without EventKit (safe first deploy).
4. **`CalendarEventService`** — implement, add plist key, wire into settings toggle.
5. **`CalendarFlyoutPanel`** — agenda panel on left-click.
6. **Polish:** per-calendar colour dots, flyout animation.

---

## Open Questions

1. **Banner fix approach:** Option A (overlay, cleaner) vs Option B (dynamic panel height, simpler)? Preference?

2. **EventKit calendar scope:** Fetch from *all* calendars, or let the user select? All calendars is simpler for v1.

3. **Agenda flyout depth:** Minimal flat list (proposed), or add a mini month view at top for a future iteration?

4. **Clock theme default:** Stay "None" (current white text) or default to "Ocean" for visual flair?

5. **`EnhancedClockWidgetView` width:** With 3 lines, 60 pt is too narrow (~90 pt needed). Should the widget self-size (requires updating 4 measurement loop sites in `TaskbarContentView`) or use a fixed wider constant?
