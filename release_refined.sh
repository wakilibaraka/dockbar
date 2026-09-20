#!/bin/bash
set -e

./scripts/package.sh
rm -rf dmg_build && mkdir dmg_build
cp -R .build/release/DockBar.app dmg_build/
ln -s /Applications dmg_build/Applications
rm -f DockBar-v1.6.1-refined.dmg
hdiutil create -volname "DockBar" -srcfolder dmg_build -ov -format UDZO DockBar-v1.6.1-refined.dmg
gh release create v1.6.1-refined DockBar-v1.6.1-refined.dmg --latest -t "DockBar v1.6.1 Refined" -n "UX refinements: unified task label width budget, vertical divider before Calendar, consolidated battery menu-bar Settings and Restore Windows to a single left-click flyout, and use memory pressure state for RAM pill color." -R wakilibaraka/dockbar
