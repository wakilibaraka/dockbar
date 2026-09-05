# DeskBar — Investigation: Fork vs. Original Upstream

**Date:** September 5, 2026  
**Fork:** `wakilibaraka/dockbar` (`/Users/baraka/DockBar/deskbar`)  
**Upstream:** `rajeshgoli/deskbar` (commit `890052d12f455cb72fd90927e4f520c9526c0b53`)  
**Verdict:** **Option (B) — Revert to Upstream Baseline and Re-Apply Curated Additions**

---

## 1. Naming & Provenance Verification

**Confirmation:** This repository ("DockBar") is an in-place renamed fork of the original **DeskBar by Rajesh Goli (`rajeshgoli/deskbar`)**, licensed under the MIT License.

### Evidence
1. **Package Configuration (`Package.swift`)**:
   ```swift
   let package = Package(
       name: "DeskBar",
       targets: [
           .executableTarget(name: "DeskBar", path: "Sources/DeskBar"),
           .testTarget(name: "DeskBarTests", path: "Tests/DeskBarTests")
       ]
   )
   ```
2. **Bundle Identifier & Application Metadata (`Info.plist.template`)**:
   * `CFBundleIdentifier`: `com.deskbar.app`
   * `CFBundleName`: `DeskBar`
   * `CFBundleExecutable`: `DeskBar`
3. **Packaging Script (`scripts/package.sh`)**:
   * Generates `/Applications/DeskBar.app` from `.build/release/DeskBar`.
4. **Git Initial Commit (`1c50b8c`)**:
   * `README.md` explicitly states: `git clone https://github.com/rajeshgoli/deskbar.git`
   * `.gitmodules` references upstream origin: `https://github.com/rajeshgoli/agent-os.git`
   * Original specification (`SPEC.md`) documents Rajesh Goli's project genesis replacing a third-party `Taskbar.app`.
5. **Renaming Scope**:
   * The renaming to "DockBar" was limited entirely to the GitHub repository name (`wakilibaraka/dockbar`) and the top-level Markdown title (`# DockBar`). Every internal symbol, class name (`DeskBarLayoutMode`), bundle ID, and binary name remains `DeskBar`.

---

## 2. Step 1 — Establish the Two Baselines

### Baseline A: Upstream DeskBar (`rajeshgoli/deskbar`)
* **Codebase Scale**: 57 Swift files in `Sources/DeskBar`, ~26,000 lines of code, 150 automated tests in `Tests/DeskBarTests`.
* **Architecture**: Clean, pure AppKit architecture. Single binary, zero external runtime dependencies.
* **Layout Modes**: 4 native modes (`.fullWidth`, `.fullWidthGlass`, `.compact`, `.compactGlass`).
* **Launcher Zone**: Houses pinned applications (`PinnedAppManager`) and an Apps button (`AppsLauncherButtonView`) which opens native macOS Launchpad (`/System/Applications/Launchpad.app` or `Apps.app`). It has **no** custom Start menu or built-in search.
* **Task Zone**: Individual window buttons with live hover thumbnails (`ScreenCaptureKit`), app grouping, drag-to-reorder, and middle-click close.
* **System Zone**: Houses a working, compact `SystemResourceWidgetView` (CPU, RAM, GPU inline meters), optional `SessionManagerWidgetView`, and the `RunningAppTrayView`.
* **Stability & Health**: 100% test pass rate in 0.09s. Clean AutoLayout without geometry loops, no layout oscillation, zero clipping on the right edge, no commented-out code, and no orphaned settings.

### Baseline B: Current Fork (`wakilibaraka/dockbar`)
* **Codebase Scale**: 91 Swift files (34 additional files), ~30,200 lines of code.
* **Layout Modes**: Added `.winstrix`, `.winstrixFlat`, and `.pills`. Default switched to `.pills`.
* **Start Menu**: Custom 2-pane Start menu window (`StartMenuWindowController.swift`) replacing the Launchpad trigger, featuring Spotlight-style file search (`NSMetadataQuery`) and power controls.
* **Instability History**:
  1. *Clock oscillation loop*: Adding an intrusive clock with per-minute preferred-width broadcasts created continuous layout loops across the entire bar.
  2. *Invisible taskbar bug in `.pills` mode*: Layer-based `ChromeGeometryProvider` updates conflicted with parent layout passes, causing the bar to fail to draw on launch. (Stabilized in commit `b7b32c5` using AutoLayout `ChromePillView` backgrounds).
  3. *Right-edge overflow*: Packing stats, clocks, quick settings, and tray items exceeded display bounds on narrow screens, violently clipping off the right edge.
  4. *Performance hitching & memory leaks*: Main-thread blocking during file queries, an unfreed `NSMetadataQuery` observer token in the dashboard, and 0.4s hover stalls.
