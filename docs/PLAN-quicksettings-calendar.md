# DeskBar — Plan: Quick Settings Flyout + Calendar/Clock Confirmation

> **Status:** Investigation & planning only. No source files modified.
> **Date:** 2026-09-04

---

## Part 1 — OnlySwitch Toggle Inventory

OnlySwitch (jacklandrin/OnlySwitch) organises every toggle as a Swift file in `OnlySwitch/EverySwitch/`. Each file conforms to a `SwitchProtocol` with `turnOn()`, `turnOff()`, and `isOn: Bool` computed property. Switches are registered in `SwitchManager.swift`.

### Full Inventory Table (41 switches)

| Toggle | What it does | macOS mechanism | Portability | Extra permissions | Recommendation |
|--------|-------------|-----------------|-------------|------------------|----------------|
| **Dark Mode** | System dark/light appearance | `NSAppearance` / `SkyLight` private fwk or `AppleInterfaceStyle` defaults key | Easy | None | **Port now** |
| **Mute** (audio out) | Mute/unmute system audio output | CoreAudio `kAudioHardwarePropertyDefaultOutputDevice` + `kAudioDevicePropertyMute` | Easy | None | **Port now** |
| **Mute Mic** | Mute/unmute default microphone input | CoreAudio `kAudioDevicePropertyMute` on input device | Easy | None | **Port now** |
| **Keep Awake** | Prevent display sleep | `IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep)` | Easy | None | **Port now** |
| **Bluetooth** | Toggle Bluetooth on/off | `IOBluetooth` framework `powerState` | Easy | None | **Port now** |
| **Autohide Dock** | Show/hide macOS Dock auto-hide | `defaults write com.apple.dock autohide` + `killall Dock` | Easy | None | **Port now** |
| **Autohide Menu Bar** | Auto-hide the menu bar | `defaults write NSGlobalDomain _HIHideMenuBar` | Easy | None | **Port now** |
| **Show Hidden Files** | Finder shows dot-files | `defaults write com.apple.finder AppleShowAllFiles` + `killall Finder` | Easy | None | **Port now** |
| **Show Finder Path Bar** | Finder path bar at bottom | `defaults write com.apple.finder ShowPathbar` + `killall Finder` | Easy | None | **Port now** |
| **Show File Extensions** | Show all file extensions | `defaults write NSGlobalDomain AppleShowAllExtensions` + `killall Finder` | Easy | None | **Port now** |
| **Show User Library** | Show `~/Library` in Finder | `chflags nohidden ~/Library` / `chflags hidden ~/Library` | Easy | None | **Port now** |
| **Dock Recent Apps** | Show/hide recent apps section in Dock | `defaults write com.apple.dock show-recents` + `killall Dock` | Easy | None | **Port now** |
| **Empty Trash** | One-tap empty trash | `NSWorkspace.shared.empty(trash:)` or `FileManager.removeItem` on `~/.Trash` | Easy | None | **Port now** (action, not toggle) |
| **Empty Pasteboard** | Clear clipboard | `NSPasteboard.general.clearContents()` | Easy | None | **Port now** (action) |
| **Eject Discs** | Eject all removable volumes | `NSWorkspace.shared.unmountAndEjectDevice(at:)` | Easy | None | **Port now** (action) |
| **Screen Saver** | Start screen saver immediately | `open -a ScreenSaverEngine` or `NSWorkspace.open(URL)` | Easy | None | **Port now** (action) |
| **F-Key** | Toggle Touch Bar Fn key mode | `AXUIElementSetAttributeValue` + private defaults key | Medium | Accessibility | **Port with caveat** (needs AX) |
| **Low Power Mode** | Toggle battery low-power mode | `pmset -a lowpowermode 1/0` via `Process` | Medium | None (admin prompt if not root) | **Port with caveat** |
| **Hide Desktop Icons** | Show/hide all Finder desktop icons | `defaults write com.apple.finder CreateDesktop` + `killall Finder` | Easy | None | **Port now** |
| **Hide Windows** | Hide all visible app windows | AppleScript `tell application "Finder" to set visible of every process to false` | Medium | Automation | **Port with caveat** |
| **Small Launchpad Icons** | Shrink Launchpad icon grid | `defaults write com.apple.dock springboard-columns/rows` + `killall Dock` | Easy | None | **Port now** |
| **Xcode Cache** | Delete Xcode derived data | `rm -rf ~/Library/Developer/Xcode/DerivedData` | Easy | None | **Port now** (action) |
| **Key Light** | Toggle keyboard backlight | IOKit `IOServiceGetMatchingService` keyboard brightness | Medium | None | **Port with caveat** (hardware-dependent) |
| **Dim Screen** | Reduce display brightness to 0 | `brightness` CLI or CoreDisplay private fwk | Fragile | None | **Skip** (private framework) |
| **Night Shift** | Toggle Night Shift on/off | `CBBlueLightClient` private framework | Fragile | None | **Skip** (private framework, breaks across OS updates) |
| **True Tone** | Toggle True Tone display | `CoreBrightness.framework` private class | Fragile | None | **Skip** (private framework) |
| **Top Notch** (hide notch) | Overlay a black bar over the notch area | Custom `NSWindow` overlay | Medium | None | **Port with caveat** (cosmetic hack) |
| **Hide Menubar Icons** | Hide third-party menu bar icons | `defaults write com.apple.systemuiserver` + restart | Fragile | None | **Skip** (unreliable on macOS 13+) |
| **AirPods** | Connect/disconnect AirPods | `IOBluetooth` + private BTLE commands | Fragile | None | **Skip** (device-specific private API) |
| **Apple Music** | Play/pause Apple Music | AppleScript `tell application "Music"` | Medium | Automation | **Port with caveat** |
| **Spotify** | Play/pause Spotify | AppleScript `tell application "Spotify"` | Medium | Automation | **Port with caveat** |
| **Sound Mixer** | Adjust per-app volume | CoreAudio object graphs (complex) | Fragile | None | **Skip** (complex, changes per macOS) |
| **Radio Station** | Play internet radio streams | AVFoundation `AVPlayer` + URL | Easy | None | **Port with caveat** (needs URL config) |
| **Pomodoro Timer** | 25-min productivity timer | Pure Swift `Timer` + notifications | Easy | Notifications | **Port now** |
| **Back Noises** | Play background audio | AVFoundation `AVAudioPlayer` | Easy | None | **Port now** |
| **Screen Test** | Solid-colour fullscreen test | `NSWindow` + `NSColor.fill` | Easy | None | **Port now** (action) |
| **AI Commander** | Siri / AI shortcut | AppleScript / shortcut invocation | Medium | Automation | **Port with caveat** |
| **Authenticator** | TOTP OTP generator | Pure Swift `CryptoKit` TOTP | Easy | None | **Port now** |
| **Top Sticker** | Always-on-top emoji window | `NSWindow.level = .floating` | Easy | None | **Port with caveat** (cosmetic) |
| **Show User Library** | (covered above) | — | — | — | — |
| **Hide Menubar Icons** | (covered above) | — | — | — | — |

