import Foundation

let path = "Sources/DeskBar/Views/Settings/DockSettingsTab.swift"
var content = try! String(contentsOfFile: path)

let insertString = """
                    Picker("Alignment", selection: $settings.appAlignment) {
                        ForEach(DeskBarAppAlignment.allCases) { alignment in
                            Text(alignment.displayName).tag(alignment)
                        }
                    }
                }
"""

content = content.replacingOccurrences(of: "                }", with: insertString, options: [], range: content.range(of: "                }"))
try! content.write(toFile: path, atomically: true, encoding: .utf8)
