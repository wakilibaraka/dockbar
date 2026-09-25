import AppKit
import Combine

final class DockBatteryWidgetView: NSView {
    private let button = NSButton()
    private var cancellables = Set<AnyCancellable>()
    private let settings: TaskbarSettings
    private let fixedWidth: CGFloat = 44
    
    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init(frame: .zero)
        
        button.isBordered = false
        button.title = ""
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: fixedWidth)
        ])
        
        BatteryMonitor.shared.$state
            .combineLatest(
                settings.$batteryIconStyle.setFailureType(to: Never.self),
                settings.$showPercentageInsideIcon.setFailureType(to: Never.self)
            )
            .combineLatest(
                settings.$batteryIconSize.setFailureType(to: Never.self)
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tuple1, size in
                let (state, style, showInside) = tuple1
                self?.button.image = BatteryStatusRenderer.renderImage(for: state, style: style, size: size, showTextInside: showInside)
            }
            .store(in: &cancellables)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    func preferredContentWidth() -> CGFloat {
        return fixedWidth
    }
}
