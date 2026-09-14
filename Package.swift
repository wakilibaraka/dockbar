// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DockBar",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "DockBar",
            path: "Sources/DeskBar"
        ),
        .testTarget(
            name: "DeskBarTests",
            dependencies: [
                "DockBar",
            ],
            path: "Tests/DeskBarTests"
        )
    ]
)
