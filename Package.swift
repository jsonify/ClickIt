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
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ClickIt",
            dependencies: [],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ClickItTests",
            dependencies: ["ClickIt"],
            path: "Tests"
        )
    ]
)
