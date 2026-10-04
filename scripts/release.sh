#!/bin/bash
set -euo pipefail

# Build, package, and (optionally) publish a DockBar release DMG.
#
# Usage:
#   scripts/release.sh <version>            # build + DMG only
#   scripts/release.sh <version> --upload   # also create the GitHub release with the DMG
#
# The version is stamped into Info.plist (via package.sh) and used for the DMG name,
# e.g. `scripts/release.sh 1.4.1` produces `DockBar-v1.4.1.dmg` for tag `v1.4.1`.

VERSION="${1:-}"
[ -n "$VERSION" ] || { echo "usage: $0 <version> [--upload]" >&2; exit 1; }

UPLOAD=false
case "${2:-}" in
  "") ;;
  --upload) UPLOAD=true ;;
  *) echo "unknown flag: ${2}" >&2; exit 1 ;;
esac

echo "Building (release)..."
swift build -c release

echo "Packaging app bundle..."
DOCKBAR_VERSION="$VERSION" bash scripts/package.sh

echo "Creating DMG..."
DMG_DIR=dmg_build
rm -rf "$DMG_DIR" && mkdir -p "$DMG_DIR"
cp -R ".build/release/DockBar.app" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

DMG="DockBar-v${VERSION}.dmg"
rm -f "$DMG"
hdiutil create -volname "DockBar" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG"
echo "Created $DMG"

if [ "$UPLOAD" = true ]; then
  echo "Creating GitHub release v${VERSION}..."
  gh release create "v${VERSION}" "$DMG" --latest --verify-tag --generate-notes \
    --title "DockBar v${VERSION}"
fi
