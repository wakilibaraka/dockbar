#!/bin/bash
set -euo pipefail

# Build, package, and (optionally) publish a DockBar release DMG.
#
# Usage:
#   scripts/release.sh <version>            # build + DMG only
#   scripts/release.sh <version> --upload   # also create the GitHub release with the DMG
#
# The version is stamped into Info.plist (via package.sh) and used for the DMG name,
# e.g. `scripts/release.sh 0.3.0` produces `DockBar-v0.3.0.dmg` for tag `v0.3.0`.
#
# Distribution (optional, both are off by default):
#   SIGN_IDENTITY="Developer ID Application: ..."  re-sign the bundle and DMG
#   NOTARY_PROFILE=dockbar                          notarize + staple via notarytool

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

# package.sh always ad-hoc signs, which is fine for your own Mac but trips Gatekeeper
# everywhere else. Set SIGN_IDENTITY to re-sign with a real Developer ID certificate.
if [ -n "${SIGN_IDENTITY:-}" ]; then
  echo "Re-signing bundle with: $SIGN_IDENTITY"
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" ".build/release/DockBar.app"
fi

DMG="DockBar-v${VERSION}.dmg"
rm -f "$DMG"
hdiutil create -volname "DockBar" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG"

# Optional notarization, so other machines can launch the DMG without warnings.
# Needs a profile created earlier with `xcrun notarytool store-credentials`.
if [ -n "${NOTARY_PROFILE:-}" ]; then
  echo "Notarizing with profile: $NOTARY_PROFILE"
  if [ -n "${SIGN_IDENTITY:-}" ]; then
    codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"
  fi
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
fi

echo "Created $DMG"

if [ "$UPLOAD" = true ]; then
  # publish-release.sh is idempotent: it attaches to an existing release if one is
  # already there, so a hand-published release or a rerun cannot fail the build.
  bash scripts/publish-release.sh "v${VERSION}" "$DMG"
fi
