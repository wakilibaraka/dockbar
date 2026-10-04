# agents.md

## Project Overview

DeskBar is a native macOS taskbar replacement built with Swift/AppKit and Swift Package Manager.
The `Sources/DeskBar` directory and the `DeskBarTests` target keep their original names from
the pre-rename bundle identifier (`com.deskbar.app`); the app now ships as `com.dockbar.app`.

## Primary Docs

- `SPEC.md` is the authoritative product and implementation spec.
- `CHANGELOG.md` records what shipped, per release.
- `docs/` holds the feature investigations and plans.

## Workflow

- `swift build` and `swift test` are the whole loop; CI runs the same two commands on push.
- `scripts/build.sh` builds, `scripts/package.sh` bundles the `.app` and stamps the version
  from the tag, `scripts/release.sh <version> [--upload]` builds the DMG and publishes the
  GitHub release.
- Formatting baseline lives in `.swiftformat`.
