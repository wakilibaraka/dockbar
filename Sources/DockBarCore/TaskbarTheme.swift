
public enum ZoneAnchor: String, Codable, Equatable {
    case leadingEdge
    case center
    case trailingEdge
}

public struct Zone: Codable, Equatable, Identifiable {
    public var id: String
    public var anchor: ZoneAnchor
    public var interSegmentGap: CGFloat
    public var segments: [Segment]

    public init(id: String, anchor: ZoneAnchor, interSegmentGap: CGFloat, segments: [Segment]) {
        self.id = id
        self.anchor = anchor
        self.interSegmentGap = interSegmentGap
        self.segments = segments
    }
}

import Foundation
import CoreGraphics

// MARK: - Root Theme

/// A declarative, Codable description of how one taskbar mode looks.
/// The only thing that differs between modes is this value.
/// Views must not branch on identity — they render whatever geometry they receive.
public struct TaskbarTheme: Codable, Equatable {
    public var id: String
    public var displayName: String

    /// Overall bar shape / height / screen-edge insets. Shared across all segments.
    public var geometry: BarGeometry
    /// How the segment cluster sits on screen.
    public var zones: [Zone]

    public var icons: IconStyle
    public var indicator: IndicatorStyle
    public var hover: HoverStyle
    /// Clock / battery display rules — consumed by whichever segment carries tray slots.
    public var tray: TrayStyle

    public init(
        id: String, displayName: String,
        geometry: BarGeometry, zones: [Zone],
        icons: IconStyle, indicator: IndicatorStyle,
        hover: HoverStyle, tray: TrayStyle
    ) {
        self.id = id; self.displayName = displayName
        self.geometry = geometry; self.zones = zones
        self.icons = icons; self.indicator = indicator
        self.hover = hover; self.tray = tray
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.geometry = try container.decode(BarGeometry.self, forKey: .geometry)
        self.icons = try container.decode(IconStyle.self, forKey: .icons)
        self.indicator = try container.decode(IndicatorStyle.self, forKey: .indicator)
        self.hover = try container.decode(HoverStyle.self, forKey: .hover)
        self.tray = try container.decode(TrayStyle.self, forKey: .tray)
        
        if let zones = try? container.decode([Zone].self, forKey: .zones) {
            self.zones = zones
        } else {
            let alignment = try container.decode(ContentAlignment.self, forKey: CodingKeys(stringValue: "alignment")!)
            let interSegmentGap = try container.decode(CGFloat.self, forKey: CodingKeys(stringValue: "interSegmentGap")!)
            let segments = try container.decode([Segment].self, forKey: CodingKeys(stringValue: "segments")!)
            let anchor: ZoneAnchor = {
                switch alignment {
                case .leading: return .leadingEdge
                case .center: return .center
                case .trailing: return .trailingEdge
                }
            }()
            self.zones = [Zone(id: "main", anchor: anchor, interSegmentGap: interSegmentGap, segments: segments)]
        }
    }
    
    // Explicit CodingKeys to handle the custom decode
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(geometry, forKey: .geometry)
        try container.encode(zones, forKey: .zones)
        try container.encode(icons, forKey: .icons)
        try container.encode(indicator, forKey: .indicator)
        try container.encode(hover, forKey: .hover)
        try container.encode(tray, forKey: .tray)
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
        
        static let id = CodingKeys(stringValue: "id")!
        static let displayName = CodingKeys(stringValue: "displayName")!
        static let geometry = CodingKeys(stringValue: "geometry")!
        static let zones = CodingKeys(stringValue: "zones")!
        static let icons = CodingKeys(stringValue: "icons")!
        static let indicator = CodingKeys(stringValue: "indicator")!
        static let hover = CodingKeys(stringValue: "hover")!
        static let tray = CodingKeys(stringValue: "tray")!
    }
}

// MARK: - Segment

