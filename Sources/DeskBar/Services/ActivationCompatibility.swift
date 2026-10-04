import AppKit

// The no-argument `activate()` on NSApplication and NSRunningApplication arrived in
// macOS 14, and `activate(ignoringOtherApps:)` is deprecated on it. Both APIs are
// MainActor-isolated, but some DockBar call sites sit in nonisolated contexts (timer
// and notification callbacks) that the compiler cannot prove run on the main thread.
// The shims therefore bridge the isolation themselves with `MainActor.assumeIsolated`
// — trapping rather than racing if genuinely called off-main — so every call site can
// use one method regardless of its actor context, and the version split lives in
// exactly one file.

extension NSApplication {
    /// `activate()` where available, `activate(ignoringOtherApps: true)` before macOS 14.
    func activateCompat() {
        MainActor.assumeIsolated {
            if #available(macOS 14.0, *) {
                activate()
            } else {
                activate(ignoringOtherApps: true)
            }
        }
    }
}

extension NSRunningApplication {
    /// `activate()` where available, the pre-macOS-14 `activate(options: [])` before that.
    func activateCompat() {
        MainActor.assumeIsolated {
            if #available(macOS 14.0, *) {
                activate()
            } else {
                activate(options: [])
            }
        }
    }
}
