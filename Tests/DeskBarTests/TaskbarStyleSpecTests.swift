import AppKit
import Foundation
import Testing
@testable import DockBar

/// `TaskbarStyleSpec` replaced hand-written per-strategy methods, so these tests pin the
/// behaviour those methods had: the same layout each style forces, the same grouping, the
/// same widget hosting, and the same button colours.
struct TaskbarStyleSpecTests {
    @Test
    func everyStyleHasASpecAndTheProtocolAgreesWithIt() {
        for mode in TaskbarMode.allCases {
            let strategy = mode.strategy
            #expect(strategy.spec == mode.spec, "\(mode.rawValue) strategy and spec disagree")
            #expect(strategy.visualEffectMaterial == mode.spec.material)
        }
    }

    @Test
    func stylesThatForceALayoutIgnoreTheUserChoice() {
        for mode in TaskbarMode.allCases where mode.spec.layoutMode != nil {
            let strategy = mode.strategy
            for choice in DeskBarLayoutMode.allCases {
                #expect(
                    strategy.layoutMode(defaultLayoutMode: choice) == mode.spec.layoutMode,
                    "\(mode.rawValue) should force its own layout"
                )
            }
        }
    }

    @Test
    func customStyleRespectsTheUserLayoutAndPosition() {
        let strategy = TaskbarMode.custom.strategy
        for choice in DeskBarLayoutMode.allCases {
            #expect(strategy.layoutMode(defaultLayoutMode: choice) == choice)
        }
        for choice in DockPosition.allCases {
            #expect(strategy.dockPosition(defaultPosition: choice) == choice)
        }
    }

    @Test
    func groupingIsForcedWhereTheStyleDemandsIt() {
        #expect(TaskbarMode.windows.strategy.shouldGroupWindows(defaultGrouping: false))
        #expect(TaskbarMode.mac.strategy.shouldGroupWindows(defaultGrouping: false))
        #expect(!TaskbarMode.classic.strategy.shouldGroupWindows(defaultGrouping: true))
        #expect(!TaskbarMode.eskele.strategy.shouldGroupWindows(defaultGrouping: true))
        // Custom honours the user either way.
        #expect(TaskbarMode.custom.strategy.shouldGroupWindows(defaultGrouping: true))
        #expect(!TaskbarMode.custom.strategy.shouldGroupWindows(defaultGrouping: false))
    }

    @Test
    func onlyMacAndClassicTrailTheClusterWithWidgets() {
        let trailing = Set(
            TaskbarMode.allCases
                .filter { $0.spec.windowClusterTrailsWidgets }
                .map(\.rawValue)
        )
        #expect(trailing == ["windows", "classic"])

        for mode in TaskbarMode.allCases {
            let widths = mode.strategy.dockWidgetWidths(originalWidths: [40, 60], clusterWidth: 300)
            if mode.spec.windowClusterTrailsWidgets {
                #expect(widths == [40, 60, 312], "\(mode.rawValue) should append the cluster")
            } else {
                #expect(widths == [40, 60], "\(mode.rawValue) should leave widths alone")
            }
        }
    }

    @Test
    func onlyMacKeepsWidgetsOutOfTheBar() {
        let hosting = Set(TaskbarMode.allCases.filter { $0.spec.hostsWidgetsInBar }.map(\.rawValue))
        #expect(!hosting.contains("mac"))
        #expect(hosting.count == TaskbarMode.allCases.count - 1)
    }

    @Test
    func runningIndicatorsMatchTheStyle() {
        #expect(TaskbarMode.windows.strategy.spec.showsRunningIndicator(forWindowCount: 0) == false)
        #expect(TaskbarMode.windows.strategy.spec.showsRunningIndicator(forWindowCount: 1))
        #expect(TaskbarMode.mac.strategy.spec.showsRunningIndicator(forWindowCount: 1))
        #expect(!TaskbarMode.classic.strategy.spec.showsRunningIndicator(forWindowCount: 4))
    }

    @Test
    func activeFillAlphasPreserveEachStylesLook() {
        let expectations: [TaskbarMode: CGFloat] = [
            .custom: 0.30,
            .windows: 0.30,
            .mac: 0.0,
            .classic: 0.30,
            .eskele: 0.35,
        ]
        for mode in TaskbarMode.allCases {
            let alpha = mode.spec.activeFillAlpha
            #expect(alpha == expectations[mode], "\(mode.rawValue) active alpha changed")
        }
    }

    @Test
    func backgroundColorPrefersActiveThenAttentionThenHover() {
        let spec = TaskbarStyleSpec.classic
        let active = spec.backgroundColor(
            isActive: true,
            needsAttention: true,
            isHovered: true
        )
        #expect(active == NSColor.controlAccentColor.withAlphaComponent(0.30))

        let attention = spec.backgroundColor(
            isActive: false,
            needsAttention: true,
            isHovered: true
        )
        #expect(attention == NSColor.systemOrange.withAlphaComponent(0.14))

        let hover = spec.backgroundColor(
            isActive: false,
            needsAttention: false,
            isHovered: true
        )
        #expect(hover == NSColor.labelColor.withAlphaComponent(0.10))

        #expect(
            spec.backgroundColor(
                isActive: false,
                needsAttention: false,
                isHovered: false
            ) == nil
        )
    }

    @Test
    func macDockDrawsNoFillForAnyState() {
        // The running dot already communicates focus, so an accent fill would double up.
        for isActive in [true, false] {
            #expect(
                TaskbarStyleSpec.mac.backgroundColor(
                    isActive: isActive,
                    needsAttention: false,
                    isHovered: false
                ) == nil,
                "the Mac style should draw no background"
            )
        }
    }

    @Test
    func onlyEskeleSizesItsIconButtonsToTheBarHeight() {
        let sizedToBar = Set(
            TaskbarMode.allCases
                .filter { $0.spec.taskTitle == .hiddenSizedToBar }
                .map(\.rawValue)
        )
        #expect(sizedToBar == ["eskele"])

        let fixedWidth = Set(
            TaskbarMode.allCases
                .filter { $0.spec.taskTitle == .hidden }
                .map(\.rawValue)
        )
        #expect(fixedWidth == ["windows", "mac"])

        let withTitles = Set(
            TaskbarMode.allCases
                .filter { $0.spec.taskTitle == .whenItFits }
                .map(\.rawValue)
        )
        #expect(withTitles == ["custom", "classic"])
    }

    @Test
    func everyStyleKeepsTheLauncherReachable() {
        // Each strategy hides the launcher *zone* and keeps the launcher *button*. A style
        // that hid both would leave icons-only bars with no way to open the launcher.
        for mode in TaskbarMode.allCases {
            let zones = NSStackView()
            let button = NSView()
            let zone = NSView()
            let defaultInsets = NSEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            mode.strategy.applyModeLayout(
                zonesStackView: zones,
                launcherButtonView: button,
                launcherZoneView: zone,
                defaultZoneEdgeInsets: defaultInsets
            )
            #expect(!button.isHidden, "\(mode.rawValue) hid the launcher button")
            #expect(zone.isHidden, "\(mode.rawValue) showed both launcher affordances")
        }
    }

    @Test
    func eachStyleAppliesItsOwnPadding() {
        for mode in TaskbarMode.allCases {
            let zones = NSStackView()
            mode.strategy.applyModeLayout(
                zonesStackView: zones,
                launcherButtonView: NSView(),
                launcherZoneView: NSView(),
                defaultZoneEdgeInsets: NSEdgeInsets(top: 99, left: 99, bottom: 99, right: 99)
            )
            let applied = zones.edgeInsets
            let expected = mode.spec.zoneInsets
            #expect(
                applied.top == expected.top
                    && applied.left == expected.left
                    && applied.bottom == expected.bottom
                    && applied.right == expected.right,
                "\(mode.rawValue) padding mismatch"
            )
        }
    }
}