### Summary by Recommendation

| Category | Count | Toggles |
|----------|-------|---------|
| **Port now** | 18 | Dark Mode, Mute, Mute Mic, Keep Awake, Bluetooth, Autohide Dock, Autohide Menu Bar, Show Hidden Files, Show Path Bar, Show Extensions, Show User Library, Dock Recent Apps, Empty Trash, Empty Pasteboard, Eject Discs, Screen Saver, Hide Desktop, Small Launchpad, Xcode Cache, Pomodoro, Back Noises, Screen Test, Authenticator |
| **Port with caveat** | 9 | F-Key (AX), Low Power Mode (pmset), Hide Windows (AS), Key Light (hw), Top Notch (hack), Apple Music (AS), Spotify (AS), Radio Station (URL config), AI Commander (AS) |
| **Skip** | 6 | Dim Screen, Night Shift, True Tone, Hide Menubar Icons, AirPods, Sound Mixer |

---

## Part 2 — Quick Settings Flyout Design

### 2.1 Button Placement

A new `QuickSettingsButtonView` (`NSView` subclass, 28×28 pt) sits in `zonesStackView` immediately to the left of `clockWidgetView` (if clock is enabled) or rightmost (if clock is hidden):

```
zonesStackView (horizontal):
[launcher][taskZone][sessionMgr][sysResource][runningAppTray][quickSettings][clock]
```

