#!/bin/bash
set -e

./scripts/package.sh
rm -rf dmg_build && mkdir dmg_build
cp -R .build/release/DockBar.app dmg_build/
ln -s /Applications dmg_build/Applications
rm -f DockBar-v1.10.0.dmg
hdiutil create -volname "DockBar" -srcfolder dmg_build -ov -format UDZO DockBar-v1.10.0.dmg
gh release create v1.10.0 DockBar-v1.10.0.dmg --latest -t "DockBar v1.10.0" -n "UX customizability updates: Dock and Menu Bar Widget Switching, and newly integrated Quick Settings from Hop." -R wakilibaraka/dockbar
