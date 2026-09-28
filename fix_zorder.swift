import Foundation

let path = "Sources/DockBarCore/ThemeContainerView.swift"
var content = try! String(contentsOfFile: path)

let oldAddSegment = """
            } else {
                sv = SegmentView(segment: segment)
                addSubview(sv)
                segmentViews[segment.id] = sv
            }
"""

let newAddSegment = """
            } else {
                sv = SegmentView(segment: segment)
                // Insert segments at the bottom (z-index 0) so they don't cover widgets/buttons
                addSubview(sv, positioned: .below, relativeTo: nil)
                segmentViews[segment.id] = sv
            }
"""

content = content.replacingOccurrences(of: oldAddSegment, with: newAddSegment)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