/// One independently-styled surface that holds a subset of slots (launcher, apps, tray…).
/// Derived from Windhawk's TaskbarBackground / SystemTrayFrameGrid model where each
/// background is its own element with its own surface, border, corner-radius, padding.
public struct Segment: Codable, Equatable {
    public var id: String
    public var surface: SurfaceStyle
    public var border: SegmentBorder
    public var cornerRadius: CornerRadius
    /// Inner padding — content must not touch the segment edge.
    public var contentInsets: EdgeInsets
    /// How the segment determines its own width.
    public var sizing: SegmentSizing
    public var minWidth: CGFloat? = nil
    /// Which logical content this segment carries, in display order.
    public var slots: [SlotKind]

    public init(id: String, surface: SurfaceStyle, border: SegmentBorder, cornerRadius: CornerRadius, contentInsets: EdgeInsets, sizing: SegmentSizing, minWidth: CGFloat? = nil, slots: [SlotKind]) {
        self.id = id; self.surface = surface; self.border = border; self.cornerRadius = cornerRadius; self.contentInsets = contentInsets; self.sizing = sizing; self.minWidth = minWidth; self.slots = slots
    }

    public init(
        id: String, surface: SurfaceStyle, border: SegmentBorder,
        cornerRadius: CornerRadius, contentInsets: EdgeInsets,
        sizing: SegmentSizing, slots: [SlotKind]
    ) {
        self.id = id; self.surface = surface; self.border = border
        self.cornerRadius = cornerRadius; self.contentInsets = contentInsets
        self.sizing = sizing; self.slots = slots
    }
}

public enum SlotKind: String, Codable, Equatable {
    case startButton    // launcher / Win key button
    case leading        // left-side widgets (weather, etc.)
    case taskArea       // running app buttons (core)
    case tray           // clock, battery, connectivity, quick-settings
}

public enum SegmentSizing: Codable, Equatable {
    /// Fixed width in points (e.g. tray segment ≈ 260 pt).
    case fixed(width: CGFloat)
    /// Segment shrinks / grows to fit its icon content exactly.
    case hugContents
    /// Segment fills remaining available width (full-width unified bar).
    case fill
}

// MARK: - Surface

public enum SurfaceStyle: Codable, Equatable {
    /// Opaque solid fill — the DEFAULT; preserves current look.
    /// `colorToken` is a semantic name looked up in the renderer (e.g. "barSurface").
    case solid(colorToken: String)
    /// Native `NSVisualEffectView` acrylic — explicit opt-in only.
    case acrylic(tintToken: String, opacity: Double)
    /// Appearance-adaptive: different token per macOS appearance.
    case adaptive(light: String, dark: String)
}

// MARK: - Segment Border

public struct SegmentBorder: Codable, Equatable {
    /// Semantic color token (e.g. "surfaceStrokeDefault" → 1-pt white @ 12% opacity).
    public var colorToken: String
    public var thickness: CGFloat
    public var enabled: Bool

    public init(colorToken: String, thickness: CGFloat, enabled: Bool) {
        self.colorToken = colorToken; self.thickness = thickness; self.enabled = enabled
    }

    public static let none = SegmentBorder(colorToken: "", thickness: 0, enabled: false)
    public static let `default` = SegmentBorder(colorToken: "surfaceStrokeDefault", thickness: 1, enabled: true)
}

// MARK: - Corner Radius

public struct CornerRadius: Codable, Equatable {
    public var topLeft: CGFloat
    public var topRight: CGFloat
    public var bottomLeft: CGFloat
    public var bottomRight: CGFloat

    public init(topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat) {
        self.topLeft = topLeft; self.topRight = topRight
        self.bottomLeft = bottomLeft; self.bottomRight = bottomRight
    }

