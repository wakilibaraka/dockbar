# DockBar Widget & Dock Layout Architecture Investigation

## Part 1 — Defect Inventory by Mode

### Custom Mode
1. **Battery percentage (e.g., 80%) rendering as a translucent overlay overlapping the Calendar icon**
   - **Root Cause:** It is actually the `SystemResourceWidgetView` (which defaults to a translucent green/orange/red background with memory/CPU percentage). `SystemResourceWidgetView` overrides `intrinsicContentSize` but fails to set a strict `widthAnchor` constraint on itself. When the main `zonesStackView` compresses due to limited space, the widget's width squishes below its internal `containerView`'s fixed 44pt width. The internal view overflows its bounds, visually overlapping adjacent widgets like the Calendar.
   - **File/Line:** `Sources/DeskBar/Views/SystemResourceWidgetView.swift` (SetupUI lacks `widthAnchor` constraint on `self`).
2. **App labels with a stray leading bracket and terrible truncation (e.g. `[C...`)**
   - **Root Cause:** `TaskButtonView.displayTitle()` wraps the titles of minimized windows in brackets: `return "[\(resolvedTitle())]"`. When `NSStackView` compresses the label using `.byTruncatingTail`, the result becomes `[C...`. The user sees the bracket as a "stray" artifact rather than an intentional minimized state indicator.
   - **File/Line:** `Sources/DeskBar/Views/TaskButtonView.swift` (`displayTitle()` method).
3. **Stray green "OFF" badge on the Calendar widget**
   - **Root Cause:** The reported "Calendar widget" is actually a pinned `TaskButtonView` for the Apple Calendar app. The `TaskButtonView` includes a `pluginActionButton` (used for the Session Manager plugin) which has a default `activityColor` of `.systemGreen`. Its default title is `"sm"`. Due to small fonts and rendering, the green `"sm"` badge is easily misread as `"OFF"` (s -> O, m -> FF) by users. 
   - **File/Line:** `Sources/DeskBar/Views/TaskButtonView.swift` (`updateTaskButtonPluginActionButton()` where title is `"sm"`).
4. **Inconsistent running/active indicators**
   - **Root Cause:** State synchronization delays between `AppRuntimeState`, `BadgeMonitor`, and `TaskButtonView`. The `isFocused` and `running` states are calculated asynchronously, and some pinned apps miss the notification that they have launched, leaving the dot absent.
5. **Cramped spacing & Dead space bottom-right**
   - **Root Cause:** `TaskbarContentView` has a hardcoded layout loop that sets `zonesStackView.setCustomSpacing(fixedWidgetSpacing, after: view)` manually, fighting against the stack view's native distribution. Furthermore, `taskZoneContainer` has a `.defaultLow` hugging priority, causing it to push all trailing widgets far to the right, or leaving dead space if the widgets don't expand.

### Windows Mode
1. **App labels over-truncated (1-2 chars) + stray bracket**
   - **Root Cause:** Same as Custom mode (minimized windows get `[...]`, and tight horizontal stack compression forces tail truncation to `[C...`).
2. **Widgets scattered along the bar instead of merged Windows tray cluster**
   - **Root Cause:** In `WindowsTaskbarStrategy.applyDockWidgetOrder()`, widgets are added to `windowsTrayClusterView` using `tray.addWidget(view)`. However, `WindowsTrayClusterView` is a custom stack view whose constraints and hugging priorities do not enforce a rigid, grouped bounding box. As a result, the parent `zonesStackView`'s `.fill` distribution pulls them apart, scattering them across the available trailing space.
   - **File/Line:** `Sources/DeskBar/Models/TaskbarLayoutStrategy.swift` (`WindowsTaskbarStrategy`).
3. **Calendar shows stale date**
   - **Root Cause:** `CalendarTrayButton` relies on a `Timer.scheduledTimer(withTimeInterval: 60, repeats: true)` created on the default run loop. If the UI thread is busy or the user leaves the computer, the timer can drift or fail to tick exactly at midnight, leaving yesterday's date until the app is restarted.
   - **File/Line:** `Sources/DeskBar/Views/CalendarTrayButton.swift` (Timer logic).

### Mac Mode
1. **Widgets still rendered in the dock's right side instead of moving to macOS menu bar**
   - **Root Cause:** When the user explicitly overrides a widget's location via settings (e.g., `defaults write com.dockbar.app calendarLocation -string "dock"`), `TaskbarContentView`'s initialization flow can sometimes re-inject widgets into the `zonesStackView` *after* `MacTaskbarStrategy` has called `removeFromSuperview()`. Additionally, dynamic mode switching without an app restart fails to re-parent the widgets from the NSStatusItem back to the dock or vice versa.

---

## Part 2 — The Current Architecture (State of `main`)

Currently, `TaskbarContentView` acts as a monolithic manager for all widgets and app buttons. It constructs a primary `zonesStackView` and attempts to delegate layout to a `TaskbarLayoutStrategy` protocol (`CustomTaskbarStrategy`, `WindowsTaskbarStrategy`, `MacTaskbarStrategy`).

