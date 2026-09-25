#!/bin/bash
set -e
echo "Clearing preferences and permissions for a fresh start..."
defaults delete com.dockbar.app || true
tccutil reset Accessibility com.dockbar.app || true

echo "Building the project..."
swift build -c release

echo "Ensuring App Bundle structure..."
mkdir -p .build/release/DockBar.app/Contents/MacOS
mkdir -p .build/release/DockBar.app/Contents/Resources
cp .build/release/DockBar .build/release/DockBar.app/Contents/MacOS/
if [ -f "Info.plist" ]; then
    cp Info.plist .build/release/DockBar.app/Contents/
fi
if [ -f "Info.plist.template" ] && [ ! -f "Info.plist" ]; then
    cp Info.plist.template .build/release/DockBar.app/Contents/Info.plist
fi

echo "Killing existing instances..."
killall DockBar || true
killall DeskBar || true

echo "Installing to /Applications..."
rm -rf /Applications/DockBar.app
cp -R .build/release/DockBar.app /Applications/
sed -i '' 's/__EXECUTABLE__/DockBar/g' /Applications/DockBar.app/Contents/Info.plist || true
sed -i '' 's/__VERSION__/1.9.4/g' /Applications/DockBar.app/Contents/Info.plist || true

echo "Launching the app..."
open /Applications/DockBar.app

echo "Installation complete!"
