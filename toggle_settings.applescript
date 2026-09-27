tell application "System Events"
    tell process "DockBar"
        -- Open settings
        keystroke "," using command down
        delay 1
        
        -- Switch to Dock tab
        click button "Dock" of toolbar 1 of window "DeskBar Settings"
        delay 0.5
        
        -- Click Layout Mode popup
        click pop up button 3 of group 1 of scroll area 1 of group 1 of group 1 of window "DeskBar Settings"
        delay 0.2
        click menu item "Windows 11" of menu 1 of pop up button 3 of group 1 of scroll area 1 of group 1 of group 1 of window "DeskBar Settings"
        delay 0.5
        
        -- Ensure Icons Only is checked
        set iconsOnlyCheckbox to checkbox 1 of group 2 of scroll area 1 of group 1 of group 1 of window "DeskBar Settings"
        if value of iconsOnlyCheckbox is 0 then
            click iconsOnlyCheckbox
        end if
        delay 0.5
        
        -- Switch to Launcher tab
        click button "Launcher" of toolbar 1 of window "DeskBar Settings"
        delay 0.5
        
        -- Wait, where is the Launcher style?
    end tell
end tell
