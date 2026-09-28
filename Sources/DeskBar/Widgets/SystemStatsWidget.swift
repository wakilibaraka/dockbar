import SwiftUI
import AppKit
import DockBarCore

struct SystemStatsWidgetDescriptor: WidgetDescriptor {
    let id = "systemStats"
    let preferredSize = CGSize(width: 70, height: 44)
    let defaultRule: WidgetLocation = .dock
    
    func makeView(context: WidgetContext) -> NSView {
        let view = NSHostingView(rootView: NewSystemStatsWidgetView(context: context))
        view.sizingOptions = []
        return view
    }
}

struct NewSystemStatsWidgetView: View {
    let context: WidgetContext
    @StateObject private var monitor = WidgetEngine.shared.systemResourceMonitor
    
    private var percent: Double {
        monitor.snapshot.memoryUsedPercent ?? 0
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cpu")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Text(String(format: "%.0f%% RAM", percent))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(height: 44)
        .padding(.horizontal, 6)
        .onTapGesture {
            context.openFlyout(AnyView(SystemStatsFlyoutView(
                monitor: WidgetEngine.shared.systemResourceMonitor,
                windowManager: WindowManager.shared
            )))
        }
    }
}
