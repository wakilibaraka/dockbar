import Foundation

let path = "Sources/DeskBar/Services/ThumbnailService.swift"
var content = try! String(contentsOfFile: path)
content = content.replacingOccurrences(of: """
        guard CGPreflightScreenCaptureAccess() else {
            isScreenRecordingGranted = false
            return nil
        }
""", with: """
        if !CGPreflightScreenCaptureAccess() {
            let granted = requestScreenRecordingPermission()
            if !granted {
                return nil
            }
        }
""")

content = content.replacingOccurrences(of: """
        guard CGPreflightScreenCaptureAccess() else {
            isScreenRecordingGranted = false
            return ThumbnailCaptureSession(
                thumbnailService: self,
                screenCaptureWindowsByID: nil
            )
        }
""", with: """
        if !CGPreflightScreenCaptureAccess() {
            let granted = requestScreenRecordingPermission()
            if !granted {
                return ThumbnailCaptureSession(
                    thumbnailService: self,
                    screenCaptureWindowsByID: nil
                )
            }
        }
""")
try! content.write(toFile: path, atomically: true, encoding: .utf8)
