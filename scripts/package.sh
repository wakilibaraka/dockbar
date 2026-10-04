#!/bin/bash
set -euo pipefail

APP_NAME="DockBar"
BUILD_DIR=".build/release"
BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean previous bundle
rm -rf "$BUNDLE_DIR"

# Create bundle structure
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Copy resources
if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Resolve version: explicit DOCKBAR_VERSION env wins, else the latest v* tag, else 0.0.0.
if [ -z "${DOCKBAR_VERSION:-}" ]; then
  DOCKBAR_VERSION="$(git describe --tags --match 'v*' --abbrev=0 2>/dev/null | sed 's/^v//' || true)"
fi
DOCKBAR_VERSION="${DOCKBAR_VERSION:-0.0.0}"

# Generate Info.plist from template
sed -e "s|__EXECUTABLE__|$APP_NAME|g" -e "s|__VERSION__|$DOCKBAR_VERSION|g" \
  Info.plist.template > "$CONTENTS_DIR/Info.plist"

# Ad-hoc codesign
codesign --force --sign - "$BUNDLE_DIR"

echo "Bundle created: $BUNDLE_DIR"
echo "To run: open $BUNDLE_DIR"
