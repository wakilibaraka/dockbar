tell application "System Events"
    tell process "DockBar"
        -- Open settings
        keystroke "," using command down
        delay 1
        
        -- Switch to Launcher tab
        click button "Launcher" of toolbar 1 of window "DeskBar Settings"
        delay 0.5
        
        -- The popup button for Launcher Style is probably the first or second.
        -- Let's just click the launcher button on the taskbar.
        -- Actually, there's no way to reliably click the popup without knowing the index.
        -- But I can just use defaults write for this test, no wait, user said NO DEFAULTS WRITE.
        -- Let's find the launcher button in the taskbar and click it.
        -- The launcher button doesn't have an ax label. Wait, it's the first button!
    end tell
end tell
