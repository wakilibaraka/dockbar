import AppKit

enum RunningIndicatorStyle: String, CaseIterable {
    case backgroundFill
    case dot
    case underline
    
    var displayName: String {
        switch self {
        case .backgroundFill: return "Background Fill (Classic)"
        case .dot: return "Dot"
        case .underline: return "Underline"
        }
    }
}
