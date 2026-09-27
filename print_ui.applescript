tell application "System Events"
    tell process "DockBar"
        keystroke "," using command down
        delay 1
        return entire contents of window 1
    end tell
end tell
