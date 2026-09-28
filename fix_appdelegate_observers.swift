import Foundation

let path = "Sources/DeskBar/App/AppDelegate.swift"
var content = try! String(contentsOfFile: path)

let oldObservers = """
        settings.$showOnAllMonitors
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshPanelsForCurrentConfiguration()
            }
            .store(in: &cancellables)
"""

let newObservers = """
        settings.$showOnAllMonitors
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshPanelsForCurrentConfiguration()
            }
            .store(in: &cancellables)

        settings.$preset
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildAllPanels()
            }
            .store(in: &cancellables)

        settings.$edgeStyle
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildAllPanels()
            }
            .store(in: &cancellables)
"""
content = content.replacingOccurrences(of: oldObservers, with: newObservers)

let rebuildAllPanelsFunc = """
    private func rebuildAllPanels() {
        for panel in panels.values {
            panel.close()
        }
        panels.removeAll()
        themeCoordinators.removeAll()
        refreshPanelsForCurrentConfiguration()
    }

    private func refreshPanelsForCurrentConfiguration() {
"""
content = content.replacingOccurrences(of: "    private func refreshPanelsForCurrentConfiguration() {", with: rebuildAllPanelsFunc)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
