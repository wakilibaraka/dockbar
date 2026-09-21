#!/bin/bash
set -e

./scripts/package.sh
rm -rf dmg_build && mkdir dmg_build
cp -R .build/release/DockBar.app dmg_build/
ln -s /Applications dmg_build/Applications
rm -f DockBar-v1.9.3.dmg
hdiutil create -volname "DockBar" -srcfolder dmg_build -ov -format UDZO DockBar-v1.9.3.dmg
gh release create v1.9.3 DockBar-v1.9.3.dmg --prerelease -t "DockBar v1.9.3 Beta" -F release_notes.md -R wakilibaraka/dockbar
