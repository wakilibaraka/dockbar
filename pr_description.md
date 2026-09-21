**DockBar — Phase 3: Reusable Metric Graph + Hop Network & Keyboard-Lock flyouts**

This PR introduces the third phase of enhancements, porting powerful metric visualization and utility flyouts from Hop while maintaining strict layout discipline and concurrency safety.

### 🚀 Deliverables
- **`MetricGraphView`**: A new, reusable, fixed-size SwiftUI graphing component using `Canvas` and `Path` for safe and smooth rolling metric visualization without relying on external packages.
- **`NetworkThroughputMonitor`**: A lightweight `@MainActor` service using `getifaddrs` to track down/up bytes at 1 Hz and maintain a 60-second rolling buffer.
- **`NetworkFlyoutView`**: A new popover interface combining live throughput graphs (via `MetricGraphView`) and an interactive `SpeedTestController` to display the actual network capacity (Mbps / RPM).
- **`KeyboardLockFlyoutView`**: A new popover providing a visual state representation, contextual instructions, and a quick-unlock button for the `KeyboardLockQuickSetting`.
- **System Resource Enhancements**: The existing `SystemResourceWidgetView` and `SystemResourceDashboardView` now seamlessly support a new opt-in `.graph` style (configured via `TaskbarElementsTab`).

### ⚙️ Build-risk checklist for merge (Antigravity verification)
- [x] **Actor-isolation:** Confirmed all `QuickSettings` and `QuickSettingsManager` properly specify `@MainActor`. No cross-actor boundary issues should occur during class initializations.
- [x] **Deinit isolation:** Deallocation logic in `KeyboardLockQuickSetting` correctly utilizes `nonisolated(unsafe)` `CFMachPort` and `CFRunLoopSource` references to safely invalidate the event tap inline during a non-isolated `deinit`.
- [x] **Fixed-width guarantees:** All graph components (`MetricGraphView`) render into fixed-width geometries and are strictly contained within `NSHostingView`s with constant constraints. `layoutSubtreeIfNeeded()` is explicitly avoided.
- [x] **Combine framework:** Ensured `import Combine` is present in any file utilizing `.sink` or `@Published` (e.g., `SpeedTestQuickSetting`, `SystemResourceMonitor`).

No regressions applied to native components (`RecentlyClosedTracker` stays pristine) or pipeline files (`release_refined.sh`).
