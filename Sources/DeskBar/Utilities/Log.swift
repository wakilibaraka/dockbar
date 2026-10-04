import os

// Unified logging for DockBar. Replaces ad-hoc print()/NSLog() calls so diagnostics
// show up in Console.app (and `log stream`) with a stable subsystem and per-area
// categories instead of interleaving on stdout.

enum Log {
    private static let subsystem = "com.dockbar.app"

    /// App lifecycle: single-instance lock, migrations, login items.
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Window tracking: AX access, window switching, accessibility fallbacks.
    static let windows = Logger(subsystem: subsystem, category: "windows")

    /// Window layout snapshots: capture, persistence, restore.
    static let layout = Logger(subsystem: subsystem, category: "layout")

    /// Dock coexistence: hiding, watchdogs, preference updates.
    static let dock = Logger(subsystem: subsystem, category: "dock")

    /// Launcher and Launchpick: app resolution, opening, pinned-app plumbing.
    static let launcher = Logger(subsystem: subsystem, category: "launcher")

    /// Quick Settings widgets and tray items (trash, Wi-Fi, keyboard lock, battery...).
    static let quickSettings = Logger(subsystem: subsystem, category: "quick-settings")

    /// Everything else: misc utilities and services without a dedicated category.
    static let general = Logger(subsystem: subsystem, category: "general")
}