    /// Convenience — uniform radius on all four corners.
    public init(all radius: CGFloat) {
        self.init(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
    }

    public static let zero = CornerRadius(all: 0)
}

// MARK: - Edge Insets (Codable replacement for NSEdgeInsets)

public struct EdgeInsets: Codable, Equatable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top; self.left = left; self.bottom = bottom; self.right = right
    }

    public static let zero = EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}

// MARK: - Bar Geometry

public enum BarShape: String, Codable, Equatable {
    /// Edge-to-edge, square corners, sits at screen bottom with no gap.
    case fullWidth
    /// Pill / card floating above the dock with configurable screen-edge insets.
    case floating
}

public struct BarGeometry: Codable, Equatable {
    public var shape: BarShape
    /// Bar content height in points (NOT including floating bottom gap).
    public var height: CGFloat
    /// Screen-edge insets (pt): used when `shape == .floating`.
    public var screenInsets: EdgeInsets

    public init(shape: BarShape, height: CGFloat, screenInsets: EdgeInsets) {
        self.shape = shape; self.height = height; self.screenInsets = screenInsets
    }
}

// MARK: - Alignment

public enum ContentAlignment: String, Codable, Equatable {
    case leading
    case center
    case trailing
}

// MARK: - Icon, Indicator, Hover, Tray Styles

public struct IconStyle: Codable, Equatable {
    public var size: CGFloat
    public var spacing: CGFloat
    /// Width/height of the tappable button hit-target (usually ≥ size).
    public var hitTargetSize: CGFloat

    public init(size: CGFloat, spacing: CGFloat, hitTargetSize: CGFloat) {
        self.size = size; self.spacing = spacing; self.hitTargetSize = hitTargetSize
    }
}

public enum IndicatorKind: String, Codable, Equatable {
    case win11Line  // centered horizontal bar under icon
    case dots       // small dot(s) under icon
    case none
}

public struct IndicatorStyle: Codable, Equatable {
    public var kind: IndicatorKind
    public var unfocusedWidth: CGFloat
    public var focusedWidth: CGFloat
    public var thickness: CGFloat
    public var groupedSegmented: Bool
    /// Semantic color token (e.g. "accent" → `NSColor.controlAccentColor`).
    public var colorToken: String
    public var minimizedIconOpacity: Double
    public var animationDuration: TimeInterval

    public init(
        kind: IndicatorKind, unfocusedWidth: CGFloat, focusedWidth: CGFloat,
        thickness: CGFloat, groupedSegmented: Bool, colorToken: String,
        minimizedIconOpacity: Double, animationDuration: TimeInterval
    ) {
        self.kind = kind; self.unfocusedWidth = unfocusedWidth; self.focusedWidth = focusedWidth
        self.thickness = thickness; self.groupedSegmented = groupedSegmented
        self.colorToken = colorToken; self.minimizedIconOpacity = minimizedIconOpacity
        self.animationDuration = animationDuration
    }
}

public struct HoverStyle: Codable, Equatable {
    public var cornerRadius: CGFloat
    public var inset: CGFloat
    public var fillOpacity: Double
    public var animationDuration: TimeInterval

    public init(cornerRadius: CGFloat, inset: CGFloat, fillOpacity: Double, animationDuration: TimeInterval) {
        self.cornerRadius = cornerRadius; self.inset = inset
        self.fillOpacity = fillOpacity; self.animationDuration = animationDuration
    }
}

public struct TrayStyle: Codable, Equatable {
    public var iconSize: CGFloat
    public var clockUsesLocale: Bool
    public var clockStacked: Bool
    public var batteryAmberBelow: Int
    public var batteryRedBelow: Int

    public init(
        iconSize: CGFloat, clockUsesLocale: Bool, clockStacked: Bool,
        batteryAmberBelow: Int, batteryRedBelow: Int
    ) {
        self.iconSize = iconSize; self.clockUsesLocale = clockUsesLocale
        self.clockStacked = clockStacked
        self.batteryAmberBelow = batteryAmberBelow; self.batteryRedBelow = batteryRedBelow
    }
}
