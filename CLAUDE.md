# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClickIt is a native macOS auto-clicker application built with Swift Package Manager and SwiftUI. It provides precision clicking automation for macOS with advanced window targeting and global hotkey support.

**Key Features:**
- Native macOS SwiftUI application
- Universal binary support (Intel x64 + Apple Silicon)
- Sub-10ms click timing accuracy
- Background operation without requiring app focus
- Global hotkey controls (ESC key)
- Preset configuration system
- Visual feedback with overlay indicators

## Development Commands

### Building & Testing
```bash
# Build the project
swift build

# Run the application
swift run

# Run tests
swift test

# Build for release
swift build -c release
```

### Package Management
```bash
# Generate Xcode project (if needed)
swift package generate-xcodeproj

# Resolve dependencies
swift package resolve

# Clean build artifacts
swift package clean
```

## Architecture Overview

The project follows a modular architecture with clear separation of concerns:

### Core Structure
- **Sources/ClickIt/**: Main application code
  - **UI/**: SwiftUI views and components
    - **Views/**: Main application views (ContentView.swift)
    - **Components/**: Reusable UI components (planned)
  - **Core/**: Business logic modules (planned structure)
    - **Click/**: Click engine and timing logic
    - **Window/**: Window detection and targeting
    - **Permissions/**: macOS permissions handling
  - **Utils/**: Utilities and helpers
    - **Constants/**: App-wide constants (AppConstants.swift)
    - **Extensions/**: Swift extensions (planned)
  - **Resources/**: Assets and resource files

### Key Technical Components

**Required Frameworks:**
- **CoreGraphics**: Mouse event generation and window targeting
- **Carbon**: Global hotkey registration (ESC key)
- **ApplicationServices**: Window detection and management
- **SwiftUI**: User interface framework

**Core Implementation Areas:**
- Window targeting using `CGWindowListCopyWindowInfo`
- Background clicking with `CGEventCreateMouseEvent` and `CGEventPostToPid`
- Global hotkey handling for ESC key controls
- Precision timing system with CPS randomization
- Visual overlay system using `NSWindow` with `NSWindowLevel.floating`

## System Requirements

- **macOS Version**: 15.0 or later
- **Architecture**: Universal binary (Intel x64 + Apple Silicon)
- **Required Permissions**:
  - Accessibility (for mouse event simulation)
  - Screen Recording (for window detection and visual overlay)

## Current Implementation Status

The project is in early development with basic structure established:
- ✅ Swift Package Manager configuration
- ✅ Basic SwiftUI app structure
- ✅ Framework imports and constants
- ⏳ Core clicking functionality (planned)
- ⏳ Window targeting system (planned)
- ⏳ Permission management (planned)

## Development Guidelines

### Code Organization
- Follow the established modular structure
- Keep UI logic separate from business logic
- Use the existing constants system in `AppConstants.swift`
- Import required frameworks at the top of relevant files

### Performance Considerations
- Target sub-10ms click timing accuracy
- Maintain minimal CPU/memory footprint (<50MB RAM, <5% CPU at idle)
- Optimize for both Intel and Apple Silicon architectures

### macOS Integration
- Utilize native macOS APIs for all core functionality
- Handle required permissions gracefully
- Support background operation without app focus
- Implement proper window targeting for minimized applications

## Key Implementation Notes

**Window Targeting**: Use process ID rather than window focus to enable clicking on minimized/hidden windows

**Timing System**: Implement dynamic timer with CPS randomization: `random(baseCPS - variation, baseCPS + variation)`

**Visual Feedback**: Create transparent overlay windows that persist during operation

**Preset System**: Store configurations in UserDefaults with custom naming support

## Documentation References

- Full product requirements: `docs/clickit_autoclicker_prd.md`
- Implementation plan: `docs/issue1_implementation_plan.md`
- Task tracking: `docs/autoclicker_tasks.md`
- GitHub issues: `docs/github_issues_list.md`