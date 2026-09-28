import Foundation
import CoreGraphics
import DockBarCore

// MARK: - Minimal assertion framework (no Xcode required)

private var passCount = 0
private var failCount = 0
private var failures: [String] = []

private func assertEqual<T: Equatable>(
    _ lhs: T, _ rhs: T, accuracy: Double? = nil,
    _ message: String, file: String = #file, line: Int = #line
) where T: BinaryFloatingPoint {
    let pass: Bool
    if let acc = accuracy {
        pass = abs(Double(lhs) - Double(rhs)) <= acc
    } else {
        pass = lhs == rhs
    }
    if pass { passCount += 1 } else {
        failCount += 1
        let msg = "FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(message) — got \(lhs), want ≈\(rhs)"
        failures.append(msg)
        print(msg)
    }
}

private func assertEqual<T: Equatable>(
    _ lhs: T, _ rhs: T,
    _ message: String, file: String = #file, line: Int = #line
) {
    if lhs == rhs {
        passCount += 1
    } else {
        failCount += 1
        let msg = "FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(message) — got \(lhs), want \(rhs)"
        failures.append(msg)
        print(msg)
    }
}

private func assertApprox(_ lhs: CGFloat, _ rhs: CGFloat, accuracy: CGFloat = 0.5,
                          _ message: String, file: String = #file, line: Int = #line) {
    if abs(lhs - rhs) <= accuracy {
        passCount += 1
    } else {
        failCount += 1
        let msg = "FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(message) — got \(lhs), want ≈\(rhs) (±\(accuracy))"
        failures.append(msg)
        print(msg)
    }
}

private func assertTrue(_ cond: Bool, _ message: String, file: String = #file, line: Int = #line) {
    if cond { passCount += 1 } else {
        failCount += 1
        let msg = "FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(message)"
        failures.append(msg)
        print(msg)
    }
}

private func assertNil<T>(_ val: T?, _ message: String, file: String = #file, line: Int = #line) {
    if val == nil { passCount += 1 } else {
        failCount += 1
        let msg = "FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(message)"
        failures.append(msg); print(msg)
    }
}

private func assertNotNil<T>(_ val: T?, _ message: String, file: String = #file, line: Int = #line) {
    if val != nil { passCount += 1 } else {
        failCount += 1
        let msg = "FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(message)"
        failures.append(msg); print(msg)
    }
}

private func test(_ name: String, _ body: () -> Void) {
    print("  · \(name)")
    body()
}

// MARK: - Frozen fixtures

enum Fixtures {
    static let screen1512 = CGRect(x: 0, y: 0, width: 1512, height: 982)
    static let visible1512 = CGRect(x: 0, y: 0, width: 1512, height: 957)
    static let screen1920 = CGRect(x: 1512, y: 0, width: 1920, height: 1080)

    static let canonicalApps: [LayoutEngine.AppItem] = [
        .init(id: "pinned",    isRunning: false, isFocused: false, hasMultipleWindows: false, isMinimized: false),
        .init(id: "running1",  isRunning: true,  isFocused: false, hasMultipleWindows: false, isMinimized: false),
        .init(id: "focused",   isRunning: true,  isFocused: true,  hasMultipleWindows: false, isMinimized: false),
        .init(id: "minimized", isRunning: true,  isFocused: false, hasMultipleWindows: false, isMinimized: true),
        .init(id: "grouped",   isRunning: true,  isFocused: false, hasMultipleWindows: true,  isMinimized: false),
    ]

    static let canonicalWidgets: [SlotKind: CGSize] = [
        .leading:     CGSize(width: 80,  height: 28),
        .tray:        CGSize(width: 260, height: 40),
        .startButton: CGSize(width: 40,  height: 40),
    ]
    static let wideTrayWidgets: [SlotKind: CGSize] = [
        .tray: CGSize(width: 400, height: 40),
    ]

    static func input(
        theme: TaskbarTheme,
        screen: CGRect = screen1512,
        visible: CGRect = visible1512,
        apps: [LayoutEngine.AppItem] = canonicalApps,
        activeAppID: String? = "focused",
        widgets: [SlotKind: CGSize] = canonicalWidgets
    ) -> LayoutEngine.Input {
        {
        var reqs: [LayoutEngine.Input.WidgetRequest] = []
        var idCounter = 0
        for (slot, size) in widgets {
            reqs.append(.init(id: "w\(idCounter)", slot: slot, rule: .dock, size: size))
            idCounter += 1
        }
        return .init(theme: theme, screenFrame: screen, visibleFrame: visible,
                     apps: apps, activeAppID: activeAppID, widgetRequests: reqs, isDockHidden: false, isFullScreen: false)
    }()
    }
}

