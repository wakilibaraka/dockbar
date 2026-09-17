# Launcher Start-Style Investigation (Phase 0)

## 1. Mapping the Current Launcher
- **Presentation Layer**: The launcher is managed by `Sources/DeskBar/Launchpick/LaunchpickManager.swift`. It supports two modes: an anchored `NSPopover` (relative to the menu bar/dock button) or a floating, centered `LaunchpickPanel` (`NSPanel`).
- **UI Layout (Search + Grid)**: Constructed in `Sources/DeskBar/Launchpick/ContentView.swift`. It uses a SwiftUI `VStack`. The Search field is a simple `TextField` bound to `state.searchText`. Below it, a `LazyVGrid` maps over the user's customized `launchers` (loaded from JSON config).
- **Behavior**: The list of "System Apps" (everything else) currently only appears dynamically when a user *types* in the search bar. Otherwise, only the `Launchers` grid is visible.

## 2. App Discovery Logic
- **Location**: `Sources/DeskBar/Launchpick/AppScanner.swift`
- **Mechanism**: Iterates over standard directories (`/Applications`, `/System/Applications`, `/System/Applications/Utilities`, `~/Applications`) using `FileManager.contentsOfDirectory`. It de-duplicates by application name.
- **Reusability**: Very high. We can seamlessly reuse this exact scanner to populate the "All Apps" section without duplicate disk I/O.

## 3. LSApplicationCategoryType & Icons
- **Reading Category**: Confirmed that reading the category is straightforward via `Bundle(path: appPath)?.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String`. This yields identifiers like `public.app-category.productivity`.
- **Icons**: Icons are already efficiently fetched in `AppScanner` using `NSWorkspace.shared.icon(forFile:)`.

## 4. Power Actions & User Avatar
- **User Avatar**: We can retrieve the native macOS account picture using `CBIdentity(name: NSUserName(), authority: .default())?.image` (via the `Collaboration` framework), falling back to initials derived from `fullName`.
- **Power Actions via AppleScript**:
  - `Restart`: `tell application "System Events" to restart`
  - `Shut Down`: `tell application "System Events" to shut down`
  - `Log Out`: `tell application "System Events" to log out`
  - `Sleep`: `tell application "System Events" to sleep`
  - `Lock Screen`: macOS lacks a direct AppleScript command for locking. We can invoke the standard `pmset displaysleepnow` via a shell process, which instantly locks and sleeps the display without requiring Accessibility/UI-Scripting permissions.
- **Permissions Note**: Executing System Events AppleScripts for power actions will trigger a one-time macOS "Automation" permission prompt asking the user to allow DockBar to control System Events.

## 5. Proposed Phase Plan (Ready for Review)

**Phase 1: Enlarge the panel + All Apps scaffold**
- Increase `NSPopover` and `LaunchpickPanel` default heights.
- Introduce the empty, scrollable "All Apps" `VStack` below the favorites grid in `ContentView.swift`.

**Phase 2: Populate All Apps (Grouped + Searchable)**
- Extend `AppScanner.App` to parse and store the mapped category string.
- Add a "View: Category ↔ A–Z" toggle in the UI.
- Render the categorized list in the new "All Apps" section.
- Wire `state.searchText` to live-filter this list, maintaining parity with existing search functionality.

**Phase 3: Footer with Power Menu**
- Add a sticky footer `HStack` at the bottom of `ContentView.swift`.
- Left side: Fetch and display `CBIdentity` image or fallback initials.
- Right side: Add a Settings gear and a native-looking Power Menu (`Menu` button) that executes the verified AppleScripts.

**Phase 4 (Optional): Polish**
- Keyboard navigation hooks.
- "Show more/less" toggle for pinned grid if it overflows heavily.
