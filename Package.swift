// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DockBar",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DockBarCore",
            path: "Sources/DockBarCore"
        ),
        .executableTarget(
            name: "DockBar",
            dependencies: ["DockBarCore"],
            path: "Sources/DeskBar"
        ),
        .executableTarget(
            name: "EngineTests",
            dependencies: ["DockBarCore"],
            path: "Tests/EngineTests"
        ),
        .executableTarget(
            name: "SnapshotTests",
            dependencies: ["DockBarCore"],
            path: "Tests/SnapshotTests"
        )
    ]
)
