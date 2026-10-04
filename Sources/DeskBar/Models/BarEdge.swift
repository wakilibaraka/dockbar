import CoreGraphics
import Foundation

/// Which screen edge the bar sits on.
///
/// This replaces the old `DockPosition`, which could only ever describe a bar along the
/// bottom and encoded two unrelated ideas — which edge, and whether it spans or hugs —
/// as six combinations that were really three. `eskele` puts its bar on the left or
/// right edge, which is a shape DockBar had no way to express at all.
enum BarEdge: String, CaseIterable, Identifiable, Codable, Sendable {
    case left
    case bottom
    case right

    var id: String { rawValue }

    /// The axis the bar's cells run along.
    var axis: BarAxis {
        switch self {
        case .left, .right: return .vertical
        case .bottom: return .horizontal
        }
    }

    var isVertical: Bool { self != .bottom }

    /// The matching `com.apple.dock orientation` value, for reserved-space mode.
    var dockOrientation: String { rawValue }

    var displayName: String {
        switch self {
        case .left: return "Left"
        case .bottom: return "Bottom"
        case .right: return "Right"
        }
    }

    /// Accepts the `DockPosition` values older installs persisted, so upgrading keeps the
    /// bar where the user put it rather than resetting it to the default edge.
    init?(persistedRawValue: String) {
        switch persistedRawValue {
        case "bottomCenter": self = .bottom
        case "bottomLeft": self = .bottom
        case "floatingCenter": self = .bottom
        default: self.init(rawValue: persistedRawValue)
        }
    }
}

/// The axis a bar runs along.
enum BarAxis: Sendable {
    case horizontal
    case vertical

    var isVertical: Bool { self == .vertical }
}

/// Whether the bar spans the whole edge or only as long as its contents.
enum BarSpan: String, CaseIterable, Identifiable, Codable, Sendable {
    case fullSpan
    case hugContents

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullSpan: return "Full Edge"
        case .hugContents: return "Fit to Contents"
        }
    }

    var detail: String {
        switch self {
        case .fullSpan: return "The bar runs the whole edge, like the macOS Dock."
        case .hugContents: return "The bar is only as long as its buttons, and floats clear of the edge."
        }
    }

    /// Older installs stored the span as part of `DockPosition`.
    init?(persistedFromDockPosition rawValue: String) {
        switch rawValue {
        case "bottomCenter": self = .fullSpan
        case "bottomLeft", "floatingCenter": self = .hugContents
        default: return nil
        }
    }
}