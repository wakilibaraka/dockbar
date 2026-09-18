import SwiftUI

struct HoldToQuitOverlayView: View {
    @ObservedObject var service = HoldToQuitService.shared
    
    var body: some View {
        if service.isShowingOverlay {
            ZStack {
                Color.black.opacity(0.7)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                VStack(spacing: 12) {
                    Image(systemName: service.symbol)
                        .font(.system(size: 36))
                        .foregroundColor(.primary)
                    
                    if service.progress > 0 {
                        ProgressView(value: service.progress)
                            .progressViewStyle(.linear)
                            .frame(width: 80)
                            .tint(.primary)
                    }
                }
                .padding(20)
            }
            .frame(width: 140, height: 140)
            .animation(.easeInOut(duration: 0.1), value: service.progress)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}
