import Foundation

protocol ChromeGeometryProvider: AnyObject {
    func customChromeRects(for bounds: NSRect) -> [NSRect]?
}
