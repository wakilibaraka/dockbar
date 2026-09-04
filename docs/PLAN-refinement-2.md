# DeskBar Refinement & Consolidation Plan 2

## STANDING RULE
**Additive variants, never silent replacement.** All requested changes to existing UI or behaviors will be added as options/variants (with the new request set as default). The old behavior will remain selectable so the user can easily revert. "Diagnose before deleting" applies everywhere.

## Context: Previous Landing Verification
- **Universal Search**: The `StartMenuWindowController` was rewritten to support local apps, files (`NSMetadataQuery`), and web fallback. However, file search isn't populating (see #2 below).
- **Command-tap Toggle**: A solitary command-tap handler was added to `TaskbarContentView`, but it clashes with an existing implementation (see #1 below).
- **Flyout Unification**: `SystemResourceFlyoutPanel` and `StartMenuWindowController` were updated to `.popover` and 16pt corners. `QuickSettingsFlyoutPanel` and `CalendarFlyoutPanel` were also updated.
- **Permissions UX**: Added a first-run prompt and a "Permissions" dashboard in `SettingsView`.
- **Winstrix Rename**: Renamed to "Floating (Windows-Style)".
- **System Stats Mode**: Added `.flyout` and `.inline` settings, successfully tested.
- **Task Click Behavior**: Added `FrontmostAppClickBehavior.minimize`, tested and working.

---

## Part 1: Core Investigation & Fixes

### 1. Start button + Command-tap Flakiness
**Finding**: There are indeed **two** competing Command-tap handlers. 
- One is in `WindowSwitcherService.swift` (lines 332-350) which uses `BareCommandShortcutDetector` and a low-level `CGEventTap` to monitor `.flagsChanged`. 
- The other was recently added in `TaskbarContentView.swift` (lines 118-129) via a local/global event monitor.
Because both fire simultaneously, the `StartMenuWindowController.toggle()` gets called twice, immediately opening and closing the menu.
**Plan**: Remove the duplicate handler in `TaskbarContentView.swift`. Rely entirely on the existing `BareCommandShortcutDetector` and `CGEventTap` in `WindowSwitcherService.swift` which is far more robust (handles timeouts, swallows, and key combinations gracefully).

### 2. Search "not working at all"
**Finding**: `NSMetadataQuery` is incorrectly implemented in `StartMenuWindowController.swift`. In `performSearch(query:)`, the query is stopped and restarted on every single keystroke (`stopQuery()` followed by `startFileSearch()`). Because `NSMetadataQuery` operates asynchronously in phases (gathering vs updating), restarting it constantly means it never reaches the `NSMetadataQueryDidFinishGathering` phase. Additionally, the predicate uses `NSMetadataItemContentTypeTreeKey` instead of `kMDItemContentType` or similar, which might be malformed.
**Plan**: 
- Initialize `NSMetadataQuery` once. 
- Only update its `predicate` when the search text changes, instead of recreating it.
- Throttle/debounce the search text input so we don't thrash the query.
- Use a safe predicate: `kMDItemFSName == *query*`.

### 3. Start vs Search (Distinct Surfaces)
**Finding**: Currently, both buttons open the `StartMenuWindowController`.
**Plan**: 
- **Start Button**: Opens the App Launcher view (Apps list prioritized).
- **Search Button**: Opens the same window, but auto-focuses the search field and defaults the list to an empty state or recent files, explicitly signaling "Spotlight-style search". 
- We will add a `mode` parameter to `StartMenuWindowController.toggle(mode: .start | .search)` to adjust the initial UI state (placeholder text, list priorities) while sharing the same backend.

### 4. Flyout Positioning & Anchoring
**Finding**: Flyouts currently hardcode their coordinates (e.g., `StartMenuWindowController` uses `NSScreen.main.frame.minX + 12`, `y = 60`). `QuickSettings` uses the button's screen origin but doesn't handle multiple displays well.
**Plan**: Create a shared `FlyoutAnchorHelper`. It will take the trigger button's screen frame (`button.window.convertToScreen`), add a consistent 8pt gap above the taskbar, and clamp the resulting `NSWindow` frame to the bounds of the screen containing the taskbar. All flyouts (Start, QuickSettings, Stats, Calendar) will adopt this.

### 5. Start Menu Outside-Click Dismissal
**Finding**: `StartMenuWindowController` uses `NSEvent.addGlobalMonitorForEvents` to detect outside clicks. Global monitors *only* fire for events sent to *other* applications. Clicking on the taskbar (which is part of the DeskBar app) does not trigger it.
**Plan**: Add an additional `NSEvent.addLocalMonitorForEvents` for clicks within the DeskBar app but outside the Start Menu's bounds. Or, more simply, implement `windowDidResignKey` to close the menu automatically.

### 6. "Floating (Windows-Style)" Liquid-Glass Look
**Finding**: Native macOS `NSVisualEffectView` materials like `.hudWindow` or `.popover` are quite flat. True "Liquid Glass" (like VisionOS) requires custom layering.
**Plan**: Update the Floating layout mode to use a layered approach:
- Background: `NSVisualEffectView` (material `.popover`, blending `.behindWindow`).
- Middle: A translucent `CALayer` with a slight white/gray tint.
- Border: A 1px inner border using `CAGradientLayer` (white at top, clear at bottom) for a specular highlight.
- Shadow: Soft drop shadow.
- *Standing Rule*: Make this the default for "Floating", but keep the old flat transparent look as a selectable "Floating (Flat)" variant.

### 7. Running-App Appearance Variants
**Finding**: The task titles will remain exactly as they are. In `TaskButtonView.swift`, the current active window indicator is a full accent-color background fill (`layer?.backgroundColor = NSColor.controlAccentColor...`).
**Plan**: Add a `RunningIndicatorStyle` setting (Background Fill, Underline, Dot, Tint). 
- **Background Fill**: (Old behavior, preserved).
- **Underline**: A 2px high strip at the bottom of the button (Windows 11 style).
- **Dot**: A small dot beneath the app icon (macOS style).
- We'll update `TaskButtonView.updateBackgroundColor()` to respect this setting.

### 8. Bottom-Right Tray Apps Click Behavior
**Finding**: `TrayIconView.swift` currently handles clicks via `mouseDown` but only processes `Control`-clicks to show the context menu. Left clicks do nothing.
**Plan**: 
- **Left-Click**: Add `application.activate(options: .activateIgnoringOtherApps)` to bring the app to the front.
- **Right-Click**: Expand the context menu to include `Hide`, `Quit`, and `Unpin`, matching `TaskButtonView`.

### 9. Quick Settings Distinct Icon
**Finding**: `QuickSettingsButtonView.swift` uses `gearshape.fill`.
**Plan**: Change the SF Symbol to `switch.2` or `slider.horizontal.3` so it reads as "Control Center / Toggles" rather than "System Settings".

### 10. Menu-Bar Status Item (Redesign & Function)
**Finding**: DeskBar has a basic `NSStatusItem` in `AppDelegate.swift` showing a gear icon with just "Settings", "Restore", and "Quit".
**Plan**: 
- Change the icon to a custom deskbar glyph (e.g., `menubar.dock.rectangle.badge.record`).
- Rebuild the menu into a "Control Center". We'll host the existing `QuickSetting`s (Dark Mode, Mute, Keep Awake, etc.) directly in the menu using `NSMenuItem` wrappers.
- Add a setting: `Show toggles in: Taskbar | Menu Bar | Both` to reduce bottom-right taskbar clutter.

---

## Part 2: Addendum Investigations

### 12. Settings Audit (UI & Appearance)
**Findings**:
- **Clock click app (Broken)**: `EnhancedClockWidgetView.swift` (lines 306-309) hardcodes a check for `calendar366://` and attempts to open it *before* falling back to AppleScript with `settings.clockTargetApp`. **Fix**: Remove the hardcoded `calendar366://`. Use `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` or `NSWorkspace.shared.launchApplication()`.
- **Show SM Widget vs Show System Resource Widget**: They are *not* duplicates. "SM Widget" belongs to the Session Manager plugin (terminal agents, etc.), whereas the "System Resource Widget" is the CPU/RAM stats. **Fix**: Rename "SM Widget" to "Terminal Agents Widget" for clarity.
- **Taskbar height / Title font size / Max task width**: Wired to `TaskbarPanel` and `TaskButtonView`. Functioning correctly.
- **Thumbnail size**: Wired to `ThumbnailPopover`. Functioning correctly.

### 13. Calendar Flyout (Month Grid + Events)
**Finding**: `CalendarFlyoutPanel` currently renders a simple vertical `NSStackView` of today's events.
**Plan**: 
- Build a new `MonthCalendarView` (a grid of 7x6 days) calculating dates via `Calendar.current`. 
- Bind it to `CalendarEventService` to overlay colored dots on days with events.
- Below the grid, list the events for the *selected* day.
- *Standing Rule*: Make the Month Grid the default, but keep the "Simple List" as a selectable layout mode in Settings.

### 14. Menu-Bar Control Center
(Covered in Item 10 above. Integrating OnlySwitch-style toggles directly into the `NSStatusItem` menu alongside "Restore Windows From Last Sleep" and "Quit").

### 15. CMD+Z "Reopen Closed App"
**Finding**: `RecentlyQuitAppsService` currently tracks the last 10 closed apps and uses a global `NSEvent.addGlobalMonitorForEvents` to listen for `⌥⌘T`. 
**Plan**: 
- Keep `⌥⌘T` as the primary, safe global shortcut (since intercepting `CMD+Z` globally via `CGEventTap` runs a high risk of breaking native Undo in active apps like Xcode, Pages, or Photoshop).
- Add the "Recently Quit Apps" list to the new Menu-Bar Status Item (Item 14).
- Add an *optional* `CMD+Z` global override setting via `CGEventTap`, but default it to OFF with a warning about Undo conflicts.

### 16. RAM% Tray Indicator (Opens Stats Flyout)
**Finding**: The stats widget uses `SystemResourceWidgetView`. It can be shown inline (all stats) or as a compact button ("SYS" or chart icon).
**Plan**: 
- Create a new `SystemResourceMetric.ramPercentage` setting. 
- When the widget is collapsed (Flyout mode), allow the button to display live text (e.g., `RAM 64%`) instead of a static icon, powered by the existing `SystemResourceMonitor`.
- This ensures no duplicate widgets—it's just a style upgrade to the existing Stats button in the tray.

---

## Summary of Action Plan
1. Consolidate Command-tap to `WindowSwitcherService`.
2. Fix `NSMetadataQuery` state management so file search works.
3. Differentiate Start vs Search entry points visually.
4. Implement `FlyoutAnchorHelper` for pixel-perfect positioning.
5. Fix Start Menu dismissal with local monitors / key window resign.
6. Build Liquid Glass layout variant (keeping flat as an option).
7. Add Running-App Indicator variants (Background, Dot, Underline) for the taskbar.
8. Add left-click activation and right-click menu to Tray apps.
9. Change Quick Settings icon to `switch.2`.
10. Build the Menu-Bar Control Center (OnlySwitch style) with the Recently Quit Apps list.
11. Audit and clarify Settings (fix clock click, rename SM widget).
12. Build the Month Grid UI for the Calendar flyout.
13. Add live RAM% text option to the collapsed Stats button.

## Open Questions for User
1. **CMD+Z vs ⌥⌘T**: As noted, stealing CMD+Z globally will break native Undo in almost every Mac app. Are you okay with keeping ⌥⌘T as the primary global shortcut, and exposing the list in the Menu-Bar icon for mouse access?
2. **Search Button**: Should the Search button be a physical icon next to Start, or just a floating text field that expands when clicked?
3. **Calendar Month View**: Do you want week numbers shown on the side of the month grid, or just the standard 7-day columns?
