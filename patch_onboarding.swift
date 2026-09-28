import Foundation

let path = "Sources/DeskBar/Views/Onboarding/OnboardingView.swift"
var content = try! String(contentsOfFile: path)

// 1. Change "Accessibility (Required)" to "Accessibility"
content = content.replacingOccurrences(of: "title: \"Accessibility (Required)\"", with: "title: \"Accessibility (Recommended)\"")

// 2. Change "Screen Recording (Required)" to "Screen Recording"
content = content.replacingOccurrences(of: "title: \"Screen Recording (Required)\"", with: "title: \"Screen Recording (Recommended)\"")

// 3. Make isNextButtonDisabled always return false
content = content.replacingOccurrences(of: """
    private var isNextButtonDisabled: Bool {
        if state.step == 1 {
            return !permissionsManager.isAccessibilityGranted || !thumbnailService.isScreenRecordingGranted
        }
        return false
    }
""", with: """
    private var isNextButtonDisabled: Bool {
        return false
    }
""")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
