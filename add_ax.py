import os
import re

def add_ax(filename, ax_name):
    with open(filename, "r") as f:
        content = f.read()
    
    if 'func accessibilityLabel' not in content:
        ax = f"""
    override func accessibilityLabel() -> String? {{ return "{ax_name}" }}
    override func accessibilityRole() -> NSAccessibility.Role? {{ return .button }}
"""
        content = re.sub(r'\}\s*$', ax + '}\n', content)
        with open(filename, "w") as f:
            f.write(content)

add_ax("Sources/DeskBar/Views/DockClockWidgetView.swift", "ClockWidget")
add_ax("Sources/DeskBar/Views/DockBatteryWidgetView.swift", "BatteryWidget")
add_ax("Sources/DeskBar/Views/DockWeatherWidgetView.swift", "WeatherWidget")
