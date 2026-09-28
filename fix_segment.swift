import Foundation

let path = "Sources/DockBarCore/TaskbarTheme.swift"
var content = try! String(contentsOfFile: path)

let segmentDecl = """
    public var contentInsets: EdgeInsets
    public var sizing: SegmentSizing
    public var slots: [SlotKind]

    public init(id: String, surface: SurfaceStyle, border: SegmentBorder, cornerRadius: CornerRadius, contentInsets: EdgeInsets, sizing: SegmentSizing, slots: [SlotKind]) {
"""
let newSegmentDecl = """
    public var contentInsets: EdgeInsets
    public var sizing: SegmentSizing
    public var minWidth: CGFloat?
    public var slots: [SlotKind]

    public init(id: String, surface: SurfaceStyle, border: SegmentBorder, cornerRadius: CornerRadius, contentInsets: EdgeInsets, sizing: SegmentSizing, minWidth: CGFloat? = nil, slots: [SlotKind]) {
        self.minWidth = minWidth
"""
content = content.replacingOccurrences(of: segmentDecl, with: newSegmentDecl)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