* **Current Post-Stripping State**:
  * The Start menu was reduced to 2 panes, and the file query was moved to a background `OperationQueue` (fixed).
  * The right-edge overflow was "fixed" via a blunt workaround: commenting out `systemResourceWidgetView`, `clockWidgetView`, `quickSettingsButtonView`, and `sessionManagerWidgetView` from `TaskbarContentView.swift`, and replacing their width calculations with `+ 0 + 0 + 0 +`.
  * The app is currently functional and passing the 150 tests, but ~2,000 lines of dead Swift files remain compiled into the binary, and upstream's working System Resource widget is disabled.

---

## 3. Step 2 — Diff Fork vs Upstream

### Table 1: In Upstream, Missing / Broken in This Fork (What You Regain by Reverting)

| Upstream Feature | Status in Current Fork | Impact of Regaining |
| :--- | :--- | :--- |
| **System Resource Widget (CPU/RAM/GPU)** | **Disabled / Commented out** (`// systemZoneContainer.addArrangedSubview...` and `+ 0 +` in width calculation) | Regain a fully functional, compact system monitor on the taskbar without clipping. |
| **Session Manager Integration** | **Disabled / Commented out** | Regain terminal agent / tmux session monitoring on the taskbar. |
| **Clean Layout Engine Architecture** | **Hacked** with commented-out code and literal arithmetic replacements (`+ 0 + 0 + 0 +`) | Eliminates fragile layout math and prevents subtle regressions when resizing or toggling displays. |
| **Cohesive Settings UI** | **Cluttered with dead controls** (~400 lines of orphaned checkboxes for weather, sticky notes, clock themes) | Clean Settings window where every single toggle works and has an immediate, verifiable effect. |
| **Zero Dead Weight / Small Binary** | Fork compiles 34 unused or disconnected files into the executable | Faster compilation, cleaner codebase, smaller footprint, zero background resource waste. |

---

### Table 2: In This Fork, Not in Upstream (Net Additions That Survived)

| Feature / Change | Implementation in Fork | Verdict / Robustness |
| :--- | :--- | :--- |
| **Three-Pill Floating Layout (`.pills`)** | `ChromePillView.swift` added directly into `TaskbarContentView` hierarchy. | **Solid (Keeper)**. Now that it uses standard AutoLayout instead of `ChromeGeometryProvider`, it is fast, stable, and visually modern. |
| **Two-Pane Start Menu Overlay** | `StartMenuWindowController.swift` replaces native Launchpad trigger with app list + Spotlight file search. | **Solid (Keeper)**. Background `OperationQueue` search resolves previous UI hitching; far superior to launching macOS Launchpad. |
| **Bare Command Tap Guard** | `BareCommandShortcutDetector.swift` checks `elapsed < 0.25`s. | **Solid (Keeper)**. Prevents accidental launcher openings when releasing `Cmd` after chords. |
| **Extended Thumbnail Caching (5s)** | `ThumbnailService.swift` `cacheTTL` raised from 2s to 5s. | **Solid (Keeper)**. Reduces CPU spikes and hover stutter when moving across task buttons. |
| **Reduced WindowManager Polling (60s)** | `WindowManager.swift` polling timer backed off from 15s to 60s. | **Solid (Keeper)**. Relies primarily on event-driven AX observers; reduces idle battery/CPU drain. |
| **Frontmost App Click Action** | `TaskButtonView.swift` supports minimize vs cycle active windows. | **Solid (Keeper)**. High-utility UX configuration. |
| **Reopen Last Quit App Context Menu** | `RecentlyQuitAppsService.swift` + `RunningAppTrayView.swift`. | **Moderate**. Convenient, but non-essential. |
| **Running Indicator Styles** | `RunningIndicatorStyle.swift` (dots, lines, pills). | **Solid**. Cosmetic preference that works cleanly. |

---

### Table 3: Code-Health & Tech-Debt Introduced by "Vibecoding"

| Issue / Artifact | Where It Exists | Consequence & Severity |
| :--- | :--- | :--- |
| **Zombie QuickSettings Subsystem** | `Sources/DeskBar/QuickSettings/*` (17 files, ~600 lines) + `QuickSettingsManager` | **High Tech-Debt**: Compiled into binary, instantiated in memory at boot, but completely disconnected from the UI. |
| **Zombie Clock & Calendar Code** | `EnhancedClockWidgetView.swift`, `CalendarFlyoutPanel.swift`, `CalendarEventService.swift`, `ClockTheme.swift` (~800 lines) | **High Tech-Debt**: Instantiated in `TaskbarContentView.init()`, requesting calendar permissions and running timers, but completely hidden. |
| **`+ 0 + 0 + 0 +` Arithmetic Hacks** | `TaskbarContentView.swift` (lines 220, 240, 260, 280) | **High Fragility**: Fragile text replacements that leave confusing mathematical debris in core layout budgeting routines. |
| **Commented-Out View Additions** | `TaskbarContentView.swift` (lines 457-460) | **Moderate Fragility**: Subviews are retained as properties but commented out from the view hierarchy. |
| **Orphaned Settings Controls** | `SettingsView.swift` (Weather, Sticky Notes, Clock Theme controls) | **Moderate Tech-Debt**: User can toggle options in Settings that write to `UserDefaults` but do absolutely nothing in the app. |
| **Zero Unit Tests for New Features** | `Tests/DeskBarTests/` | **High Risk**: All 150 passing unit tests belong to upstream. Not a single test verifies `StartMenuWindowController`, `ChromePillView`, or the new settings. |

