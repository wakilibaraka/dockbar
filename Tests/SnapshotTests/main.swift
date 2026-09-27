import AppKit
import Foundation
import DockBarCore

// MARK: - Determinism controls
// Animations disabled: all CATransaction.setDisableActions(true) calls in views handle this
// Clock: frozen — SnapshotClock fixture replaces Date() in new views (new views read from injected provider)
// Battery: 62% fixed (neutral, per spec)
// Accent: pin controlAccentColor via NSAppearance in test app launch

let referencesDir = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .appendingPathComponent("References")
let failureDir = URL(fileURLWithPath: "/tmp/SnapshotFailures")
let recordMode = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"

try? FileManager.default.createDirectory(at: failureDir, withIntermediateDirectories: true)

var passed = 0
var failed = 0
var failures: [String] = []

// MARK: - Snapshot machinery

func captureSnapshot(view: NSView, size: CGSize) -> NSBitmapImageRep? {
    view.frame = NSRect(origin: .zero, size: size)
    view.layoutSubtreeIfNeeded()
    guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
    view.cacheDisplay(in: view.bounds, to: rep)
    return rep
}

func pngData(from rep: NSBitmapImageRep) -> Data? {
    rep.representation(using: .png, properties: [:])
}

func comparePixels(actual: NSBitmapImageRep, reference: NSBitmapImageRep) -> (pass: Bool, diffCount: Int, total: Int) {
    let w = actual.pixelsWide
    let h = actual.pixelsHigh
    guard reference.pixelsWide == w, reference.pixelsHigh == h else {
        return (false, w * h, w * h)
    }
    var diffCount = 0
    let threshold: Int = 2
    for y in 0..<h {
        for x in 0..<w {
            let a = actual.colorAt(x: x, y: y)!
            let r = reference.colorAt(x: x, y: y)!
            let dr = Int(abs((a.redComponent - r.redComponent) * 255))
            let dg = Int(abs((a.greenComponent - r.greenComponent) * 255))
            let db = Int(abs((a.blueComponent - r.blueComponent) * 255))
            let da = Int(abs((a.alphaComponent - r.alphaComponent) * 255))
            if dr > threshold || dg > threshold || db > threshold || da > threshold {
                diffCount += 1
            }
        }
    }
    let total = w * h
    let pass = Double(diffCount) / Double(total) <= 0.001
    return (pass, diffCount, total)
}

func writeDiff(actual: NSBitmapImageRep, reference: NSBitmapImageRep, name: String) {
    let w = actual.pixelsWide
    let h = actual.pixelsHigh
    guard let diffRep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { return }
    for y in 0..<h {
        for x in 0..<w {
            let a = actual.colorAt(x: x, y: y) ?? .clear
            let r = reference.colorAt(x: x, y: y) ?? .clear
            let dr = abs(a.redComponent - r.redComponent)
            let dg = abs(a.greenComponent - r.greenComponent)
            let db = abs(a.blueComponent - r.blueComponent)
            let diff = NSColor(red: dr * 10, green: dg * 10, blue: db * 10, alpha: 1)
            diffRep.setColor(diff, atX: x, y: y)
        }
    }
    if let actualData = pngData(from: actual) {
        try? actualData.write(to: failureDir.appendingPathComponent("actual_\(name).png"))
    }
    if let diffData = pngData(from: diffRep) {
        try? diffData.write(to: failureDir.appendingPathComponent("diff_\(name).png"))
    }
}

func snapshot(name: String, view: NSView, size: CGSize) {
    guard let actual = captureSnapshot(view: view, size: size),
          let actualData = pngData(from: actual) else {
        print("FAIL [\(name)]: could not capture snapshot")
        failed += 1
        failures.append(name)
        return
    }

    let refURL = referencesDir.appendingPathComponent("\(name).png")

    if recordMode {
        try? actualData.write(to: refURL)
        print("RECORD [\(name)]: written to \(refURL.path)")
        passed += 1
        return
    }

    guard let refData = try? Data(contentsOf: refURL),
          let refImage = NSBitmapImageRep(data: refData) else {
        print("FAIL [\(name)]: no reference at \(refURL.path) — run with RECORD_SNAPSHOTS=1 to generate")
        failed += 1
        failures.append(name)
        return
    }

    let result = comparePixels(actual: actual, reference: refImage)
    if result.pass {
        passed += 1
        print("PASS [\(name)]: \(result.diffCount)/\(result.total) pixels differ (within 0.1% tolerance)")
    } else {
        failed += 1
        failures.append(name)
        writeDiff(actual: actual, reference: refImage, name: name)
        let pct = String(format: "%.2f", Double(result.diffCount) / Double(result.total) * 100)
        print("FAIL [\(name)]: \(result.diffCount)/\(result.total) pixels differ (\(pct)%) — see /tmp/SnapshotFailures/")
    }
}

