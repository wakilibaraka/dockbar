import re

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

# 1. Replace declaration
content = content.replace(
    "private let runningAppTrayView: RunningAppTrayView",
    "private let runningAppTrayView = DummyTrayView()"
)

# 2. Remove initialization
content = re.sub(
    r"\s*runningAppTrayView = RunningAppTrayView\(\n\s*displayID: displayID,\n\s*settings: settings,\n\s*appGroupManager: appGroupManager,\n\s*windowManager: windowManager\n\s*\)\n",
    "\n",
    content
)

# 3. Add DummyTrayView at the end of the file
dummy_class = """
private class DummyTrayView: NSView {
    var preferredWidthDidChange: (() -> Void)? = nil
    func refresh() {}
    func plannedContentWidth(visibleApplicationCapacity: Int?) -> CGFloat { return 0 }
    func minimumOverflowContentWidth() -> CGFloat { return 0 }
    func visibleApplicationCapacity(fitting: CGFloat) -> Int? { return nil }
    func setVisibleApplicationCapacity(_ capacity: Int?, notifiesPreferredWidthChange: Bool) {}
    override var intrinsicContentSize: NSSize { .zero }
}
"""
content += dummy_class

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)
