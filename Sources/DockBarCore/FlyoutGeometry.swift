import Foundation

public struct FlyoutGeometry {
    public static func calculateFrame(
        anchor: CGRect,
        contentSize: CGSize,
        visibleFrame: CGRect,
        spacing: CGFloat
    ) -> CGRect {
        var panelWidth = contentSize.width
        var panelHeight = contentSize.height
        
        var originY: CGFloat
        if anchor.minY > visibleFrame.midY {
            // Anchor is in the top half of the screen (e.g. top dock). Open DOWNWARD.
            originY = anchor.minY - spacing - panelHeight
            if originY < visibleFrame.minY + spacing {
                let overflow = (visibleFrame.minY + spacing) - originY
                panelHeight -= overflow
                originY = visibleFrame.minY + spacing
            }
        } else {
            // Anchor is in the bottom half of the screen (e.g. bottom dock). Open UPWARD.
            originY = anchor.maxY + spacing
            if originY + panelHeight > visibleFrame.maxY - spacing {
                panelHeight = (visibleFrame.maxY - spacing) - originY
            }
        }
        
        var originX = anchor.midX - (panelWidth / 2)
        if panelWidth > visibleFrame.width { panelWidth = visibleFrame.width }
        
        if originX < visibleFrame.minX + spacing {
            originX = visibleFrame.minX + spacing
        } else if originX + panelWidth > visibleFrame.maxX - spacing {
            originX = visibleFrame.maxX - panelWidth - spacing
        }
        
        return CGRect(x: originX, y: originY, width: panelWidth, height: panelHeight)
    }
}
