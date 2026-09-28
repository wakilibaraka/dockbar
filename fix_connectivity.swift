import Foundation

let path = "Sources/DeskBar/Views/ConnectivityTrayView.swift"
var content = try! String(contentsOfFile: path)

let oldConstraint = """
        win11Constraint?.isActive = settings.layoutMode == .windows11FullWidth || settings.layoutMode == .windows11Floating
"""
let newConstraint = """
        win11Constraint?.isActive = false
"""
content = content.replacingOccurrences(of: oldConstraint, with: newConstraint)

let oldSink = """
        settings.$layoutMode
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.win11Constraint?.isActive = mode == .windows11FullWidth || mode == .windows11Floating
            }
            .store(in: &cancellables)
"""
let newSink = """
"""
content = content.replacingOccurrences(of: oldSink, with: newSink)

let oldWidth = """
    func preferredContentWidth() -> CGFloat {
        if settings.layoutMode == .windows11FullWidth || settings.layoutMode == .windows11Floating {
            return 32
        }
        return quickSettingsButton.fittingSize.width
    }
"""
let newWidth = """
    func preferredContentWidth() -> CGFloat {
        return quickSettingsButton.fittingSize.width
    }
"""
content = content.replacingOccurrences(of: oldWidth, with: newWidth)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
