// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClickIt",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "ClickIt",
            targets: ["ClickIt"]
        )
    ],
    dependencies: [
        // No external dependencies required for now
    ],
    targets: [
        .executableTarget(
            name: "ClickIt",
            dependencies: [],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ClickItTests",
            dependencies: ["ClickIt"]
        )
    ]
)
