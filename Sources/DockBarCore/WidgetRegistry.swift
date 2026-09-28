import Foundation
import CoreGraphics

public enum WidgetLocation: String, Codable, CaseIterable, Identifiable {
    case dock
    case menuBar
    case auto
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .dock: return "Taskbar"
        case .menuBar: return "Menu Bar"
        case .auto: return "Auto"
        }
    }
}

public struct WidgetDefinition {
    public let id: String
    public let slotEligibility: SlotKind
    public let defaultRule: WidgetLocation
    public let fixedSize: CGSize
    
    public init(id: String, slotEligibility: SlotKind, defaultRule: WidgetLocation, fixedSize: CGSize) {
        self.id = id
        self.slotEligibility = slotEligibility
        self.defaultRule = defaultRule
        self.fixedSize = fixedSize
    }
}

public class WidgetRegistry {
    public static let shared = WidgetRegistry()
    
    public let definitions: [WidgetDefinition]
    
    private init() {
        self.definitions = [
            WidgetDefinition(id: "startButton", slotEligibility: .startButton, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
            WidgetDefinition(id: "weather", slotEligibility: .leading, defaultRule: .auto, fixedSize: CGSize(width: 80, height: 44)),
            WidgetDefinition(id: "systemStats", slotEligibility: .tray, defaultRule: .dock, fixedSize: CGSize(width: 100, height: 44)),
            WidgetDefinition(id: "connectivity", slotEligibility: .tray, defaultRule: .auto, fixedSize: CGSize(width: 60, height: 44)),
            WidgetDefinition(id: "clock", slotEligibility: .tray, defaultRule: .dock, fixedSize: CGSize(width: 80, height: 44)),
            WidgetDefinition(id: "quickSettings", slotEligibility: .tray, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
            WidgetDefinition(id: "liveEvents", slotEligibility: .liveEvents, defaultRule: .dock, fixedSize: CGSize(width: 80, height: 44)),
            
            WidgetDefinition(id: "widgetsBoard", slotEligibility: .widgetsBoard, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
            WidgetDefinition(id: "downloads", slotEligibility: .downloads, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
            WidgetDefinition(id: "trash", slotEligibility: .trash, defaultRule: .dock, fixedSize: CGSize(width: 44, height: 44)),
        ]
    }
    
    public func definition(for id: String) -> WidgetDefinition? {
        return definitions.first { $0.id == id }
    }
}