The button renders a Windows-style gear/grid icon (SF Symbol `gearshape.fill` or a 2×2 grid). It inherits the dark-glass aesthetic.

### 2.2 Flyout Panel

A floating `NSPanel` with:
- `styleMask: [.nonactivatingPanel, .borderless]`
- `level: .floating`
- `backgroundColor: NSColor.clear` + custom `NSVisualEffectView` dark material (`.hudWindow`) for the glass look — matching the Start Menu style.
- `collectionBehavior: [.canJoinAllSpaces, .transient]`
- Corner radius: 12 pt (matching the taskbar pill)
- Anchored: bottom-right corner of panel aligns with top-right corner of `QuickSettingsButtonView`, gap 4 pt.

Closes on:
- Click outside (global `NSEvent.addGlobalMonitorForEvents`)
- Pressing Escape
- Clicking the button again (toggle)

### 2.3 Grid Layout Inside the Panel

Toggle switches arranged in a responsive grid (3 columns on large panels, 2 on small):

```
┌───────────────────────────────────────────┐
│   Quick Settings                    ╳     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐│
│  │ 🌙 Dark   │  │ 🔇 Mute  │  │🎙️ Mic    ││
│  │  Mode     │  │          │  │  Mute    ││
│  └──────────┘  └──────────┘  └──────────┘│
│  ┌──────────┐  ┌──────────┐  ┌──────────┐│
│  │ 🔋 Keep  │  │ 🦷 BT    │  │ 📂 Hidden││
│  │  Awake   │  │          │  │  Files   ││
│  └──────────┘  └──────────┘  └──────────┘│
│  ...                                      │
│  ─────────────────────────────────────    │
│  Empty Trash     Eject Discs  Screen Saver│
└───────────────────────────────────────────┘
```

Each tile: 72×56 pt. Icon (SF Symbol, 22 pt) above label (10 pt), background toggles between active (accent tint, 20% opacity) and inactive (white, 5% opacity).

Action items (not toggles) appear at the bottom as a single-row strip of labelled buttons.

### 2.4 Toggle State Architecture

New protocol:

```swift
protocol QuickSetting: AnyObject, ObservableObject {
    var id: String { get }
    var title: String { get }
    var symbolName: String { get }
    var isOn: Bool { get }
    func toggle()
}
```

Each toggle is an isolated class conforming to this protocol. Examples:
- `DarkModeQuickSetting.swift` — reads/writes `NSAppearance`
- `MuteAudioQuickSetting.swift` — reads/writes CoreAudio mute property
- `KeepAwakeQuickSetting.swift` — manages `IOPMAssertion`

A `QuickSettingsManager` singleton holds an array of enabled `QuickSetting` objects (filtered from `settings.enabledQuickSettings: [String]`).

**State reading:** Each setting reads live system state (not from UserDefaults) so the panel always reflects actual system state.

**Persistence:** `settings.enabledQuickSettings: [String]` (ordered array of toggle IDs) determines which tiles appear. Default = `["darkMode", "mute", "muteMic", "keepAwake", "bluetooth"]`.

### 2.5 New Files / Services

