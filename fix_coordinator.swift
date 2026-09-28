import Foundation

let path = "Sources/DeskBar/Views/Engine/ThemeCoordinator.swift"
var content = try! String(contentsOfFile: path)

let oldSwitch = """
            switch def.id {
            case "clock":
                // no clock settings
                break
            case "weather":
                isEnabled = settings.weatherEnabled
            case "battery":
                rule = settings.batteryWidgetLocation
            case "systemResources":
                isEnabled = settings.showSystemResourceWidget
                rule = settings.systemResourceWidgetLocation
            case "connectivity":
                rule = settings.connectivityTrayLocation
            default: break
            }
"""

let newSwitch = """
            switch def.id {
            case "clock":
                // no clock settings
                break
            case "weather":
                isEnabled = settings.weatherEnabled
            case "battery":
                rule = settings.batteryWidgetLocation
            case "systemResources":
                isEnabled = settings.showSystemResourceWidget
                rule = settings.systemResourceWidgetLocation
            case "connectivity":
                rule = settings.connectivityTrayLocation
            case "startButton":
                isEnabled = settings.showStartButton
            case "search":
                isEnabled = settings.showSearch
            case "taskView":
                isEnabled = settings.showTaskView
            case "widgetsBoard":
                isEnabled = settings.showWidgetsBoard
            case "downloads":
                isEnabled = settings.showDownloads
            case "liveEvents":
                isEnabled = settings.showLiveEvents
            default: break
            }
"""

content = content.replacingOccurrences(of: oldSwitch, with: newSwitch)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