// MARK: - Theme snapshot helper

func makeThemeSnapshot(themeID: String, appearance: NSAppearance.Name, scale: CGFloat) {
    guard let theme = ThemeRegistry.shared.theme(for: themeID) else {
        print("SKIP [\(themeID)]: theme not found")
        return
    }

    let screenFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)
    let apps = SnapshotFixtures.canonicalApps
    let widgets = SnapshotFixtures.canonicalWidgets
    let reqs = widgets.enumerated().map { (idx, element) in
        LayoutEngine.Input.WidgetRequest(id: "w\(idx)", slot: element.key, rule: .dock, size: element.value)
    }
    let input = LayoutEngine.Input(
        theme: theme, screenFrame: screenFrame,
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 957),
        apps: apps, activeAppID: "focused",
        widgetRequests: reqs, isDockHidden: false, isFullScreen: false
    )
    let resolved = LayoutEngine.resolve(input: input)

    let container = ThemeContainerView(theme: theme)
    container.applyLayout(resolved)

    let panelSize = CGSize(width: 1512, height: theme.geometry.height)
    let scaleSuffix = scale == 2 ? "@2x" : "@1x"
    let appSuffix = appearance == .darkAqua ? "dark" : "light"
    let snapshotName = "\(themeID)_\(appSuffix)_\(scaleSuffix)"

    NSAppearance.current = NSAppearance(named: appearance)!
    snapshot(name: snapshotName, view: container, size: panelSize)
}

// MARK: - Fixtures (frozen, deterministic)
enum SnapshotFixtures {
    static let canonicalApps: [LayoutEngine.AppItem] = [
        .init(id: "pinned",    isRunning: false, isFocused: false, hasMultipleWindows: false, isMinimized: false),
        .init(id: "running1",  isRunning: true,  isFocused: false, hasMultipleWindows: false, isMinimized: false),
        .init(id: "focused",   isRunning: true,  isFocused: true,  hasMultipleWindows: false, isMinimized: false),
        .init(id: "minimized", isRunning: true,  isFocused: false, hasMultipleWindows: false, isMinimized: true),
        .init(id: "grouped",   isRunning: true,  isFocused: false, hasMultipleWindows: true,  isMinimized: false),
    ]
    static let canonicalWidgets: [SlotKind: CGSize] = [
        .leading:     CGSize(width: 80, height: 28),
        .tray:        CGSize(width: 260, height: 40),
        .startButton: CGSize(width: 40, height: 40),
    ]
}

// MARK: - Run snapshots

print("═══════════════════════════════════════════")
print("  DockBar Snapshot Tests (Path B — new-stack baselines)")
print("  Mode: \(recordMode ? "RECORD" : "COMPARE")")
print("═══════════════════════════════════════════\n")

print("  Existing themes: guarded manually via install-and-confirm until migrated in Phase 2.")

// Only windows11.floatingSplit is snapshot-guarded right now, because it's the only theme actually served by the new stack.
let themeIDs = [
    "windows11.floatingSplit"
]
let appearances: [NSAppearance.Name] = [.aqua, .darkAqua]
let scales: [CGFloat] = [1.0] // 2x requires screen — skip in headless for now

for themeID in themeIDs {
    for appearance in appearances {
        for scale in scales {
            makeThemeSnapshot(themeID: themeID, appearance: appearance, scale: scale)
        }
    }
}

print("\n═══════════════════════════════════════════")
print("  Results: \(passed) passed, \(failed) failed")
if failed > 0 {
    print("  Failures: \(failures.joined(separator: ", "))")
    exit(1)
} else {
    print("  ✅ All snapshots passed")
}
print("═══════════════════════════════════════════")