| File | Responsibility |
|------|----------------|
| `Sources/DeskBar/Services/QuickSettingsManager.swift` | Registry of all `QuickSetting` implementations; loads enabled set from settings |
| `Sources/DeskBar/QuickSettings/QuickSetting.swift` | `QuickSetting` protocol definition |
| `Sources/DeskBar/QuickSettings/DarkModeQuickSetting.swift` | Dark Mode toggle |
| `Sources/DeskBar/QuickSettings/MuteAudioQuickSetting.swift` | Speaker mute |
| `Sources/DeskBar/QuickSettings/MuteMicQuickSetting.swift` | Mic mute |
| `Sources/DeskBar/QuickSettings/KeepAwakeQuickSetting.swift` | Prevent sleep via IOPMAssertion |
| `Sources/DeskBar/QuickSettings/BluetoothQuickSetting.swift` | Bluetooth power |
| `Sources/DeskBar/QuickSettings/AutohideDockQuickSetting.swift` | Dock auto-hide |
| `Sources/DeskBar/QuickSettings/HiddenFilesQuickSetting.swift` | Show/hide dot-files in Finder |
| `Sources/DeskBar/QuickSettings/PomodoroQuickSetting.swift` | 25-min Pomodoro timer |
| *(…one file per toggle, ~18 "Port now" files)* | — |
| `Sources/DeskBar/Views/QuickSettingsButtonView.swift` | Tray button (gear icon) that opens/closes the panel |
| `Sources/DeskBar/Views/QuickSettingsFlyoutPanel.swift` | `NSPanel` + grid layout container |
| `Sources/DeskBar/Views/QuickSettingsTileView.swift` | Reusable tile cell (icon + label + toggle state) |

### 2.6 Settings Entries

**Settings → Widgets → Quick Settings section:**

| Setting | Type | Default |
|---------|------|---------|
| Show Quick Settings button | Toggle | OFF |
| Active toggles | Ordered list (drag to reorder, checkbox to enable) | Dark Mode, Mute, Mute Mic, Keep Awake, Bluetooth |

**Implementation order (recommended batch 1 — "Port now"):**
1. Dark Mode
2. Mute / Mute Mic
3. Keep Awake
4. Bluetooth
5. Autohide Dock / Menu Bar
6. Show Hidden Files, Path Bar, Extensions

**Batch 2 — "Port with caveat":**
7. Low Power Mode (shows admin auth dialog on first use)
8. Apple Music / Spotify (requires Automation permission prompt)
9. F-Key (requires Accessibility)

---

## Part 3 — Calendar/Clock Confirmation

### Current state (from code investigation)

| Item | Status |
|------|--------|
| Clock implemented? | ✅ Yes — `ClockWidgetView` in `Sources/DeskBar/Views/ClockWidgetView.swift` |
| Wired into tray? | ✅ Yes — added as rightmost arranged subview of `zonesStackView` (TaskbarContentView.swift L429) |
| Behind what setting? | `settings.showClock` (defaults `false`; toggle in Settings → Tray Widgets) |
| Clock format | Two-line: `HH:mm` (L12) and `dd/MM/yyyy` (L18) |
| Click: scheme first? | ✅ Yes — tries `calendar366://` via `NSWorkspace.open(URL)` (L83–86) |
| Click: bundle fallback? | ✅ Yes — AppleScript `tell application "<name>" to activate` (L90–101) |
| Graceful no-op if absent? | ✅ Partial — error is caught by AppleScript's `try/on error` block (L92–95) |

### Bugs / Issues found

1. **Layout glitch (PRIMARY BUG):** The clock is invisible when the Accessibility permission banner is showing because the banner takes up the entire panel height. See PLAN-clock-port.md Part 1 for full root-cause analysis.

2. **Width hardcoded to 60 pt** in four measurement loop sites in `TaskbarContentView.swift` (L197, L1587, L1605, L1638, L1655). If the widget is ever widened (e.g., for the next-event line), all four sites need updating.

3. **URL scheme check uses `urlForApplication(toOpen:)` on a bare `calendar366://` URL** (L83). This function may return `nil` on some setups even if Calendar 366 is installed (it checks file associations, not URL schemes). A more reliable check is: try `NSWorkspace.shared.open(url)` directly inside a `do/try` and fall back to AppleScript on any error.

4. **Timer fires on background thread?** `Timer.scheduledTimer` without specifying the runloop — this is fine when called from `init` on the main thread, as it schedules on `RunLoop.main` by default. Not a bug, but worth a comment.

5. **`settings` is not `@Published` observed.** If `clockTargetApp` changes in settings, the running timer doesn't pick it up until the next click because it reads `settings.clockTargetApp` at click time — this is actually correct and fine.

### Fix / Completion Plan

