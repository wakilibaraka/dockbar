# DeskBar — Plan: Appearance Overhaul

## 1. Summary

This document details the plan to implement a new "three-segment floating pills" taskbar layout and a rich Windows-11 style dashboard Start menu, following the established additive constraints.

## 2. A. Three-Pill Taskbar Layout

### Findings
Currently, `TaskbarPanel` manages a single `chromeShadowView` and `visualEffectView`. To support three independent pills (Start, Apps, System), the chrome drawing logic must be overhauled to draw three distinct `NSVisualEffectView` instances when in this new mode. 

### Implementation Plan
1. **New Layout Mode:** Add `.pills` to `DeskBarLayoutMode`.
2. **TaskbarPanel Refactor:**
    *   Instead of a single `visualEffectView` and `glassHighlightLayer`, maintain an array of 3 `NSVisualEffectView` (and shadow/highlight) layers.
    *   `TaskbarContentView` (which lays out the icons) currently uses one `zonesStackView`. It will need a way to communicate the bounding boxes of its 3 logical clusters (Left/Start, Center/Apps, Right/System) to `TaskbarPanel`.
    *   *Mechanism:* Add a protocol `ChromeGeometryProvider` that `TaskbarContentView` conforms to, returning an array of `NSRect`s for the chrome backgrounds.
    *   *Overflow/Multi-display:* The center pill will shrink via standard AutoLayout compression resistance on the app icons, while Start/System pills retain their intrinsic widths. `FlyoutAnchorHelper` will continue to work since it positions relative to the trigger button's screen coordinates, unaffected by the disjoint background.
3. **Settings:** Add "Floating (Pills)" to the layout dropdown.

## 3. B. Full Dashboard Start Menu

### Findings
`StartMenuWindowController` is currently a simple `NSTableView` with a search field.

### Implementation Plan
1. **Structure:** Transform `StartMenuWindowController`'s view hierarchy. Keep the Search field at the top. Below it, add an `NSSplitView` or a horizontal `NSStackView` to divide the menu into:
    *   **Left (Widgets):** Weather, Calendar, Sticky Notes.
    *   **Center (Dashboard):** A vertical stack containing the Pinned Grid (a custom `NSCollectionView`), followed by a "Recents" section.
    *   **Right (Rail):** User Profile, Folder Shortcuts, Power Controls.
2. **Pinned Grid / All Apps:**
    *   Create a simple grid for pinned apps.
    *   Add an "All Apps" button that swaps the Center pane to the existing alphabetical `NSTableView`.
    *   Persistence: Store pinned app bundle IDs in `UserDefaults`.
3. **Right Rail:**
    *   *Profile:* Retrieve current user name via `NSUserName()` and image via `CBIdentity`.
    *   *Shortcuts:* Open standard `FileManager` directories (Documents, Downloads, etc.) via `NSWorkspace.shared.open()`.
    *   *Power Controls:* Sleep, Restart, Shut Down, Lock.
4. **Recents:**
    *   Use `NSMetadataQuery` searching `kMDItemLastUsedDate` to find recently used applications.

## 4. C. Widget Feasibility & Data Decisions

### Weather
*   **Feasibility:** Requires an external API.
*   **Proposal:** Open-Meteo (free, no API key required). Location can be set manually via a text field in Settings (e.g., "City, Country" which we geocode) to avoid adding `CoreLocation` entitlement and permission prompts.

### Sticky Notes
*   **Feasibility:** Fully feasible locally.
*   **Proposal:** Persist notes as a simple JSON array in `UserDefaults` (if small) or a dedicated JSON file in `~/Library/Application Support/DeskBar`. Support create, edit, delete.

### Calendar
*   **Feasibility:** High.
*   **Proposal:** Reuse the existing `CalendarEventService` which already handles EventKit permissions and fetching.

### Power Controls
*   **Feasibility:** Feasible via AppleScript.
*   **Proposal:** Use `NSAppleScript`.
    *   *Sleep:* `tell application "System Events" to sleep`
    *   *Restart:* `tell application "System Events" to restart` (OS usually prompts)
    *   *Shut Down:* `tell application "System Events" to shut down` (OS usually prompts)
    *   *Lock:* `tell application "System Events" to keystroke "q" using {control down, command down}`

## 5. D. Settings & Integration

1.  **Appearance Tab:**
    *   Add "Start Menu Style" dropdown (Simple List, Full Dashboard).
    *   Add "Weather Location" text field.
2.  **Widgets Tab:**
    *   Add checkboxes for "Show Weather", "Show Calendar", "Show Sticky Notes" specifically for the Start Menu.

## 6. Build Order

1.  **Phase 1:** Add the `.pills` layout mode and refactor `TaskbarPanel` / `TaskbarContentView` to render three disjoint backgrounds. Verify layout and anchoring.
2.  **Phase 2:** Implement the Dashboard Start Menu shell (Left/Center/Right layout) behind a new variant setting.
3.  **Phase 3:** Populate Center (Pinned/All Apps toggle and persistence).
4.  **Phase 4:** Populate Right Rail (Profile, Folders, Power).
5.  **Phase 5:** Populate Left Widgets (Sticky Notes and Weather backend).

## 7. Open Questions

1.  **Weather Location:** Is using Open-Meteo with a manual city text setting acceptable to avoid location permission prompts?
2.  **Sticky Notes Storage:** Is a simple JSON file in Application Support the preferred persistence method?
3.  **Recents:** Should we only show recently *used* apps (easier via Spotlight metadata) or attempt to show recently *installed* (harder to track reliably)?
