# Changelog

All notable changes to DockBar are recorded here. Versions follow this fork's 0.x line
(`v0.1.0` … `v0.3.0`); `scripts/package.sh` stamps `CFBundleShortVersionString` from the tag,
so the bundle version and the release tag always agree.

## [Unreleased]

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