---

## 4. Step 3 — Strategic Evaluation & Recommendation

### Path Analysis

#### Option A: Keep and Stabilize This Fork
* **Gain**: Keep current working state without starting over.
* **Loss**: You are maintaining a severely compromised codebase where upstream's system monitor and session manager had to be amputated to prevent screen clipping, surrounded by ~2,000 lines of dead code and hardcoded layout patches.
* **Required Work**:
  1. Delete all 17 files in `QuickSettings/`, `CalendarEventService`, `CalendarFlyoutPanel`, `EnhancedClockWidgetView`.
  2. Strip orphaned checkboxes from `SettingsView.swift`.
  3. Clean up the `+ 0 +` layout math in `TaskbarContentView.swift`.
  4. Re-engineer `SystemResourceWidgetView` sizing so it can be re-enabled without causing right-edge overflow.
  5. Write tests for `StartMenuWindowController` and `ChromePillView`.

#### Option B: Revert to Upstream and Re-Apply Curated Additions (RECOMMENDED)
* **Gain**: 
  * You return to a pristine, clean upstream architecture with working System Resource monitoring, clean settings, and zero technical debt.
  * You preserve the **only things that actually made the fork good**: the modern **Three-Pill layout (`.pills`)**, the **Two-Pane Start Menu**, the **Command-tap 0.25s guard**, and the **perf tweaks (60s polling + 5s thumbnail cache)**.
  * You permanently discard the failed experiments (fragile clock widget, weather/notes dashboard bloat, monolithic Quick Settings panel).
* **Loss**: Takes ~30–45 minutes of surgical git cherry-picking / file porting.
* **Verdict**: **The superior technical and product choice.**

#### Option C: Clean Reinstall of Upstream (Abandon Fork)
* **Gain**: Zero effort, immediate stability.
* **Loss**: You lose the Three-Pill visual appearance and the Start Menu. Upstream falls back to the full-width Windows bar and triggers full-screen macOS Launchpad when you click the Apps button.

---

## 5. Implementation Plan for Option (B): "Revert & Re-Apply"

If you choose **Option B**, here is the exact, zero-risk recipe to produce the ideal DeskBar:

### Phase 1: Reset to Upstream Baseline
1. Set upstream tracking branch to `rajeshgoli/deskbar:main`.
2. Hard-reset working tree to upstream commit `890052d`.
3. Verify upstream builds and passes all 150 tests.

### Phase 2: Transplant the 4 Proven Assets
1. **Asset 1 — Three-Pill AutoLayout Mode**:
   * Port `Sources/DeskBar/Views/ChromePillView.swift`.
   * Add `.pills` case to `DeskBarLayoutMode` (set as default).
   * In `TaskbarContentView.swift`, add the three `ChromePillView` backgrounds and update `updateTaskbarLayout()` to toggle pill visibility vs full-width background.
   * *Risk*: Low. AutoLayout approach is proven and stable.
2. **Asset 2 — Two-Pane Start Menu**:
   * Port `Sources/DeskBar/Views/StartMenuWindowController.swift` (using the fixed background `OperationQueue` search implementation).
   * Update `AppsLauncherButtonView.swift` to invoke `StartMenuWindowController.shared.toggle()`.
   * *Risk*: Low. Self-contained window controller.
3. **Asset 3 — Command Tap Guard**:
   * Port the `elapsed < 0.25` logic into `BareCommandShortcutDetector.swift`.
   * *Risk*: None.
4. **Asset 4 — Performance Tuning**:
   * In `WindowManager.swift`, change poll interval from 15.0s to 60.0s.
   * In `ThumbnailService.swift`, change `cacheTTL` from 2s to 5s.
   * *Risk*: None.

### Result
You get an application that is **leaner, faster, and cleaner than both the current fork AND upstream**: upstream's rock-solid foundation + your modern Three-Pill aesthetics and native Start menu, with zero bloat.

---

## 6. Open Questions for the User

1. **Keep Upstream's Resource Monitor?** When we revert and re-apply, do you want upstream's original compact CPU/RAM/GPU widget active on the right pill, or do you prefer the right pill to remain strictly minimal (Tray icons only)?
2. **Naming Preference:** Do you want to formally rebrand the project to "DockBar" across all files (including `Package.swift`, `CFBundleIdentifier: com.dockbar.app`, and directory structure), or keep the upstream "DeskBar" identity?
3. **Execution Approval:** Should we proceed with executing **Option B (Revert to Upstream and Re-Apply Curated Additions)** now?
