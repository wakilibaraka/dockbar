# DockBar v1.5.0 Beta

This major beta release finalizes our transition from DeskBar to DockBar, introduces a pixel-perfect native battery menu bar replacement, and brings an entirely new flyout for power and device management.

## 🚀 Key Features & Changes

### 🔋 Native Battery Icon
- **Pixel-Perfect Redesign:** The menu bar battery icon has been completely rebuilt to match the native macOS proportions (16pt height) with a clean 1.5pt internal gap padding.
- **Dynamic Theming:** The outer stroke correctly adapts to Light and Dark mode using dynamic AppKit drawing handlers, while the inner fill adjusts its color based on your charge state (Green/Orange/Red).
- **Contrasting Text:** Percentage text is mathematically clipped to render in white over the color fill, and inverted over the empty background to ensure perfect readability.

### ⚡️ Power & Bluetooth Flyout
- **Rich Status Popover:** Left-clicking the battery icon now opens a new BeteriApp-inspired popover.
- **Battery Hero:** A circular, animated gauge showing live power draw (Watts), cycle count, battery health, and temperature.
- **Connected Devices:** A dedicated scrollable column for connected Bluetooth accessories, displaying specific icons (headphones, mouse, keyboard) and color-coded battery bars.
- **Smart Context Menu:** Right-clicking the battery icon seamlessly falls back to the standard application menu (Settings, Restore Windows, Quit).
- **Dashboard Cleanup:** Redundant battery and device sections have been removed from the main System Resource Dashboard to streamline the UI.

### 🧹 System Migration & Stability
- **Bundle ID Transition:** Fully migrated the underlying application bundle from `com.deskbar.app` to `com.dockbar.app`. 
- **Automated Cleanup:** Added a `MigrationManager` that automatically hunts down and terminates old DeskBar instances, unregisters stale LaunchAgents, and removes outdated config locks so that you never end up with two instances competing for permissions.
- **Zero-Width Bug Fix:** The menu bar item is now synchronously populated before layout to prevent macOS from incorrectly collapsing it on Macs with a notch.

