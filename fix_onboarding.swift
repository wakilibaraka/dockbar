import Foundation

let path = "Sources/DeskBar/Views/Onboarding/OnboardingView.swift"
var content = try! String(contentsOfFile: path)

let oldPicker = """
                            Picker("Layout Theme", selection: $settings.layoutMode) {
                                Text("Windows 11 (Floating)").tag(DeskBarLayoutMode.windows11Floating)
                                Text("Windows 11 (Full Width)").tag(DeskBarLayoutMode.windows11FullWidth)
                                Text("Compact Glass").tag(DeskBarLayoutMode.compactGlass)
                                Text("Full Width Glass").tag(DeskBarLayoutMode.fullWidthGlass)
                                Text("Full Width (Solid)").tag(DeskBarLayoutMode.fullWidth)
                            }
"""
let newPicker = """
                            Picker("Preset", selection: $settings.preset) {
                                Text("Split").tag(DeskBarPreset.split)
                                Text("Compact").tag(DeskBarPreset.compact)
                                Text("Full Width").tag(DeskBarPreset.fullWidth)
                            }
                            Picker("Edge Style", selection: $settings.edgeStyle) {
                                Text("Rounded (Floating)").tag(DeskBarEdgeStyle.rounded)
                                Text("Sharp (Flush)").tag(DeskBarEdgeStyle.sharp)
                            }
"""
content = content.replacingOccurrences(of: oldPicker, with: newPicker)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
