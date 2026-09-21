import AppKit

final class ConnectivityTrayView: NSStackView {
    private static let fixedWidth: CGFloat = 116
    private let calendarWidget = CalendarWidgetView()
    private let quickSettingsWidget: QuickSettingsWidgetView

    init(settings: TaskbarSettings) {
        quickSettingsWidget = QuickSettingsWidgetView(settings: settings)
        super.init(frame: .zero)
        orientation = .horizontal
        alignment = .centerY
        spacing = 4

        addArrangedSubview(calendarWidget)
        addArrangedSubview(quickSettingsWidget)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func preferredContentWidth() -> CGFloat { Self.fixedWidth }
}
