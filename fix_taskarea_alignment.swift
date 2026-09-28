import Foundation

let path = "Sources/DockBarCore/LayoutEngine.swift"
var content = try! String(contentsOfFile: path)

let oldTaskAreaCode = """
                    if slot == .taskArea {
                        let btnW = input.theme.icons.hitTargetSize
                        for app in input.apps {
                            if slotX + btnW > segFrame.width - seg.contentInsets.right { break }
                            
                            // bFrame panel-local: segFrame.minX is already panel-local
                            let bFrame = CGRect(x: segFrame.minX + slotX, y: (g.height - input.theme.icons.hitTargetSize)/2, width: btnW, height: input.theme.icons.hitTargetSize)
                            taskButtonFrames[app.id] = bFrame
                            
                            let state: IndicatorState
                            if !app.isRunning { state = .none }
                            else if app.hasMultipleWindows { state = (app.id == input.activeAppID || app.isFocused) ? .groupedFocused : .unfocused }
                            else { state = (app.id == input.activeAppID || app.isFocused) ? .focused : .unfocused }
                            indicatorStates[app.id] = state
                            
                            let inset = input.theme.hover.inset
                            hoverRects[app.id] = bFrame.insetBy(dx: inset, dy: inset)
                            
                            slotX += btnW + input.theme.icons.spacing
                        }
                    } else if let widgetsInSlot = zl.sizesBySlot[slot] {
"""

let newTaskAreaCode = """
                    if slot == .taskArea {
                        let btnW = input.theme.icons.hitTargetSize
                        let areaWidth = taskAreaWidth(apps: input.apps, icons: input.theme.icons)
                        
                        var alignOffset: CGFloat = 0
                        if input.appAlignment == "centered" && (seg.sizing == .fill || seg.minWidth != nil) {
                            // If we have extra space in this segment, center the task area
                            // Calculate total width of all slots in this segment
                            var allSlotsW: CGFloat = 0
                            for s in seg.slots {
                                if s == .taskArea { allSlotsW += areaWidth }
                                else if let ws = zl.sizesBySlot[s] {
                                    for w in ws { allSlotsW += w.size.width + input.theme.icons.spacing }
                                }
                            }
                            let extraSpace = segFrame.width - seg.contentInsets.left - seg.contentInsets.right - allSlotsW
                            if extraSpace > 0 { alignOffset = extraSpace / 2.0 }
                        }
                        
                        slotX += alignOffset
                        
                        for app in input.apps {
                            if slotX + btnW > segFrame.width - seg.contentInsets.right + alignOffset { break } // allow overflowing visually if centered
                            
                            let bFrame = CGRect(x: segFrame.minX + slotX, y: (g.height - input.theme.icons.hitTargetSize)/2, width: btnW, height: input.theme.icons.hitTargetSize)
                            taskButtonFrames[app.id] = bFrame
                            
                            let state: IndicatorState
                            if !app.isRunning { state = .none }
                            else if app.hasMultipleWindows { state = (app.id == input.activeAppID || app.isFocused) ? .groupedFocused : .unfocused }
                            else { state = (app.id == input.activeAppID || app.isFocused) ? .focused : .unfocused }
                            indicatorStates[app.id] = state
                            
                            let inset = input.theme.hover.inset
                            hoverRects[app.id] = bFrame.insetBy(dx: inset, dy: inset)
                            
                            slotX += btnW + input.theme.icons.spacing
                        }
                    } else if let widgetsInSlot = zl.sizesBySlot[slot] {
"""

content = content.replacingOccurrences(of: oldTaskAreaCode, with: newTaskAreaCode)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
