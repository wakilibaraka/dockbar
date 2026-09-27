tell application "System Events"
    tell process "DockBar"
        -- Find the widgets inside window 1
        -- "ClockWidget", "BatteryWidget", "WeatherWidget"
        
        click button "ClockWidget" of window 1
        delay 1
        -- close it
        click button "ClockWidget" of window 1
        delay 1
        
        click button "BatteryWidget" of window 1
        delay 1
        -- close it
        click button "BatteryWidget" of window 1
        delay 1
        
        click button "WeatherWidget" of window 1
        delay 1
        -- close it
        click button "WeatherWidget" of window 1
        delay 1
    end tell
end tell
