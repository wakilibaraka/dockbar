import Foundation

let path = "Sources/DockBarCore/WidgetRegistry.swift"
var content = try! String(contentsOfFile: path)

let oldDef = """
            WidgetDefinition(id: "quickSettings", slotEligibility: .tray, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
        ]
"""

let newDef = """
            WidgetDefinition(id: "quickSettings", slotEligibility: .tray, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
            WidgetDefinition(id: "liveEvents", slotEligibility: .liveEvents, defaultRule: .dock, fixedSize: CGSize(width: 80, height: 44)),
            WidgetDefinition(id: "taskView", slotEligibility: .taskView, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
            WidgetDefinition(id: "search", slotEligibility: .search, defaultRule: .dock, fixedSize: CGSize(width: 200, height: 44)),
            WidgetDefinition(id: "widgetsBoard", slotEligibility: .widgetsBoard, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
            WidgetDefinition(id: "downloads", slotEligibility: .downloads, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
        ]
"""

content = content.replacingOccurrences(of: oldDef, with: newDef)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
