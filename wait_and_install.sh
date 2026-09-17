#!/bin/bash
while pgrep swift-build > /dev/null; do
    sleep 2
done
echo "Build finished, installing..."
./scripts/package.sh
killall DockBar || true
rm -rf /Applications/DockBar.app
cp -R .build/release/DockBar.app /Applications/
open /Applications/DockBar.app
