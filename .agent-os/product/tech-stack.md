# Technical Stack

> Last Updated: 2025-01-22
> Version: 1.0.0

## Core Platform

- **Application Framework:** Swift 5.9+ with Swift Package Manager
- **UI Framework:** SwiftUI (macOS 15.0+)
- **Target Platform:** macOS Universal Binary (Intel x64 + Apple Silicon arm64)
- **Minimum OS Version:** macOS 15.0

## Development Environment

- **Build System:** Swift Package Manager (SPM) with Xcode integration
- **IDE Support:** Xcode with native SPM project opening via `open Package.swift`
- **Package Manager:** Swift Package Manager for dependency resolution
- **Version Control:** Git with GitHub repository

## Core Frameworks

- **CoreGraphics:** Mouse event generation (`CGEventCreateMouseEvent`, `CGEventPostToPid`)
- **ApplicationServices:** Window detection and management (`CGWindowListCopyWindowInfo`)
- **Carbon:** Global hotkey registration and system-level input handling
- **SwiftUI:** Modern reactive user interface framework
- **Combine:** Reactive state management and data flow
- **Foundation:** Core utilities, UserDefaults, and system integration

## UI Architecture

- **Design Pattern:** MVVM with SwiftUI and Combine
- **State Management:** `@StateObject`, `@ObservedObject`, `@Published` properties
- **Data Persistence:** UserDefaults for settings and presets
- **Component Library:** Custom SwiftUI components with modular architecture
- **Visual Feedback:** `NSWindow` with `NSWindowLevel.floating` for overlay system

## Build & Deployment

- **Build Automation:** Fastlane with 12+ configured lanes
- **Universal Binary Creation:** Automated multi-architecture builds (Intel + Apple Silicon)
- **Code Signing:** Automated certificate detection with Apple Development certificates
- **Distribution Format:** Native macOS .app bundle with framework embedding
- **Build Scripts:** Unified build script supporting both SPM and Xcode workflows

## Development Tools

- **Build Script:** `./build_app_unified.sh` for universal app bundle creation
- **Automation:** Fastlane lanes for development, testing, and release workflows
- **Testing Framework:** XCTest for unit testing with UI testing support
- **Code Signing:** Automated signing with `./scripts/sign-app.sh`
- **Linting:** SwiftLint integration (optional for CI compatibility)

## Performance Requirements

- **Memory Usage:** <50MB RAM at idle, <100MB during operation
- **CPU Usage:** <5% CPU at idle, optimized for precision timing
- **Timing Precision:** Sub-10ms click timing accuracy target
- **Position Accuracy:** ±1 pixel positioning precision
- **Click Rate:** Support up to 100 clicks per second

## System Integration

- **Permissions Required:** 
  - Accessibility (for mouse event simulation)
  - Screen Recording (for window detection and visual overlay)
- **Global Hotkeys:** ESC key integration via Carbon framework
- **Window Management:** Process-ID based targeting for background applications
- **Visual Overlay:** Transparent floating windows with system-level display

## Security & Permissions

- **Sandboxing:** Currently not sandboxed (required for system-level mouse events)
- **Code Signing:** Apple Developer certificate with automated signing pipeline
- **Permission Management:** Real-time monitoring with System Settings deep-linking
- **Privacy Compliance:** Minimal data collection, all settings stored locally

## Architecture Patterns

- **Modular Design:** Clear separation between UI, Core logic, and Utils
- **Dependency Injection:** SwiftUI environment and `@EnvironmentObject` patterns
- **Error Handling:** Comprehensive error recovery with user feedback
- **Resource Management:** Automatic cleanup of system resources and timers
- **Background Processing:** Timer-based automation with proper lifecycle management

## Third-Party Dependencies

- **None:** Pure Swift implementation using only Apple's native frameworks
- **Rationale:** Minimal dependencies for security, performance, and maintenance
- **Previous Dependencies:** Sparkle (removed in favor of manual update checking)

## Development Workflow

- **Primary:** Xcode with SPM via `open Package.swift`
- **Command Line:** `swift build`, `swift run`, `swift test`
- **App Bundle Creation:** `./build_app_unified.sh release`
- **Development Testing:** `./build_app_unified.sh debug && open dist/ClickIt.app`
- **Automated Workflows:** `fastlane dev` for quick development cycles

## Distribution Strategy

- **Format:** Standalone .app bundle (no App Store initially)
- **Architecture:** Universal binary supporting all modern Macs
- **Installation:** Direct download and drag-to-Applications
- **Updates:** Manual check with GitHub releases integration
- **Future:** Potential Homebrew cask and App Store distribution