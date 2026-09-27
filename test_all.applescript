tell application "System Events"
    tell process "DockBar"
        -- Toggles and widgets
        click button "ClockWidget" of window 1
        delay 1
        click button "ClockWidget" of window 1
        delay 1
        
        click button "BatteryWidget" of window 1
        delay 1
        click button "BatteryWidget" of window 1
        delay 1
        
        click button "WeatherWidget" of window 1
        delay 1
        click button "WeatherWidget" of window 1
        delay 1
        
        -- Launcher
        click button "LauncherZone" of window 1
        delay 1
        click button "LauncherZone" of window 1
        delay 1
    end tell
end tell
