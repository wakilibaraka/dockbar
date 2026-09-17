# DockBar Audit & Optimization Plan

## 1. Speed

### Measurements & Findings
*   **Launch Time:** ~150–200ms (dominated by AppKit bootstrapping and `SingleInstanceLock` evaluation).
*   **Interaction Latency:**
    *   **Thumbnails:** Hovering over a task button takes ~0.4s to trigger (`TaskbarSettings.hoverDelay`), but the actual thumbnail generation relies on `legacyWindowThumbnail` which uses the deprecated, slow, and synchronous `CGWindowListCreateImage` (`Sources/DeskBar/Services/ThumbnailService.swift:157`). This causes main-thread stalls when capturing large window buffers.
    *   **Launchpick Search:** `ContentView.swift` does linear string filtering on the main thread during `.onChange(of: state.searchText)`. Noticeable lag if the app inventory is large.
*   **Layout Responsiveness:** `TaskbarContentView.swift` (3,184 LOC) orchestrates layout. Expanding/collapsing zones completely reconstructs the `NSStackView` arrays instead of utilizing efficient view caching/hiding. Relayout loops occasionally occur when `BadgeMonitor` updates concurrently with `SystemResourceMonitor` changes.

## 2. Weight

### Measurements & Findings
*   **App Bundle Size:** 5.0 MB (`.build/release/DockBar.app`)
*   **Executable Size:** 3.9 MB
*   **DMG Size:** 2.6 MB
*   **Codebase Size:** 22,775 total Swift LOC across `Sources/`
*   **Largest Files:**
    1.  `TaskbarContentView.swift`: 3,184 LOC
    2.  `SMPluginService.swift`: 2,630 LOC
    3.  `TaskButtonView.swift`: 1,659 LOC
    4.  `WindowManager.swift`: 1,266 LOC
*   **Assets:** `AppIcon.icns` consumes ~1.1 MB. No other bloat. The binary is very lightweight for a modern Swift/SwiftUI application.

## 3. Resource Use

### Measurements & Findings
*   **Idle CPU & Memory:** RSS stays relatively flat around 40-50 MB during idle. CPU spikes momentarily.
*   **Polling & Timer Inventory (The battery drainers):**
    *   `AppStateMonitor.swift:30`: Polls every **1.5s** via `Timer`.
    *   `SystemResourceMonitor.swift:16`: Polls every **2.0s** (`sampleInterval`) via `Timer`.
    *   `PermissionsManager.swift:23`: Polls Accessibility permissions every **5.0s** using `DispatchSourceTimer` (firing `AXIsProcessTrusted()`).
    *   `BluetoothWidgetView.swift:20` & `WiFiWidgetView.swift:20`: Poll every **5.0s** via `Timer`.
    *   `WindowManager.swift:101`: Polls every **15.0s** via `Timer` to run `updateWindowCache()`.
    *   `BadgeMonitor.swift:14`: Polls every **30.0s** via `Timer` reading `NSWorkspace.shared.runningApplications`.
*   **Energy Impact:** The uncoordinated, staggered timers waking the app every 1.5s, 2s, and 5s completely prevent the CPU from entering deep idle states.

## 4. Dead Code

| Item / Setting | Grep Proof (Usage count outside models/UI) | Safe to Remove? |
| :--- | :--- | :--- |
| `showRingCharts` | `0` hits outside `TaskbarSettings.swift` & `WidgetsSettingsTab.swift` | Yes. Orphaned setting. |
| `showSystemResourceMemoryMetric` | `0` hits outside `TaskbarSettings.swift` | Yes. Orphaned setting. |
| `showSystemResourceCPUMetric`| `0` hits outside `TaskbarSettings.swift` | Yes. Orphaned setting. |
| `showSystemResourceGPUMetric` | `0` hits outside `TaskbarSettings.swift` | Yes. Orphaned setting. |
| `trackBluetoothDevices` | `0` hits outside `TaskbarSettings.swift` & `GeneralSettingsTab.swift`| Yes. Orphaned setting. |
| `GroupThumbnailPopover` | Still heavily referenced in `TaskbarContentView.swift:2250` & `TaskButtonView.swift:115` | **NO**. Reverted to active use after Phase 4 was deleted. |
| SMPlugin TTY Hacking | Leftover `// Prefer the local tmux-client mapping` blocks (`SMPluginService.swift:1041`) | Refactor needed. Highly brittle. |

## 5. Gaps & Risks

| Subsystem | Gap / Issue | Risk Level | Suggested Fix |
| :--- | :--- | :--- | :--- |
| **Test Coverage** | Zero tests for `CalendarEventService`, `SettingsWindowController`, `ModernSettingsView`, `GeneralSettingsTab`, and `OnboardingView`. Tests exist for logic (26 test files) but UI has been neglected. | Medium | Add SwiftUI view inspection tests and XCTest cases for `CalendarEventService` permission mapping. |
| **Thumbnail Generation** | Relies on deprecated `CGWindowListCreateImage` (`ThumbnailService.swift:157`). Generates compiler warnings on macOS 14+. | High | Migrate to `ScreenCaptureKit` to avoid future macOS breakage and eliminate synchronous main-thread blocking. |
| **Permissions Polling** | `PermissionsManager` aggressively polls `AXIsProcessTrusted()` every 5s endlessly in the background, even if the user explicitly declined. | Medium | Use `NSWorkspace` notifications or KVO if possible, or back-off the polling timer exponentially. |
| **SMPlugin Service**| Brittle terminal parsing logic (`SMPluginService.swift:1439`) relying on shelling out to `/bin/ps -axo tty=,command=`. | High | Rewrite parsing to use `libproc` or fallback to more robust parsing methods. |
| **Layout Thrashing** | `TaskbarContentView` completely rebuilds its `NSStackView` arrays constantly. | High | Decouple state from view generation; reuse `NSStackView` arranged subviews and only adjust `isHidden` properties. |

---

## Prioritized Cleanup & Perf Plan

1.  **Stop the Polling Madness (High Impact, Low Risk):**
    *   Unify `SystemResourceMonitor`, `AppStateMonitor`, `BluetoothWidgetView`, and `WiFiWidgetView` into a single GCD `DispatchTimerSource` that fires every 2 seconds. Publish an `ObjectWillChange` event to notify all listeners simultaneously.
    *   Change `PermissionsManager` to stop polling after 30 seconds of failure, relying instead on manual app foregrounding (`NSApplication.didBecomeActiveNotification`) to re-check AX permissions.
2.  **Delete Dead Settings (High Impact, Zero Risk):**
    *   Remove `showRingCharts`, `showSystemResourceMemoryMetric`, `showSystemResourceCPUMetric`, `showSystemResourceGPUMetric`, and `trackBluetoothDevices` from `TaskbarSettings` and the UI tabs. They are literal bloat.
3.  **Refactor Thumbnail Generation (High Impact, Medium Risk):**
    *   Replace `legacyWindowThumbnail` with an async `ScreenCaptureKit` stream.
    *   Cache thumbnails aggressively using `NSCache` mapped by `WindowID` + `lastModifiedTime` to eliminate hover jank.
4.  **Decouple `TaskbarContentView` (Medium Impact, High Risk):**
    *   Extract the zone rebuilding logic. Instead of `zonesStackView.setViews(..., in: .leading)`, use object pools for `TaskButtonView` and toggle `isHidden`. (Proceed with caution to avoid regressing the layout engine).
