// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClickIt",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ClickIt",
            targets: ["ClickIt"]
        ),
        .executable(
            name: "ClickItLite",
            targets: ["ClickItLite"]
        )
    ],
    dependencies: [],
    targets: [
        // ClickIt Pro - Full-featured version
        .executableTarget(
            name: "ClickIt",
            dependencies: [],
            path: "Sources/ClickIt",
            exclude: ["Lite"],
            resources: [.process("Resources")]
        ),
        // ClickIt Lite - Simplified version
        .executableTarget(
            name: "ClickItLite",
            dependencies: [],
            path: "Sources/ClickIt/Lite",
            resources: []
        ),
        .testTarget(
            name: "ClickItTests",
            dependencies: ["ClickIt"],
            path: "Tests"
        )
    ]
)
