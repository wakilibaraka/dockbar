import AppKit

/// The rules that decide how wide one task button wants to be, and whether it has room
/// for its title.
///
/// These lived inside `TaskButtonView`, which is a 1,600-line view with hover previews,
/// drag sessions, and context menus. Because the rules were interleaved with all of
/// that, they could only be tested through the view's static helpers, and the minimum
/// and icon-only rules had no coverage at all.
enum TaskButtonWidthPlanner {
    /// Minimum width of a button, given how the bar is laid out and what the button
    /// carries.
    ///
    /// * With titles hidden, a button is just its icon, so it tracks the bar height.
    /// * In adaptive mode the bar compresses buttons to save room, so the floor drops.
    /// * A button with a plugin action button needs room for that button as well.
    static func minimumWidth(
        showsTitles: Bool,
        usesAdaptiveWidth: Bool,
        showsPluginActionButton: Bool,
        taskbarHeight: CGFloat,
        minimumTaskWidth: CGFloat,
        minimumPluginActionTaskWidth: CGFloat,
        minimumAdaptiveTaskWidth: CGFloat,
        minimumAdaptivePluginActionTaskWidth: CGFloat
    ) -> CGFloat {
        guard showsTitles else {
            return taskbarHeight + DesignSystem.Metrics.iconOnlyInset
        }
        if usesAdaptiveWidth {
            return showsPluginActionButton ? minimumAdaptivePluginActionTaskWidth : minimumAdaptiveTaskWidth
        }
        return showsPluginActionButton ? minimumPluginActionTaskWidth : minimumTaskWidth
    }

    /// The narrowest a button may get while still showing its title.
    static func titleThreshold(
        showsPluginActionButton: Bool,
        minimumTaskWidth: CGFloat,
        minimumPluginActionTaskWidth: CGFloat
    ) -> CGFloat {
        showsPluginActionButton ? minimumPluginActionTaskWidth : minimumTaskWidth
    }

    /// Whether a button of this width should drop its title and show the icon alone.
    ///
    /// Only ever true in adaptive mode: outside it, the button is sized to fit whatever
    /// it has, so a title that would not fit was already truncated upstream.
    static func usesIconOnlyLayout(
        effectiveWidth: CGFloat,
        usesAdaptiveWidth: Bool,
        showsTitles: Bool,
        showsPluginActionButton: Bool,
        minimumTaskWidth: CGFloat,
        minimumPluginActionTaskWidth: CGFloat
    ) -> Bool {
        guard usesAdaptiveWidth, showsTitles else {
            return false
        }
        let threshold = titleThreshold(
            showsPluginActionButton: showsPluginActionButton,
            minimumTaskWidth: minimumTaskWidth,
            minimumPluginActionTaskWidth: minimumPluginActionTaskWidth
        )
        return effectiveWidth < threshold
    }

    /// Whether the plugin's inline action button still fits beside the icon.
    static func showsInlinePluginActionButton(
        effectiveWidth: CGFloat,
        showsPluginActionButton: Bool,
        minimumInlinePluginActionTaskWidth: CGFloat
    ) -> Bool {
        showsPluginActionButton && effectiveWidth >= minimumInlinePluginActionTaskWidth
    }
}