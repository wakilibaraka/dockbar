# DockBar

DockBar is a highly customizable, native macOS dock and taskbar replacement built with Swift and AppKit. Designed to be modular and highly responsive, DockBar allows you to completely overhaul your macOS desktop experience with dynamic floating pills, classic full-width taskbars, live system resources, and a robust quick-access dashboard.

## 🚀 Features

* **Dynamic Layout Engine:** Choose between multiple layouts including Full Width (classic Windows style), Compact (macOS dock style), Winstrix, and the new **Floating Pills** mode which divides the taskbar into distinct, floating segments.
* **Dashboard & Start Menu:** A powerful overlay that combines Spotlight-style search, recent files, sticky notes, weather, and a calendar view.
* **Live System Resources:** Keep an eye on your machine with real-time CPU, GPU, and Memory graphs rendered directly on the taskbar.
* **Quick Settings Flyout:** Instant access toggles for System Audio (Mute/Unmute), Microphone, Dark Mode, Caffeine (Keep Awake), and Bluetooth without having to open macOS Control Center.
* **Enhanced Calendar Clock:** A customizable gradient clock (Ocean, Violet, Sunset) that syncs with your Calendar to display upcoming events right on your taskbar.
* **Smart Window Management:** Easily switch between running apps, track active windows with running indicators, and automatically restore windows from sleep.
* **Complete Dock Override:** Hide the native macOS dock and let DockBar take over completely.

## 🛠 Architecture & UI

DockBar is built using a responsive `NSStackView` engine, dividing the taskbar into three intelligent zones:
1. **Launcher Zone (Left):** Houses the Dashboard Start button and quick Search toggle.
2. **Task Zone (Center):** Houses the active application icons (`RunningAppTrayView`). The engine automatically balances space, centering your icons perfectly and collapsing them into overflow menus when space gets tight.
3. **System Zone (Right):** Houses the system stat widgets, Quick Settings, and Enhanced Clock.

The background (the "Chrome") is dynamically drawn using a `ChromeGeometryProvider`, allowing it to shrink-wrap perfectly around your widgets into separate floating pills or span the full width of your monitor.

## ⚙️ Configuration & Settings

DockBar is highly customizable. Right-click anywhere on the taskbar to access the **Settings** menu. From there you can:
- Switch Layout Modes (Full Width, Pills, Compact)
- Toggle specific widgets on or off (e.g., hide the GPU monitor, or disable the clock)
- Customize the clock theme
- Manage whether DockBar appears on all monitors or just the primary display

## 🔐 Permissions

To function as a seamless system extension, DockBar requires the following macOS permissions. (These are requested via a friendly Onboarding Window on first launch):
* **Accessibility:** *Critical.* Required for DockBar to query window states, switch between active applications, and intercept global clicks to dismiss flyout panels.
* **Calendar:** Required by the Enhanced Clock and Dashboard to display your upcoming events.
* **Screen Recording:** Used if thumbnail previews of running applications are enabled.

## 📦 Building from Source

DockBar is built using the Swift Package Manager (SPM).

```bash
# Clone the repository
git clone https://github.com/wakilibaraka/dockbar.git
cd dockbar

# Build the release package
swift build -c release

# Package the application
bash scripts/package.sh

# The application will be generated in .build/release/DeskBar.app
# You can move this to your /Applications folder
```
