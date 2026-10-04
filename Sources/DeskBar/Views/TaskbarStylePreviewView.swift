import SwiftUI

/// A miniature, live rendering of a bar style.
///
/// It is built from `TaskbarStyleSpec`, the same value the real bar lays out from, so the
/// preview cannot drift from the bar: if a style stops grouping, or starts trailing the
/// widget cluster, the picture changes with it.
struct TaskbarStylePreviewView: View {
    let spec: TaskbarStyleSpec
    var isSelected: Bool = false
    var windowCount: Int = 3

    private var accent: Color {
        isSelected ? Color.accentColor : Color.primary.opacity(0.55)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer(minLength: 0)
                bar(in: proxy.size)
                Spacer(minLength: 0)
            }
        }
        .accessibilityHidden(true)
    }

    private func bar(in size: CGSize) -> some View {
        HStack(spacing: 6) {
            // The launcher leads every style; only its treatment differs.
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accent)
                .frame(width: 9, height: 9)

            if spec.windowClusterTrailsWidgets {
                cluster
                widgets
            } else {
                widgets
                cluster
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(width: barWidth(in: size.width))
        .background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.primary.opacity(isSelected ? 0.25 : 0.12), lineWidth: 1)
        )
    }

    /// The layout the bar will actually use. A style that does not force one defers to
    /// the user's picker; the preview shows the compact default in that case.
    private var effectiveLayout: DeskBarLayoutMode {
        spec.layoutMode ?? .compactGlass
    }

    /// Whether the bar fills the available width or hugs its contents.
    private func barWidth(in available: CGFloat) -> CGFloat {
        switch effectiveLayout {
        case .fullWidth, .fullWidthGlass:
            return available
        case .compact, .compactGlass:
            return min(available * 0.62, 210)
        }
    }

    private var radius: CGFloat {
        switch effectiveLayout {
        case .fullWidth, .fullWidthGlass:
            return spec.usesCompactContentWidth ? DesignSystem.Shape.chipCornerRadius : 0
        case .compact, .compactGlass:
            return DesignSystem.Shape.flyoutCornerRadius
        }
    }

    private var background: Color {
        // Roughly mirrors how each material reads against the desktop, so the preview
        // still distinguishes "solid bar" from "translucent bar".
        switch spec.material {
        case .sidebar, .hudWindow:
            return Color.primary.opacity(0.16)
        case .contentBackground:
            return Color.primary.opacity(0.22)
        default:
            return Color.primary.opacity(0.12)
        }
    }

    /// One button per window, or a single grouped button per app.
    @ViewBuilder
    private var cluster: some View {
        if spec.resolvedGrouping(userChoice: false) {
            HStack(spacing: 4) {
                taskButton(active: true)
                taskButton(active: false)
            }
        } else {
            HStack(spacing: 4) {
                ForEach(0..<max(1, windowCount), id: \.self) { index in
                    taskButton(active: index == 0)
                }
            }
        }
    }

    private func taskButton(active: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(active ? accent : Color.primary.opacity(0.3))
                .frame(width: 14, height: 14)
            if spec.runningIndicator == .dot && active {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 3)
                    .offset(y: 6)
            }
            if spec.runningIndicator == .windowCount && active {
                Text("2")
                    .font(.system(size: 5, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .offset(x: 7, y: 6)
            }
        }
    }

    @ViewBuilder
    private var widgets: some View {
        if spec.hostsWidgetsInBar {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 10, height: 5)
                }
            }
        }
    }
}

/// The style chooser: cards with a live preview, selection state, and the style's own
/// description. Shared by onboarding and the Taskbar settings page so the two cannot
/// disagree about what a style looks like.
struct TaskbarStylePicker: View {
    @Binding var selection: TaskbarMode

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(TaskbarMode.allCases) { mode in
                TaskbarStyleCard(
                    mode: mode,
                    isSelected: selection == mode
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = mode }
                }
            }
        }
    }
}

struct TaskbarStyleCard: View {
    let mode: TaskbarMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: mode.symbolName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    Text(mode.displayName)
                        .font(.body.weight(.semibold))
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }

                TaskbarStylePreviewView(spec: mode.spec, isSelected: isSelected)
                    .frame(height: 56)
                    .padding(.vertical, 2)

                Text(mode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Shape.cardCornerRadius, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Shape.cardCornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.15),
                        lineWidth: DesignSystem.Shape.hairline
                    )
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .help(mode.subtitle)
    }
}