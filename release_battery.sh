#!/bin/bash
set -e

# Package
./scripts/package.sh
rm -rf dmg_build && mkdir dmg_build
cp -R .build/release/DockBar.app dmg_build/
ln -s /Applications dmg_build/Applications

# Kill all previous instances
killall DockBar || true

# Install it
rm -rf /Applications/DockBar.app
cp -R dmg_build/DockBar.app /Applications/

# DMG
rm -f DockBar-v1.6.3-battery.dmg
hdiutil create -volname "DockBar" -srcfolder dmg_build -ov -format UDZO DockBar-v1.6.3-battery.dmg

# Release
gh release create v1.6.3-battery DockBar-v1.6.3-battery.dmg --latest -t "DockBar v1.6.3 Battery Icon Update" -n "Adds percentage text inside the battery icon (e.g. 24%) alongside the charging bolt, with dynamic high-contrast clipping." -R wakilibaraka/dockbar