**The Conflict:**
`TaskbarContentView` retains hardcoded layout assumptions (e.g., iterating through `arrangedSubviews` to inject fixed spacing) that actively fight the strategies. When a strategy tries to group widgets (Windows Mode) or hide them (Mac Mode), `TaskbarContentView`'s post-processing often overrides or breaks those configurations. Furthermore, widget dimensions are inconsistently defined—some use strict `widthAnchor`s (`CalendarWidgetView`), while others rely on squishy `intrinsicContentSize` (`SystemResourceWidgetView`), leading to overlaps.

*Note on In-flight Work:* The `BorderlessFlyout` polish and settings revamp are actively migrating to a centralized model, but the core layout chassis still suffers from these constraint collisions.

---

## Part 3 — Proposed Widget Placement Logic

To support dynamic switching and stable positioning across all three modes, widget placement must be decoupled from `TaskbarContentView`'s internal view hierarchy hacks.

**Rules Engine for Placement:**
1. **Location Resolution:** Every widget must implement a protocol `DockWidget` that interrogates `TaskbarSettings.taskbarMode` and `TaskbarSettings.[widget]Location` to resolve its target destination: `.dockZone(trailing)`, `.windowsTrayCluster`, or `.menuBar`.
2. **Container Injection:** Instead of `TaskbarContentView` passing all views to the strategy, the Strategy should provide concrete **Slot Containers**. 
   - `MacMode`: Provides `NSStatusItem` containers.
   - `WindowsMode`: Provides a rigidly constrained `NSStackView` (Tray).
   - `CustomMode`: Provides the standard trailing `zonesStackView`.
3. **Lifecycle:** When the mode changes, widgets invoke `moveTo(container:)`, automatically removing themselves from their previous superview and applying the appropriate constraints for their new home.

---

## Part 4 — Target Architecture (Sizing, Readability, Sectioning)

**Sizing:**
- **Strict Anchors:** All widgets MUST have a `.required` `widthAnchor` constraint. No widget should rely on `intrinsicContentSize` for horizontal layout in a `.fill` distribution stack view. This guarantees stability and prevents overlaps (e.g., the System Resources overlap bug).
- **Height Matching:** All widgets enforce a strict 24pt or 32pt height anchor depending on the mode's compact setting, ensuring vertical alignment.

**Readability:**
- **Truncation Style:** Move away from `[...]` string interpolation for minimized windows. Use an opacity shift (e.g., `alpha = 0.6`) or a distinct border to indicate minimized state, keeping the title string clean (`Calendar` instead of `[C...`).
- **Badge Clarity:** Replace text-based `"sm"` badges with symbolic icons (e.g., a tiny gear or dot) to prevent users from misreading small text as `"OFF"`.

**Sectioning (Dock vs Menu Bar):**
- **Mac Mode:** The dock is strictly for App `TaskButtonView`s. All widgets (`Weather`, `Calendar`, `SystemResources`) dynamically mount to `NSStatusItem`s in the global macOS Menu Bar. The cluster divider is hidden.
- **Windows Mode:** App `TaskButtonView`s cluster on the leading edge (or center-left). All widgets are injected into a *rigid* `WindowsTrayClusterView` with `.required` hugging priority, preventing the scatter effect.
- **Custom Mode:** App `TaskButtonView`s occupy the center flexible zone. Widgets occupy the trailing zone, separated by a distinct visual divider line, with fixed spacing constraints rather than post-processed stack spacing.

---

## Part 5 — Migration Path

1. **Fix Constraint Leaks:** First, add strict `widthAnchor` constraints to `SystemResourceWidgetView` and replace the `"sm"` string in `TaskButtonView` with a symbol to eliminate the immediate visual bugs.
2. **Remove Hardcoded Spacing:** Delete the hardcoded `.setCustomSpacing` loops in `TaskbarContentView`. Move all spacing responsibilities into the respective `TaskbarLayoutStrategy` implementations.
3. **Decouple App Titles:** Refactor `TaskButtonView.displayTitle()` to return raw application names, moving state indicators (minimized/hidden) to purely visual properties (opacity, borders).
4. **Implement Container Slots:** Refactor `addOrderedDockWidgets()` so that widgets are explicitly assigned to containers provided by the active Strategy, rather than modifying the global stack view and hoping the strategy fixes it.

---

## Part 6 — Risks & Mitigations

- **Risk:** macOS Menu Bar API (`NSStatusItem`) limits custom view interactions, potentially breaking interactive flyouts for widgets when in Mac Mode.
  - *Mitigation:* Ensure `BorderlessFlyout` anchors correctly to `NSStatusItem.button.window` when rendering from the menu bar, bypassing AppKit's native popover restrictions.
- **Risk:** Strict `widthAnchor` constraints might clip localized text (e.g., if a date string in another language exceeds the fixed calendar width).
  - *Mitigation:* Combine `.required` minimum widths with `.defaultHigh` hugging priorities, allowing widgets to expand if their content requires it, while strictly preventing compression below their baseline.
- **Risk:** Dynamic mode switching leaves ghost widgets on screen.
  - *Mitigation:* Implement a centralized `WidgetRegistry` that tracks every active widget instance and forces a `removeFromSuperview()` sweep before transitioning to a new Strategy layout.
