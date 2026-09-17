# Menu Bar Battery Investigation

## 1. Why the Status Item Isn't Showing

I traced the `NSStatusItem` lifecycle in `DockBar` and checked every possible failure point:

- **Retention:** `AppDelegate.configureStatusItem()` assigns the item to a local variable `let statusItem`, but correctly retains it via `self.statusItem = statusItem` at the bottom of the function. The Combine `.sink { [weak statusItem] }` correctly updates the captured item. (I verified this with a standalone Swift test script).
- **Execution:** It is called sequentially inside `applicationDidFinishLaunching` on the main thread.
- **Button Image/Size:** `BatteryStatusRenderer.renderImage(for:)` synchronously returns a valid `28x14` image.

**Root Cause:**
The issue stems from a combination of the **Single-Instance Lock** and the recent **LaunchAgent/App renaming**:
1. Because the app was previously known as `DeskBar`, the old background `LaunchAgent` (or a leftover running process) holds the single instance lock at `~/.config/deskbar/deskbar.lock`.
2. When you manually launch the newly compiled `DockBar` (which contains the new battery code), it encounters the lock, prints `"DeskBar: another instance is already running; exiting duplicate."`, and silently calls `NSApp.terminate(nil)`.
3. The app you are actually looking at on your screen is the *old* background `DeskBar` instance, which never had the `configureStatusItem` battery code to begin with!

*(Minor secondary factor: The `statusItem` relies on Combine's asynchronous `.receive(on: DispatchQueue.main)` to set its initial image and title. While macOS usually handles asynchronous `variableLength` item resizing, on heavily loaded notch Macs, a status item initially added with zero width can occasionally be permanently hidden. Supplying a synchronous placeholder image/title before the async subscription guarantees it reserves space immediately).*

**Recommended Fix (Phase 2):**
- Force kill all stale `DeskBar` background agents.
- Update `SingleInstanceLock.swift` to use `~/.config/dockbar/dockbar.lock` to break free from the old footprint.
- Synchronously set an initial `"---"` title or empty image on the `statusItem.button` before the Combine sink.

## 2. Inventory of Existing Battery + Bluetooth Code

DockBar currently houses excellent, robust logic for power and devices.
- **`Sources/DeskBar/Services/BatteryMonitor.swift`**: Uses `IOPSCopyPowerSourcesInfo` for basic percentage and charging status (currently drives the menu bar item).
- **`Sources/DeskBar/Services/Stats/SystemStatsService.swift`**: Uses deep `IOServiceGetMatchingService("IOPMPowerSource")` queries to extract `wattage` (draw), `cycleCount`, `healthPercentage`, and `temperature`. 
- **`Sources/DeskBar/Services/Stats/BluetoothStatsService.swift`**: Parses `/usr/sbin/system_profiler SPBluetoothDataType` via a background `Task` to get connected devices and their battery levels.
- **`Sources/DeskBar/Views/SystemResourceDashboardView.swift`**: Contains a `BatteryAndDevicesSection` SwiftUI view that displays all of this inside the stats flyout.

**Plan for Move:** We can reuse *all* of the existing `SystemStatsService` and `BluetoothStatsService` data fetching! We will completely remove `BatteryAndDevicesSection` from `SystemResourceDashboardView`, shrinking the system resource flyout to just CPU/MEM/GPU, and port the UI into a new `BatteryFlyoutView`.

## 3. BeteriApp Popover Source

I successfully located the BeteriApp UI source at `/Users/baraka/BeteriApp/BatteryBoi`.
- I examined `BatteryHeroView.swift`, `BBHUDView.swift`, and `BBBluetoothView.swift`.
- BeteriApp uses a clean circular gauge (ZStack with trimmed circles) for the main charge, a horizontal `ScrollView` or `VStack` for the connected devices list, and a grid of status cards (Draw / Health / Cycles / State) for metrics.
- Since `DockBar` already has the exact data services required, the port will be purely UI-focused. I will extract the visual styling (the circular stroke gauge and device capsule look) into our new `BatteryFlyoutView` using standard SwiftUI.

## 4. Phased Implementation Plan

### Phase 2: Native Battery Icon & Fix
- Update `BatteryStatusRenderer.swift` to draw the horizontal macOS-style battery with a terminal nub, percentage rendered *inside* the battery fill, and dynamic colors (Green ≥50%, Amber 20–49%, Red <20%).
- Apply the `SingleInstanceLock` rename and the synchronous `statusItem` placeholder fix in `AppDelegate` so the icon is guaranteed to appear and take precedence over old ghosts.
- **Review Gate:** Build, package DMG, and await your visual confirmation of the new menu bar icon.

### Phase 3: The Flyout (Lightweight Port)
- Create `BatteryFlyoutPanel.swift` (an `NSPanel` / `NSPopover` anchored to the status item) and `BatteryFlyoutView.swift`.
- Remove the battery/bluetooth block from `SystemResourceDashboardView.swift`.
- Recreate the BeteriApp circular gauge, Connected Devices list, and status cards in `BatteryFlyoutView`, binding them to our existing `SystemStatsService` and `BluetoothStatsService`.
- Wire the menu bar icon click to toggle the flyout (using an `EventMonitor` for outside clicks).
- **Review Gate:** Build, package DMG, and await final approval.
