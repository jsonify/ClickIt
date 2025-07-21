// swift-tools-version: 6.0
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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.2")
    ],
    targets: [
        .executableTarget(
            name: "ClickIt",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ClickItTests",
            dependencies: ["ClickIt"]
        )
    ]
)
