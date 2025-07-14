# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Primary Development Workflow
- **Build app**: `./build_app_unified.sh` (auto-detects Xcode project, builds release version)
- **Build debug**: `./build_app_unified.sh debug`
- **Run app**: `./run_clickit_unified.sh` (auto-detects best run method)
- **Open in Xcode**: `open ClickIt.xcodeproj`

### Alternative Build Methods
- **Force Xcode build**: `./build_app_unified.sh release xcode`
- **Force SPM build**: `./build_app_unified.sh release spm`
- **Run from app bundle**: `./run_clickit_unified.sh app`
- **Run with Xcode**: `./run_clickit_unified.sh xcode`

### Fastlane Automation
- **Build debug**: `fastlane build_debug`
- **Build release**: `fastlane build_release`
- **Build and run**: `fastlane run`
- **Clean builds**: `fastlane clean`
- **Verify code signing**: `fastlane verify_signing`
- **App info**: `fastlane info`
- **Full release workflow**: `fastlane release`
- **Development workflow**: `fastlane dev`

### Development Notes
- Project supports both Xcode and Swift Package Manager workflows
- Xcode project is primary development environment
- Built apps are placed in `dist/` directory
- No traditional test suite - testing is done through the UI and manual validation
- Fastlane provides automation lanes that wrap existing build scripts

## Architecture Overview

### Core Architecture Pattern
The app follows a SwiftUI + Core separation pattern with these main layers:

1. **App Layer** (`ClickItApp.swift`): Main app entry point with permission gating
2. **UI Layer** (`UI/`): SwiftUI views and view models
3. **Core Layer** (`Core/`): Business logic and system interactions
4. **Utils Layer** (`Utils/`): Shared utilities and constants

### Key Components

#### Click System
- **ClickCoordinator**: High-level automation orchestrator (singleton)
- **ClickEngine**: Low-level click execution using CoreGraphics
- **BackgroundClicker**: Application-specific background clicking
- **ClickType**: Enumeration for left/right click types

#### Permission System
- **PermissionManager**: Manages accessibility and screen recording permissions
- Accessibility permission required for mouse event injection
- Screen recording permission needed for window detection

#### Window Management
- **WindowManager**: System window detection and management
- **WindowTargeter**: Application window targeting
- **WindowDetectionTester**: Testing window detection capabilities

#### Settings and State
- **ClickItViewModel**: Main UI state management
- **ClickSettings**: Persistent configuration management
- Uses UserDefaults for settings persistence

### Coordinate Systems
The app handles two coordinate systems:
- **AppKit coordinates**: Used by NSEvent and UI positioning (origin top-left)
- **CoreGraphics coordinates**: Used by CGEvent for click injection (origin bottom-left)
- Conversion functions handle multi-monitor setups correctly

### Timer and Automation Modes
- **Immediate mode**: Starts clicking immediately at selected point
- **Timer mode**: Countdown timer before starting dynamic mouse tracking
- **Dynamic mode**: Follows mouse cursor during automation
- Visual feedback overlay shows click locations in real-time

## Code Signing
- Code signing is handled automatically in build scripts
- Looks for "ClickIt Developer Certificate" first
- Falls back to available development certificates
- See `scripts/README.md` for manual code signing setup

## Permission Requirements
- **Accessibility**: Required for mouse event injection
- **Screen Recording**: Required for window detection features
- App shows permission gate on first launch
- Permissions are checked continuously during runtime

## File Structure Notes
- Main source code in `ClickIt/` directory
- UI components organized by function in `UI/Components/`
- Core functionality separated by domain in `Core/`
- Build outputs go to `dist/` directory
- Scripts for common operations in `scripts/` directory
- Fastlane configuration in `fastlane/` directory

## Fastlane Setup
To use Fastlane automation, first install it:
```bash
# Install via Homebrew (recommended)
brew install fastlane

# Or install via gem
gem install fastlane
```

Then you can use any of the configured lanes:
- `fastlane dev` - Quick development workflow (build debug + run)
- `fastlane release` - Full release workflow (clean + build + verify + info)
- `fastlane build_debug` - Build debug version
- `fastlane build_release` - Build release version
- `fastlane clean` - Clean build artifacts
- `fastlane verify_signing` - Check code signing status
- `fastlane info` - Display app bundle information

The Fastlane setup integrates with existing build scripts and adds automation conveniences.

For detailed usage instructions, workflows, and troubleshooting, see: **[docs/fastlane-guide.md](docs/fastlane-guide.md)**

## Documentation
- `docs/fastlane-guide.md` - Comprehensive Fastlane user guide with workflows and troubleshooting