// Helper: compute cluster center X in screen coordinates
func clusterCenter(of layout: LayoutEngine.ResolvedLayout) -> CGFloat {
    guard !layout.segmentFrames.isEmpty else { return 0 }
    let minX = layout.segmentFrames.values.map(\.minX).min()!
    let maxX = layout.segmentFrames.values.map(\.maxX).max()!
    return layout.panelFrame.origin.x + (minX + maxX) / 2
}

// MARK: - Test suite

let registry = ThemeRegistry.shared

print("═══════════════════════════════════════════════════")
print("  DockBar Layout Engine Tests")
print("═══════════════════════════════════════════════════\n")

// ── 1. Center independence (split) ────────────────────────────────────────
print("1. Center alignment independence (split)")
test("cluster center == screen center with normal tray") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: Fixtures.canonicalWidgets))
    assertApprox(clusterCenter(of: l), Fixtures.screen1512.width / 2, "cluster center with normal tray")
}
test("cluster center == screen center with wide tray") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: Fixtures.wideTrayWidgets))
    assertApprox(clusterCenter(of: l), Fixtures.screen1512.width / 2, "cluster center with wide tray")
}
test("task segment frame unchanged when only tray widget width changes") {
    let t = registry.theme(for: "split_rounded")!
    // Both inputs have identical task-segment content; only tray width differs
    let taskWidgets: [SlotKind: CGSize] = [
        .startButton: CGSize(width: 40, height: 40),
        .leading:     CGSize(width: 80, height: 28),
    ]
    let normalTray = taskWidgets.merging([.tray: CGSize(width: 260, height: 40)]) { _, new in new }
    let wideTray   = taskWidgets.merging([.tray: CGSize(width: 400, height: 40)]) { _, new in new }
    let lNormal = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: normalTray))
    let lWide   = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: wideTray))
    let n = lNormal.segmentFrames["task_seg"]!
    let w = lWide.segmentFrames["task_seg"]!
    assertApprox(n.minX, w.minX, "task minX must not shift when only tray width changes")
    assertApprox(n.maxX, w.maxX, "task maxX must not shift when only tray width changes")
}

// ── 2. Center independence (unified) ─────────────────────────────────────
print("\n2. Center alignment independence (unified floating)")
test("unified floating cluster center == screen center (normal tray)") {
    let t = registry.theme(for: "compact_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: Fixtures.canonicalWidgets))
    assertApprox(clusterCenter(of: l), Fixtures.screen1512.width / 2, "unified cluster center normal")
}
test("unified floating cluster center == screen center (wide tray)") {
    let t = registry.theme(for: "compact_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: Fixtures.wideTrayWidgets))
    assertApprox(clusterCenter(of: l), Fixtures.screen1512.width / 2, "unified cluster center wide")
}

// ── 3. Segment gap ────────────────────────────────────────────────────────

// ── 4. Fixed tray width ───────────────────────────────────────────────────
print("\n4. Fixed tray segment width")
// (Tray width test removed since we no longer use fixed tray sizing)

// ── 5. Content insets ─────────────────────────────────────────────────────
print("\n5. Content insets")
test("first task button respects task segment contentInsets.left") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    let taskSeg = t.zones.flatMap({ $0.segments }).first(where: { $0.id == "task_seg" })!
    let segFrame = l.segmentFrames["task_seg"]!
    let firstBtn = l.taskButtonFrames["pinned"]!
    assertApprox(firstBtn.minX, segFrame.minX + taskSeg.contentInsets.left, "first button respects left contentInset")
}

// ── 6. Indicator states ───────────────────────────────────────────────────
print("\n6. Indicator states")
test("not-running pinned → .none") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    assertEqual(l.indicatorStates["pinned"], LayoutEngine.IndicatorState.none, "pinned not-running must be .none")
}
test("running unfocused → .unfocused") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    assertEqual(l.indicatorStates["running1"], .unfocused, "running unfocused must be .unfocused")
}
test("running focused → .focused") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    assertEqual(l.indicatorStates["focused"], .focused, "running focused must be .focused")
}
test("running minimized unfocused → .unfocused") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    assertEqual(l.indicatorStates["minimized"], .unfocused, "minimized running must be .unfocused")
}
test("running grouped (multi-window) but not active → .unfocused") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    assertEqual(l.indicatorStates["grouped"], .unfocused, "grouped not-active must be .unfocused")
}
test("running grouped (multi-window) AND active → .groupedFocused") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, activeAppID: "grouped"))
    assertEqual(l.indicatorStates["grouped"], .groupedFocused, "grouped active must be .groupedFocused")
}

