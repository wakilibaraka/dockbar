import sys

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'r') as f:
    content = f.read()

content = content.replace(
"""
private class DummyTrayView: NSView {
    var preferredWidthDidChange: (() -> Void)? = nil
    func refresh() {}
    func plannedContentWidth(visibleApplicationCapacity: Int?) -> CGFloat { return 0 }
    func minimumOverflowContentWidth() -> CGFloat { return 0 }
    func visibleApplicationCapacity(fitting: CGFloat) -> Int? { return nil }
    func setVisibleApplicationCapacity(_ capacity: Int?, notifiesPreferredWidthChange: Bool) {}
    override var intrinsicContentSize: NSSize { .zero }
}
""", ""
)

dummy_inside = """
    class DummyTrayView: NSView {
        var preferredWidthDidChange: (() -> Void)? = nil
        func refresh() {}
        func plannedContentWidth(visibleApplicationCapacity: Int?) -> CGFloat { return 0 }
        func minimumOverflowContentWidth() -> CGFloat { return 0 }
        func visibleApplicationCapacity(fitting: CGFloat) -> Int? { return nil }
        func setVisibleApplicationCapacity(_ capacity: Int?, notifiesPreferredWidthChange: Bool) {}
        override var intrinsicContentSize: NSSize { .zero }
    }
"""

content = content.replace("final class TaskbarContentView: NSView {", "final class TaskbarContentView: NSView {\n" + dummy_inside)

with open('Sources/DeskBar/Views/TaskbarContentView.swift', 'w') as f:
    f.write(content)
