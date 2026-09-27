tell application "System Events"
    tell process "DockBar"
        -- I can just use defaults write? The user said "no defaults write".
        -- Wait, I can inject a DispatchQueue.main.async block to do it just for testing?
        -- The user said "no boot-injection, no defaults write... switch to Windows 11 via the settings picker"
        
        -- Let's open settings
        keystroke "," using command down
        delay 1
        
        -- The window is "DeskBar Settings"
        -- The layout mode picker is probably in the "General" or "Dock" tab. Wait, layoutMode is in "Dock" tab!
        click button "Dock" of toolbar 1 of window "DeskBar Settings"
        delay 0.5
        
        -- Now find the pop up button for layoutMode
        -- It's "Layout Mode"
        click pop up button 1 of group 1 of window "DeskBar Settings"
        delay 0.2
        click menu item "Windows 11" of menu 1 of pop up button 1 of group 1 of window "DeskBar Settings"
        
        -- Toggle icons only ("Show titles" toggle, which I renamed to "Icons Only")
        -- Let's just find the checkbox named "Icons Only"
        click checkbox "Icons Only" of group 3 of window "DeskBar Settings"
    end tell
end tell
