import Foundation
import Testing
@testable import DockBar

/// `TaskButtonWidthPlanner` holds the rules that were interleaved with a 1,600-line
/// view. These tests pin them, especially the minimums and the icon-only fallback, which
/// previously had no coverage.
struct TaskButtonWidthPlannerTests {
    private let minimumTaskWidth: CGFloat = 56
    private let minimumPluginActionTaskWidth: CGFloat = 88
    private let minimumAdaptiveTaskWidth: CGFloat = 32
    private let minimumAdaptivePluginActionTaskWidth: CGFloat = 32
    private let minimumInlinePluginActionTaskWidth: CGFloat = 72
    private let taskbarHeight: CGFloat = 44

    private func minimum(
        showsTitles: Bool = true,
        usesAdaptiveWidth: Bool = false,
        showsPluginActionButton: Bool = false
    ) -> CGFloat {
        TaskButtonWidthPlanner.minimumWidth(
            showsTitles: showsTitles,
            usesAdaptiveWidth: usesAdaptiveWidth,
            showsPluginActionButton: showsPluginActionButton,
            taskbarHeight: taskbarHeight,
            minimumTaskWidth: minimumTaskWidth,
            minimumPluginActionTaskWidth: minimumPluginActionTaskWidth,
            minimumAdaptiveTaskWidth: minimumAdaptiveTaskWidth,
            minimumAdaptivePluginActionTaskWidth: minimumAdaptivePluginActionTaskWidth
        )
    }

    private func iconOnly(
        effectiveWidth: CGFloat,
        usesAdaptiveWidth: Bool = true,
        showsTitles: Bool = true,
        showsPluginActionButton: Bool = false
    ) -> Bool {
        TaskButtonWidthPlanner.usesIconOnlyLayout(
            effectiveWidth: effectiveWidth,
            usesAdaptiveWidth: usesAdaptiveWidth,
            showsTitles: showsTitles,
            showsPluginActionButton: showsPluginActionButton,
            minimumTaskWidth: minimumTaskWidth,
            minimumPluginActionTaskWidth: minimumPluginActionTaskWidth
        )
    }

    // MARK: Minimums

    @Test
    func hiddenTitlesSizeTheButtonToTheBarHeight() {
        // No title, so the button is just an icon: the bar height is the whole story.
        #expect(minimum(showsTitles: false) == taskbarHeight + 8)
        // Adaptive mode does not change that; it only compresses buttons that have titles.
        #expect(minimum(showsTitles: false, usesAdaptiveWidth: true) == taskbarHeight + 8)
    }

    @Test
    func aTallerBarProducesTallerIconOnlyButtons() {
        let tall = TaskButtonWidthPlanner.minimumWidth(
            showsTitles: false,
            usesAdaptiveWidth: false,
            showsPluginActionButton: false,
            taskbarHeight: 72,
            minimumTaskWidth: minimumTaskWidth,
            minimumPluginActionTaskWidth: minimumPluginActionTaskWidth,
            minimumAdaptiveTaskWidth: minimumAdaptiveTaskWidth,
            minimumAdaptivePluginActionTaskWidth: minimumAdaptivePluginActionTaskWidth
        )
        #expect(tall == 80)
    }

    @Test
    func adaptiveModeLowersTheFloorSoTheBarCanCompress() {
        #expect(minimum(usesAdaptiveWidth: true) == minimumAdaptiveTaskWidth)
        #expect(minimum(usesAdaptiveWidth: false) == minimumTaskWidth)
    }

    @Test
    func aPluginActionButtonRaisesTheFloorInBothModes() {
        #expect(minimum(showsPluginActionButton: true) == minimumPluginActionTaskWidth)
        #expect(
            minimum(usesAdaptiveWidth: true, showsPluginActionButton: true)
                == minimumAdaptivePluginActionTaskWidth
        )
    }

    @Test
    func adaptiveMinimumsNeverExceedTheFixedOnes() {
        // Otherwise "adaptive" would make buttons wider when the bar is tightest.
        #expect(minimumAdaptiveTaskWidth < minimumTaskWidth)
        #expect(minimumAdaptivePluginActionTaskWidth <= minimumAdaptiveTaskWidth)
    }

    // MARK: Title threshold

    @Test
    func theTitleThresholdRisesWhenThereIsAPluginButton() {
        #expect(
            TaskButtonWidthPlanner.titleThreshold(
                showsPluginActionButton: false,
                minimumTaskWidth: minimumTaskWidth,
                minimumPluginActionTaskWidth: minimumPluginActionTaskWidth
            ) == minimumTaskWidth
        )
        #expect(
            TaskButtonWidthPlanner.titleThreshold(
                showsPluginActionButton: true,
                minimumTaskWidth: minimumTaskWidth,
                minimumPluginActionTaskWidth: minimumPluginActionTaskWidth
            ) == minimumPluginActionTaskWidth
        )
    }

    // MARK: Icon-only fallback

    @Test
    func adaptiveButtonsDropTheirTitleWhenTooNarrow() {
        #expect(iconOnly(effectiveWidth: minimumTaskWidth - 1))
        #expect(!iconOnly(effectiveWidth: minimumTaskWidth))
        #expect(!iconOnly(effectiveWidth: minimumTaskWidth + 40))
    }

    @Test
    func aPluginButtonMakesTheTitleDropSooner() {
        // The icon is more load-bearing than the title, so when a button also has to fit
        // a plugin action button, the title is what gets sacrificed first.
        let width: CGFloat = 70
        #expect(!iconOnly(effectiveWidth: width))
        #expect(iconOnly(effectiveWidth: width, showsPluginActionButton: true))
    }

    @Test
    func nonAdaptiveButtonsNeverGoIconOnly() {
        // Outside adaptive mode the button is already sized to its content, so dropping
        // the title would fight the layout rather than help it.
        #expect(!iconOnly(effectiveWidth: 10, usesAdaptiveWidth: false))
        #expect(!iconOnly(effectiveWidth: 10, usesAdaptiveWidth: false, showsTitles: false))
    }

    @Test
    func buttonsWithNoTitlesAreAlreadyIconOnly() {
        #expect(!iconOnly(effectiveWidth: 10, showsTitles: false))
    }

    // MARK: Inline plugin button

    @Test
    func theInlinePluginButtonOnlyShowsWhenItFits() {
        func shows(_ width: CGFloat, _ hasButton: Bool) -> Bool {
            TaskButtonWidthPlanner.showsInlinePluginActionButton(
                effectiveWidth: width,
                showsPluginActionButton: hasButton,
                minimumInlinePluginActionTaskWidth: minimumInlinePluginActionTaskWidth
            )
        }
        #expect(shows(minimumInlinePluginActionTaskWidth, true))
        #expect(!shows(minimumInlinePluginActionTaskWidth - 1, true))
        #expect(!shows(400, false), "there is nothing to show without a plugin button")
    }
}