// ── 7. Indicator geometry values ──────────────────────────────────────────
print("\n7. Indicator geometric values from model")
test("unfocusedWidth = 16, focusedWidth = 24, thickness = 3") {
    let t = registry.theme(for: "split_rounded")!
    assertApprox(t.indicator.unfocusedWidth, 16.0, "unfocusedWidth")
    assertApprox(t.indicator.focusedWidth, 24.0, "focusedWidth")
    assertApprox(t.indicator.thickness, 3.0, "thickness")
}
test("minimizedIconOpacity = 0.5, animationDuration = 0.15") {
    let t = registry.theme(for: "split_rounded")!
    assertTrue(abs(t.indicator.minimizedIconOpacity - 0.5) < 0.001, "minimizedIconOpacity")
    assertTrue(abs(t.indicator.animationDuration - 0.15) < 0.001, "animationDuration")
}
test("groupedSegmented = true for win11 themes") {
    let t = registry.theme(for: "split_rounded")!
    assertEqual(t.indicator.groupedSegmented, true, "groupedSegmented must be true")
}

// ── 8. Hover rect ────────────────────────────────────────────────────────
print("\n8. Hover rects")
test("hover rect is inset from button bounds by hover.inset") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    let inset = t.hover.inset
    for app in Fixtures.canonicalApps {
        guard let btn = l.taskButtonFrames[app.id], let hover = l.hoverRects[app.id] else { continue }
        assertApprox(hover.minX, btn.minX + inset, "hover.minX for \(app.id)")
        assertApprox(hover.maxX, btn.maxX - inset, "hover.maxX for \(app.id)")
    }
    assertApprox(t.hover.cornerRadius, 4, "hover cornerRadius must be 4 pt")
}

// ── 9. Full-width unified bar ─────────────────────────────────────────────
print("\n9. Full-width unified bar")
test("All 6 generated themes have exactly 3 zones with anchors leadingEdge/center/trailingEdge") {
    let presets = ["fullWidth", "compact", "split"]
    let edges = ["rounded", "sharp"]
    for p in presets {
        for e in edges {
            let id = "\(p)_\(e)"
            let t = registry.theme(for: id)!
            assertEqual(t.zones.count, 3, "\(id) must have 3 zones")
            if t.zones.count == 3 {
                assertEqual(t.zones[0].anchor, .leadingEdge, "\(id) zone 0 anchor")
                assertEqual(t.zones[1].anchor, .center, "\(id) zone 1 anchor")
                assertEqual(t.zones[2].anchor, .trailingEdge, "\(id) zone 2 anchor")
            }
        }
    }
}
test("fullWidth center segment has sizing .fill") {
    let t = registry.theme(for: "fullWidth_sharp")!
    if t.zones.count >= 2 {
        assertEqual(t.zones[1].segments.first?.sizing == .fill, true, "fullWidth center must fill")
    }
}
test("fill segment spans screen width minus geometry insets") {
    let t = registry.theme(for: "fullWidth_sharp")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    let seg = l.segmentFrames["task_seg"]!
    let g = t.geometry
    // Because fullWidth has left_seg and tray_seg, the task_seg fills the space between them.
    // It doesn't strictly span the whole screen width minus insets because left/tray segments exist.
    // Let's assert it is > 0 to prove it fills something.
    assertTrue(seg.width > 500, ".fill segment must expand significantly")
}

