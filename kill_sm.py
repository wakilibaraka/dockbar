import re

with open("Sources/DeskBar/Plugins/SMPlugin/SMPluginService.swift", "r") as f:
    c = f.read()

# Force init to always be disabled, or just return early in refresh
c = c.replace("    init(isEnabled: Bool) {", "    init(isEnabled: Bool) {\n        self.isEnabled = false\n        return\n")

# Kill refresh logic
c = c.replace("    func refresh(forceTerminalMapping: Bool = false) {", "    func refresh(forceTerminalMapping: Bool = false) {\n        return\n")

# Empty out terminal fetching
c = c.replace("    private func updateTerminalWindows() {", "    private func updateTerminalWindows() {\n        return\n")

with open("Sources/DeskBar/Plugins/SMPlugin/SMPluginService.swift", "w") as f:
    f.write(c)

