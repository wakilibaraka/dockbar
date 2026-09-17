#!/bin/bash
set -e

echo "Building and packaging..."
./scripts/package.sh

echo "Creating DMG..."
rm -rf dmg_build && mkdir dmg_build
cp -R .build/release/DockBar.app dmg_build/
ln -s /Applications dmg_build/Applications

rm -f DockBar-v1.6.4.dmg
hdiutil create -volname "DockBar" -srcfolder dmg_build -ov -format UDZO DockBar-v1.6.4.dmg

echo "Killing old instances and installing..."
killall DockBar || true
rm -rf /Applications/DockBar.app
cp -R dmg_build/DockBar.app /Applications/

echo "Committing and pushing to git..."
git add .
git commit -m "feat: revamp battery icon to classic macOS style, unify right-click menus to native left-click NSMenu, and use green for standard battery > 20%"
git push origin main

echo "Creating GitHub Release..."
gh release create v1.6.4 DockBar-v1.6.4.dmg --latest -t "DockBar v1.6.4 (Classic UI Revamp)" -n "Reverted battery to classic layout with text outside. Unified context menus to standard macOS native left-click popovers. Added user preference for green standard battery fill." -R wakilibaraka/dockbar

echo "Done!"
