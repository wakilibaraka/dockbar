tell application "System Events"
    tell process "DockBar"
        keystroke "," using command down
        delay 1
        return entire contents of window "DeskBar Settings"
    end tell
end tell
