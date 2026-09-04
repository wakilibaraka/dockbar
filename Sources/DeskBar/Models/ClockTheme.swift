import AppKit

enum ClockTheme: String, CaseIterable {
    case none
    case ocean
    case violet
    case sunset
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .ocean: return "Ocean"
        case .violet: return "Violet"
        case .sunset: return "Sunset"
        }
    }
    
    /// Start and end colours for the gradient background (for dark appearance / glass overlay)
    var gradientColors: (start: NSColor, end: NSColor)? {
        switch self {
        case .none: return nil
        case .ocean: return (NSColor(red: 0.1, green: 0.6, blue: 0.85, alpha: 0.55),
                             NSColor(red: 0.0, green: 0.35, blue: 0.65, alpha: 0.55))
        case .violet: return (NSColor(red: 0.55, green: 0.2, blue: 0.90, alpha: 0.55),
                              NSColor(red: 0.35, green: 0.1, blue: 0.65, alpha: 0.55))
        case .sunset: return (NSColor(red: 0.95, green: 0.45, blue: 0.15, alpha: 0.55),
                              NSColor(red: 0.80, green: 0.20, blue: 0.40, alpha: 0.55))
        }
    }
    
    /// Text colour to use on top of this theme's gradient
    var textColor: NSColor {
        switch self {
        case .none: return .white
        default: return .white
        }
    }
}
