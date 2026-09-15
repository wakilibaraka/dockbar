import AppKit
import SwiftUI

final class StatsWidgetHostingView: NSHostingView<StatsWidgetView> {
    var action: (() -> Void)?
    
    init() {
        super.init(rootView: StatsWidgetView())
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    @available(*, unavailable)
    @MainActor dynamic required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required init(rootView: StatsWidgetView) {
        super.init(rootView: rootView)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func mouseDown(with event: NSEvent) {
        action?()
    }
}
