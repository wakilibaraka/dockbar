# Changelog

All notable changes to DockBar are recorded here. Versions follow this fork's 0.x line
(`v0.1.0` … `v0.3.0`); `scripts/package.sh` stamps `CFBundleShortVersionString` from the tag,
so the bundle version and the release tag always agree.

## [Unreleased]

## [0.4.0] - 2026-10-04

### Added

- **Two new taskbar styles.** DeskBar reproduces the original edge-to-edge bar (solid
  chrome, one button per window, launcher leading, widgets trailing the window cluster);
  Eskele mirrors the dock from the eskele port (a pill that fits its contents, icons only).
  Both join Custom, Windows and Mac in Settings and onboarding, so the layouts can be
  compared side by side.
- **A display model instead of a boolean.** `showOnAllMonitors` becomes `TaskbarScreenMode`
  - all displays, per display, menu-bar display, plus focused display so upgrading installs
  do not silently move their bar. Legacy installs migrate from the old key.

### Fixed

- **Tall flyouts are no longer squashed.** A panel that did not fit below its anchor had
  its height clamped instead of moving, crushing the calendar and quick settings panels.
  Placement now prefers below, flips above, and clamps only as a last resort; the rules
  live in `FlyoutLayout` and are unit-tested.
- **The launcher is reachable in every style.** Mac and Eskele hid both the launcher
  button and the launcher zone, leaving those bars with no way to open the start menu.
  Custom showed both at once, which put a duplicate control on the bar. Every style now
  shows exactly one, enforced by a test over the strategy protocol.
- Widgets no longer disappear when switching away from the Windows style: the tray cluster
  is emptied before it is detached.

### Notes

- Taskbar flyouts are corner-continuous rounded rectangles with no notch or pointer.
  Only the menu-bar panels are allowed to point back at their status item.

## [0.3.0] - 2026-10-04

### Added

- **Check for Updates** — the taskbar context menu can now ask the GitHub Releases API for the
  latest release and compare it with the installed build, offering to open the release page.
  No third-party auto-updater: `UpdateService` is a few hundred lines and fully unit-tested.

### Changed

- Logging moved from scattered `print()` calls to `os.Logger` (`Log.*` categories,
  subsystem `com.dockbar.app`), so diagnostics are filterable in Console.app instead of
  interleaving on stdout.
- Window activation goes through `activateCompat()`, which uses the macOS 14 `activate()`
  where available and keeps a pre-14 path in one place instead of nine call sites calling the
  deprecated `activate(ignoringOtherApps:)`.
- Taskbar windows all live in a single unified row, so `ScreenGeometry.taskbarZone` no longer
  reports left/right zones.
- Release flow consolidated into `scripts/release.sh <version> [--upload]`, with optional
  Developer ID signing and notarization via `SIGN_IDENTITY` / `NOTARY_PROFILE`.
- CI runs `swift build` + `swift test` on every push, and a tag-triggered workflow publishes
  the release DMG.
- Fresh installs now default to the compact glass bar with window grouping, the window
  switcher, and the right-Command double-tap launcher — matching what the app advertises.

### Fixed

- Accessibility payloads are verified by CFTypeID before casting (`AXCast.element` /
  `AXCast.value`) instead of `as!`, so one malformed AX value from a non-standard app can no
  longer take down the taskbar.
- Test suite repaired: the bare-command detector's double-tap contract, the unified taskbar
  row, and the current default settings are now pinned by tests that actually compile against
  the shipped sources.

### Documentation

- Version claims reconciled: the 0.x release line, the bundle identifier note, and the dead
  `.agent-os` pointer in `agents.md` are gone; `scripts/release.sh` and `CHANGELOG.md` are now
  the single source of truth for versions.