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
        // Shared Lite UI library — used by both ClickIt (Pro) and ClickItLite binaries.
        // Contains all Lite UI source files and resources; excludes the @main entry point.
        .target(
            name: "ClickItLiteUI",
            dependencies: [],
            path: "Sources/ClickIt/Lite",
            exclude: ["README.md", "ClickItLiteApp.swift"],
            resources: [.process("Resources")]
        ),
        // ClickIt Pro - Full-featured version
        .executableTarget(
            name: "ClickIt",
            dependencies: ["ClickItLiteUI"],
            path: "Sources/ClickIt",
            exclude: ["Lite"],
            resources: [.process("Resources")]
        ),
        // ClickIt Lite - Simplified standalone version (entry point only; UI from ClickItLiteUI)
        .executableTarget(
            name: "ClickItLite",
            dependencies: ["ClickItLiteUI"],
            path: "Sources/ClickIt/Lite",
            exclude: [
                "README.md",
                "LiteScheduler.swift",
                "LoggingConstants.swift",
                "ScheduledClickManager.swift",
                "SimpleClickEngine.swift",
                "SimpleCursorManager.swift",
                "SimpleHotkeyManager.swift",
                "SimplePermissionManager.swift",
                "SimpleViewModel.swift",
                "SimplifiedMainView.swift",
                "Resources",
                "TimingDiagnostic"
            ]
        ),
        .testTarget(
            name: "ClickItTests",
            dependencies: ["ClickIt", "ClickItLiteUI"],
            path: "Tests"
        )
    ]
)
