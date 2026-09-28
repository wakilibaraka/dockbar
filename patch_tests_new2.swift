import Foundation

let path = "Tests/EngineTests/main.swift"
var content = try! String(contentsOfFile: path)
let target = "// ── Results ──────────────────────────────────────────────────────────"
let newTarget = """
// 16. WindowManager Minimized Apps
test("WindowManager handles minimized apps correctly") {
    let w1 = WindowInfo(pid: 100, cgWindowID: 1, provisionalID: nil, appName: "A", title: "A", icon: nil, bundleIdentifier: "a", applicationURL: nil, isMinimized: true, isHidden: false, isProvisional: false)
    let w2 = WindowInfo(pid: 101, cgWindowID: 2, provisionalID: nil, appName: "B", title: "B", icon: nil, bundleIdentifier: "b", applicationURL: nil, isMinimized: false, isHidden: true, isProvisional: false)
    let w3 = WindowInfo(pid: 102, cgWindowID: 3, provisionalID: nil, appName: "C", title: "C", icon: nil, bundleIdentifier: "c", applicationURL: nil, isMinimized: false, isHidden: false, isProvisional: false)
    
    let pids = WindowManager.visibleWindowPIDs(from: [w1, w2, w3])
    assert(pids.contains(100), "Minimized app should be included")
    assert(pids.contains(101), "Hidden app should be included")
    assert(pids.contains(102), "Normal app should be included")
}

// 17. ThemeCoordinator Trash Mount
test("ThemeCoordinator mounts trash") {
    let reg = WidgetRegistry.shared
    assert(reg.definition(for: "trash") != nil, "Trash should be registered")
    assert(reg.definition(for: "taskView") == nil, "TaskView should be removed")
}

// ── Results ──────────────────────────────────────────────────────────
"""
content = content.replacingOccurrences(of: target, with: newTarget)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
