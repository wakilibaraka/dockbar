import Foundation

let path = "Sources/DockBarCore/LayoutEngine.swift"
var content = try! String(contentsOfFile: path)

let oldLogic = """
        // Place Left & Right firmly (they don't compress per requirements)
        var curX = availableXMin
        for zl in leftZones {
            zoneFrames[zl.id] = CGRect(x: curX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
            curX += zl.naturalWidth
        }
        
        var rCurX = availableXMax
        for zl in rightZones.reversed() {
            rCurX -= zl.naturalWidth
            zoneFrames[zl.id] = CGRect(x: rCurX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
        }
        
        // Center compresses if needed
        if let centerZone = centerZones.first {
            let naturalW = centerZone.naturalWidth
            let preferredMinX = screen.minX + floor((screen.width - naturalW) / 2)
            let preferredMaxX = preferredMinX + naturalW
"""

let newLogic = """
        if g.shape == .compact {
            let centerZoneW = centerZones.first?.naturalWidth ?? 0
            let totalW = leftWidth + centerZoneW + rightWidth
            let gap: CGFloat = 8 // small gap between zones in compact mode
            let totalWithGaps = totalW + (leftZones.isEmpty ? 0 : gap) + (rightZones.isEmpty ? 0 : gap)
            
            var startX = screen.minX + floor((screen.width - totalWithGaps) / 2)
            
            for zl in leftZones {
                zoneFrames[zl.id] = CGRect(x: startX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
                startX += zl.naturalWidth + gap
            }
            if let centerZone = centerZones.first {
                zoneFrames[centerZone.id] = CGRect(x: startX, y: screen.minY + g.screenInsets.bottom, width: centerZone.naturalWidth, height: g.height)
                startX += centerZone.naturalWidth + gap
            }
            for zl in rightZones {
                zoneFrames[zl.id] = CGRect(x: startX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
                startX += zl.naturalWidth + gap
            }
        } else {
            // Place Left & Right firmly (they don't compress per requirements)
            var curX = availableXMin
            for zl in leftZones {
                zoneFrames[zl.id] = CGRect(x: curX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
                curX += zl.naturalWidth
            }
            
            var rCurX = availableXMax
            for zl in rightZones.reversed() {
                rCurX -= zl.naturalWidth
                zoneFrames[zl.id] = CGRect(x: rCurX, y: screen.minY + g.screenInsets.bottom, width: zl.naturalWidth, height: g.height)
            }
            
            // Center compresses if needed
            if let centerZone = centerZones.first {
                let naturalW = centerZone.naturalWidth
                let preferredMinX = screen.minX + floor((screen.width - naturalW) / 2)
                let preferredMaxX = preferredMinX + naturalW
"""

content = content.replacingOccurrences(of: oldLogic, with: newLogic)

let oldLogicClose = """
                if let taskSegIdx = centerZone.segments.firstIndex(where: { $0.slots.contains(.taskArea) }) {
                    let oldW = adjustedWidths[taskSegIdx] ?? 0
                    let difference = naturalW - finalWidth
                    adjustedWidths[taskSegIdx] = max(0, oldW - difference)
                }
            }
            
            zoneFrames[centerZone.id] = CGRect(x: constrainedMinX, y: screen.minY + g.screenInsets.bottom, width: finalWidth, height: g.height)
            
            // Replace the center zone info with adjusted widths
            let newCenterZone = ZoneLayoutInfo(id: centerZone.id, anchor: centerZone.anchor, measuredWidths: adjustedWidths, sizesBySlot: centerZone.sizesBySlot, naturalWidth: finalWidth, segments: centerZone.segments, hasTaskOverflow: centerZone.hasTaskOverflow || finalWidth < naturalW)
            centerZones[0] = newCenterZone
            
            // Re-update zonesLayout to reflect adjusted widths
            if let idx = zonesLayout.firstIndex(where: { $0.id == centerZone.id }) {
                zonesLayout[idx] = newCenterZone
            }
        }
"""

let newLogicClose = """
                if let taskSegIdx = centerZone.segments.firstIndex(where: { $0.slots.contains(.taskArea) }) {
                    let oldW = adjustedWidths[taskSegIdx] ?? 0
                    let difference = naturalW - finalWidth
                    adjustedWidths[taskSegIdx] = max(0, oldW - difference)
                }
            }
            
            zoneFrames[centerZone.id] = CGRect(x: constrainedMinX, y: screen.minY + g.screenInsets.bottom, width: finalWidth, height: g.height)
            
            // Replace the center zone info with adjusted widths
            let newCenterZone = ZoneLayoutInfo(id: centerZone.id, anchor: centerZone.anchor, measuredWidths: adjustedWidths, sizesBySlot: centerZone.sizesBySlot, naturalWidth: finalWidth, segments: centerZone.segments, hasTaskOverflow: centerZone.hasTaskOverflow || finalWidth < naturalW)
            centerZones[0] = newCenterZone
            
            // Re-update zonesLayout to reflect adjusted widths
            if let idx = zonesLayout.firstIndex(where: { $0.id == centerZone.id }) {
                zonesLayout[idx] = newCenterZone
            }
        }
        } // close else block
"""
content = content.replacingOccurrences(of: oldLogicClose, with: newLogicClose)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
