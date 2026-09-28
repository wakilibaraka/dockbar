import Foundation

let path = "Sources/DeskBar/Views/Engine/ThemeCoordinator.swift"
var content = try! String(contentsOfFile: path)

let bindString = """
        settings.$showSystemResourceWidget.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
"""

let newBindString = """
        settings.$showSystemResourceWidget.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showStartButton.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showSearch.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showTaskView.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showWidgetsBoard.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showDownloads.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showLiveEvents.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$appAlignment.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
"""

content = content.replacingOccurrences(of: bindString, with: newBindString)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