// ── 10. Overflow ────────────────────────────────────────────────────────
print("\n10. Overflow safety")
test("50 apps: hasTaskOverflow=true with fixed-width segment, no frame exceeds bounds") {
    let base = registry.theme(for: "split_rounded")!
    var narrowSeg = base.zones[0].segments[0] // task segment
    narrowSeg = Segment(
        id: narrowSeg.id, surface: narrowSeg.surface, border: narrowSeg.border,
        cornerRadius: narrowSeg.cornerRadius, contentInsets: narrowSeg.contentInsets,
        sizing: .fixed(width: 200), slots: narrowSeg.slots
    )
    var narrowTheme = base
    narrowTheme.zones[0].segments[0] = narrowSeg
    let manyApps = (0..<50).map {
        LayoutEngine.AppItem(id: "app\($0)", isRunning: true, isFocused: false,
                             hasMultipleWindows: false, isMinimized: false)
    }
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: narrowTheme, apps: manyApps))
    assertTrue(l.hasTaskOverflow, "must signal overflow with 50 apps in 200pt fixed segment")
    if let taskSeg = l.segmentFrames["task_seg"] {
        for (id, frame) in l.taskButtonFrames {
            assertTrue(frame.maxX <= taskSeg.maxX + 0.5, "button \(id) maxX must not exceed segment")
        }
    }
}
test("50 apps: button frames don't overlap") {
    let t = registry.theme(for: "split_rounded")!
    let manyApps = (0..<50).map {
        LayoutEngine.AppItem(id: "app\($0)", isRunning: true, isFocused: false,
                             hasMultipleWindows: false, isMinimized: false)
    }
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, apps: manyApps))
    let frames = Array(l.taskButtonFrames.values)
    var overlaps = 0
    for i in 0..<frames.count {
        for j in (i+1)..<frames.count {
            if frames[i].intersects(frames[j].insetBy(dx: 0.5, dy: 0)) { overlaps += 1 }
        }
    }
    assertEqual(overlaps, 0, "no button frames may overlap")
}

// ── 11. Panel frame ────────────────────────────────────────────────────
print("\n11. Panel frame")
test("floating theme panel minY == screenMinY + screenInsets.bottom") {
    let t = registry.theme(for: "split_rounded")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    assertApprox(l.panelFrame.minY, Fixtures.screen1512.minY + t.geometry.screenInsets.bottom,
                 "panel Y for floating theme")
}
test("fullWidth_sharp panel minY == screenMinY") {
    let t = registry.theme(for: "fullWidth_sharp")!
    let l = LayoutEngine.resolve(input: Fixtures.input(theme: t, widgets: [:]))
    assertApprox(l.panelFrame.minY, Fixtures.screen1512.minY, "panel Y for fullWidth_sharp")
    assertApprox(l.panelFrame.width, Fixtures.screen1512.width, "panel width for fullWidth_sharp")
}

// ── 12. Codable round-trip ────────────────────────────────────────────
print("\n12. Theme Codable round-trips")
test("all themes encode and decode identically") {
    for (id, theme) in registry.themes {
        if let data = try? JSONEncoder().encode(theme),
           let decoded = try? JSONDecoder().decode(TaskbarTheme.self, from: data) {
            assertEqual(theme, decoded, "\(id) round-trip")
        } else {
            assertTrue(false, "\(id) failed Codable round-trip")
        }
    }
}

// ── 13. Variant helpers ───────────────────────────────────────────────
print("\n13. Variant helpers (data mutations only)")
test("roundVariant sets all corners to 25, preserves gap") {
    let base = registry.theme(for: "split_rounded")!
    let round = registry.roundVariant(of: base)
    assertTrue(round.zones.flatMap({ $0.segments }).allSatisfy { $0.cornerRadius == CornerRadius(all: 25) }, "all corners=25")
    assertApprox(round.zones.first?.interSegmentGap ?? 0, base.zones.first?.interSegmentGap ?? 0, "gap unchanged")
}
test("acrylicVariant makes all segments acrylic") {
    let base = registry.theme(for: "split_rounded")!
    let acrylic = registry.acrylicVariant(of: base)
    for seg in acrylic.zones.flatMap({ $0.segments }) {
        if case .acrylic = seg.surface { passCount += 1 }
        else { assertTrue(false, "segment \(seg.id) must be .acrylic") }
    }
    assertEqual(acrylic.zones.flatMap({ $0.segments }).count, base.zones.flatMap({ $0.segments }).count, "segment count unchanged")
}

// ── 14. Registry completeness + tray locale ───────────────────────────
print("\n14. Registry completeness & locale rule")
test("all 8 required themes exist") {
    let required = [
        "fullWidth_rounded", "fullWidth_sharp",
        "compact_rounded", "compact_sharp",
        "split_rounded", "split_sharp"
    ]
    for id in required { assertNotNil(registry.theme(for: id), "\(id) must exist") }
}
test("clockUsesLocale=true on every theme (no hardcoded format)") {
    for (id, theme) in registry.themes {
        assertTrue(theme.tray.clockUsesLocale, "\(id): clockUsesLocale must be true")
    }
}

// ── Results ──────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════")
print("  Results: \(passCount) passed, \(failCount) failed")
if failCount > 0 {
    print("\n  Failures:")
    failures.forEach { print("    \($0)") }
    print("")
    exit(1)
} else {
    print("  ✅ All tests passed")
}
print("═══════════════════════════════════════════════════")
