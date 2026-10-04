# Changelog

All notable changes to DockBar are recorded here. Versions follow this fork's 0.x line
(`v0.1.0` … `v0.5.0`); `scripts/package.sh` stamps `CFBundleShortVersionString` from the tag,
so the bundle version and the release tag always agree.

## [Unreleased]

## [0.5.0] - 2026-10-04

A redesign pass. The visible headline is a rebuilt Settings window, but most of the work
was removing the places where the app had quietly forked itself.

### Added

- **Searchable settings.** The Settings window has a search field that matches setting
  titles, help text, and keywords. Results are grouped by section, show each setting's
  current value, and jump to the section that owns them.
- **Live style preview.** Every style is now drawn as a miniature bar, rendered from the
  same `TaskbarStyleSpec` the real bar lays out from — width, corner radius, grouping,
  running indicator, and whether widgets appear in the bar are all read off the spec. The
  preview appears both in onboarding and in Settings, from one shared component, so it
  cannot drift from the bar or disagree with itself.
- **Per-section revert.** Each section has a "Revert" action that restores every setting
  in it to its default, behind a confirmation that names the section.
- **Help text on every setting.** Each row states what the setting does and why it exists,
  not just what it is called. The same text is indexed by search.

### Changed

- **Settings rebuilt around six sections:** Taskbar, Windows, Displays, Launcher, Widgets,
  and System. The previous window had seven overlapping categories; six dedicated tab
  views were dead code, and the live window silently omitted ten real settings (window
  grouping, grouped and frontmost click actions, drag reorder, middle-click close, hover
  delay, thumbnail and title sizes, and the hold-to-quit family). All of them are now
  reachable.
- **Every setting is described exactly once.** `SettingsCatalog` holds all 69 persisted
  settings with their section, title, help, control kind, keywords, and how to read and
  restore them. Tests enforce that keys are unique, that every `@Published` property on
  `TaskbarSettings` is catalogued (parsed from source, so adding one without cataloguing it
  fails the build), and that reverting every section reproduces a freshly constructed
  settings object value for value.
- **The five bar styles are declarative.** They used to be five strategy classes
  re-implementing a dozen near-identical methods, differing by a handful of constants —
  which is why they had drifted apart visually. `TaskbarStyleSpec` states each style once
  as data; a shared protocol extension derives the layout and appearance methods from it,
  and what remains per style is only what genuinely behaves differently. Tests pin the
  behaviour so the consolidation cannot silently change a style.
- **The menu bar has one owner.** Six `NSStatusItem`s each had their own Combine sink
  deciding whether to be visible, and the combined calendar/quick settings case had to be
  handled in all of them to avoid two items appearing at once. `MenuBarController` owns
  the items and a pure `MenuBarPlan` decides visibility, so the combined item and its two
  halves are mutually exclusive by construction.
- **Onboarding is four steps, not five.** "Choose Your Style" and "Personalize Your
  DeskBar" asked the same question twice; they are now one screen with the live preview,
  the three choices that actually matter, and a step counter.
- Booleans are toggles rather than segmented pickers, and enum pickers drop to a menu once
  they have more than two options, per the macOS HIG.

### Renamed

- **The `deskBar` style is now `Classic`.** It has always been the original solid bar;
  `DeskBarTaskbarStrategy` is now `ClassicTaskbarStrategy`. Installs that had chosen it
  keep it: the persisted raw value `deskBar` is migrated on read and rewritten as
  `classic`, with a regression test.

### Removed

- Six dead settings tab views, and `systemResourceWidgetPinnedDisplayID`, which has had no
  consumer since the Session Manager widget was removed.

### Fixed

- The notification permission row in Settings reports its real state instead of implying
  it, and the update check is reachable from Settings as well as the bar's context menu,
  through one shared code path so the wording cannot differ between them.

### Notes

- `TaskbarContentView.swift` went from 3,709 lines to 2,394 by splitting out the six types
  it was hiding. Swift's `private` is file-scoped, so those types had no choice but to live
  in a file named after an unrelated class — which is also why the task zone's manual
  ordering logic had no tests. It does now.
- The task button width rules moved out of a 1,600-line view into `TaskButtonWidthPlanner`,
  giving the minimum-width and icon-only fallback rules their first coverage.
- Visual constants now live in `DesignSystem` rather than as literals scattered across the
  tree.

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