1. Fix the banner layout conflict (see PLAN-clock-port.md Part 1, Option A or B).
2. Fix the `calendar366://` detection (replace `urlForApplication` check with a direct `open` try/catch).
3. Replace `ClockWidgetView` with `EnhancedClockWidgetView` per the clock plan.

### Tray Layout Order (with Quick Settings)

```
Right side of taskbar, left → right:

[systemResourceWidget] [runningAppTray] [quickSettingsButton] [clock]
```

Spacing:
- `zonesStackView` default spacing between arranged subviews: 0
- Custom spacing after `runningAppTray`: 4 pt (existing/natural)
- Custom spacing after `quickSettingsButton`: 6 pt (new `setCustomSpacing(6, after:)`)
- Custom spacing after `clock`: 0 (rightmost, already at edge inset)

The Quick Settings button is only visible when `settings.showQuickSettings == true` (off by default). When both are hidden, the tray collapses naturally since both views are `isHidden = true`.

---

## Part 3 — Taskbar by lawand-dot-io: Feature Port Analysis

As noted in PLAN-clock-port.md, the `lawand-dot-io/taskbar` repo is **HTML/CSS/JS only** — a browser-based mockup, not native Swift. No code can be directly ported.

However, the *design model* surfaces useful features missing from DeskBar that can be added natively:

| Feature from lawand mockup | Native equivalent plan | Difficulty |
|---------------------------|------------------------|-----------|
| App search (⌘-tap to open Search) | **Already implemented** as `StartMenuWindowController` (BareCommand shortcut) | Done ✅ |
| Taskbar launcher icon = app's own icon | **Replace the Start/launcher button icon with DeskBar's own `NSApp.applicationIconImage`** | Easy |
| Quick settings panel flyout | Planned above in Part 2 | Medium |
| Pinned apps in tray | **Already implemented** in Phase 2 (`pinnedTrayApps`) | Done ✅ |
| Grouped app windows on hover | **Already implemented** via `ThumbnailPopover` | Done ✅ |
| Notification badge on task buttons | **Already implemented** via `BadgeMonitor` | Done ✅ |
| System tray with clock | **Already implemented** as `ClockWidgetView` | Done ✅ |
| Colourful accent on active app | Could add a coloured underline/highlight per app's dominant icon colour | Medium |
| Jump list (right-click recent files) | AppleScript-based per-app recent items | Hard |
| Virtual desktops widget | Mission Control integration (limited public API) | Hard/Fragile |

### Replace Start Menu Icon with DeskBar's App Icon

The launcher zone button currently uses a custom Windows-start-style icon. Per the request, it should display the running app's icon (i.e., DeskBar's own `NSApp.applicationIconImage` — a 28×28 pt render of the app's icon).

**Plan:**
- In `LauncherButtonView.swift`, replace the static SF Symbol / custom icon with `NSApp.applicationIconImage?.resized(to: NSSize(width: 28, height: 28))`.
- Expose as a toggle: **Settings → Appearance → "Show app icon as launcher button"** (off by default, preserving current Windows logo behavior).

---

## Open Questions

1. **Quick Settings panel trigger:** Should the Quick Settings button also be triggered by a keyboard shortcut (e.g., `Cmd+Shift+Q`)? Or click-only?

2. **Tile grid size:** 3-column grid (72×56 pt tiles) vs. 2-column larger tiles (96×72 pt)? The larger format is more touch-friendly; the 3-column is more space-efficient.

3. **Pomodoro as Quick Setting vs. a separate tray widget?** It's a stateful timer, which makes it awkward as a grid tile. Could be a dedicated small indicator in the tray instead.

4. **Launcher icon replacement:** Should we switch the Start button icon to DeskBar's app icon by default, or keep the Windows logo and add it as an opt-in setting?

5. **Low Power Mode (`pmset`):** This requires running a privileged shell command, which triggers an admin password prompt on many setups. Should we gate it behind an "Advanced" label, or skip it for now?

6. **Bluetooth toggle:** The `IOBluetooth` API to toggle power state works but has been unreliable in some macOS versions. Should we fall back to opening System Settings → Bluetooth if the API fails?
