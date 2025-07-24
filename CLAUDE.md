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

## Build and Development Commands

### Primary Development Workflow (SPM-based)
- **Open in Xcode**: `open Package.swift` (opens the SPM project in Xcode)
- **Build app bundle**: `./build_app_unified.sh` (builds universal release app bundle)
- **Build debug**: `./build_app_unified.sh debug`
- **Run app**: `./run_clickit_unified.sh` (launches the built app bundle)

### Swift Package Manager Commands
```bash
# Open the package in Xcode (recommended for development)
open Package.swift

# Build the project (command line)
swift build

# Run the application (command line, won't create app bundle)
swift run

# Run tests
swift test

# Build for release (command line)
swift build -c release

# Build universal app bundle (recommended for distribution)
./build_app_unified.sh release
```

### Package Management
```bash
# Resolve dependencies
swift package resolve

# Clean build artifacts
swift package clean

# Reset Package.resolved
swift package reset
```

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
- Project uses Swift Package Manager as the primary build system
- Open `Package.swift` in Xcode for the best development experience
- Built app bundles are placed in `dist/` directory
- No traditional test suite - testing is done through the UI and manual validation
- Fastlane provides automation lanes that wrap existing build scripts

## Complete SPM Development Guide

### Getting Started with SPM + Xcode

**1. Open the Project**
```bash
# Navigate to the project directory
cd /path/to/clickit

# Open the Swift Package in Xcode (recommended)
open Package.swift
```

This will open the package in Xcode with full IDE support including:
- Code completion and syntax highlighting
- Integrated debugging
- Build and run capabilities
- Package dependency management
- Git integration

**2. Build and Run in Xcode**
- **Scheme**: Select "ClickIt" scheme in Xcode
- **Build**: ⌘+B to build the executable
- **Run**: ⌘+R to run in debug mode
- **Archive**: Use Product → Archive for release builds

**Note**: Running directly in Xcode (⌘+R) runs the executable but doesn't create an app bundle. For a complete app bundle with proper macOS integration, use the build scripts.

### App Bundle Creation

**For Distribution (Recommended)**
```bash
# Create universal app bundle (Intel + Apple Silicon)
./build_app_unified.sh release

# Launch the app bundle
./run_clickit_unified.sh
# or
open dist/ClickIt.app
```

**For Development Testing**
```bash
# Create debug app bundle
./build_app_unified.sh debug

# Quick development cycle with Fastlane
fastlane dev  # builds debug + runs automatically
```

### SPM Project Structure

```
ClickIt/
├── Package.swift                 # SPM manifest
├── Package.resolved             # Locked dependency versions
├── Sources/
│   └── ClickIt/                 # Main executable target
│       ├── main.swift           # App entry point
│       ├── UI/                  # SwiftUI views
│       ├── Core/               # Business logic
│       ├── Utils/              # Utilities and constants
│       └── Resources/          # App resources
├── Tests/
│   └── ClickItTests/           # Test target
└── dist/                       # Built app bundles
    └── ClickIt.app
```

### Dependency Management

**View Dependencies**
```bash
# Show dependency graph
swift package show-dependencies

# Show dependency tree
swift package show-dependencies --format tree
```

**Update Dependencies**
```bash
# Update to latest compatible versions
swift package update

# Update specific dependency
swift package update Sparkle
```

**Add New Dependencies**
Edit `Package.swift` and add to the `dependencies` array:
```swift
dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.2"),
    .package(url: "https://github.com/new-dependency/repo", from: "1.0.0")
]
```

### Build Configurations

**Debug Build**
- Optimizations disabled
- Debug symbols included
- Assertions enabled
- Fast compilation

```bash
swift build                      # Debug by default
swift build -c debug            # Explicit debug
./build_app_unified.sh debug     # Debug app bundle
```

**Release Build**
- Full optimizations enabled
- Debug symbols stripped
- Assertions disabled
- Longer compilation time

```bash
swift build -c release              # Release executable
./build_app_unified.sh release      # Release app bundle (recommended)
```

### Xcode Integration Features

**When you open `Package.swift` in Xcode, you get:**

1. **Full IDE Support**
   - Code completion and IntelliSense
   - Real-time error checking
   - Refactoring tools
   - Jump to definition

2. **Integrated Building**
   - Build with ⌘+B
   - Clean build folder with ⌘+Shift+K
   - Build settings accessible via scheme editor

3. **Debugging**
   - Breakpoints and stepping
   - Variable inspection
   - Console output
   - Memory debugging tools

4. **Testing**
   - ⌘+U to run tests
   - Test navigator showing all tests
   - Code coverage reports

5. **Git Integration**
   - Source control navigator
   - Commit and push directly from Xcode
   - Diff views and blame annotations

### Performance and Architecture

**Universal Binary Support**
The build script automatically detects and builds for available architectures:
- Intel x64 (`x86_64`)
- Apple Silicon (`arm64`)
- Creates universal binary when both are available

**Build Optimization**
```bash
# Check what architectures are supported
swift build --arch x86_64 --show-bin-path  # Intel
swift build --arch arm64 --show-bin-path   # Apple Silicon

# Build script automatically handles both
./build_app_unified.sh release
```

### Troubleshooting SPM Workflow

**Common Issues:**

1. **Dependencies not resolving**
   ```bash
   swift package clean
   swift package resolve
   ```

2. **Xcode can't find Package.swift**
   ```bash
   # Make sure you're in the right directory
   ls Package.swift
   
   # Open explicitly
   open Package.swift
   ```

3. **Build errors after dependency changes**
   ```bash
   swift package clean
   swift package resolve
   swift build
   ```

4. **App bundle not working correctly**
   ```bash
   # Ensure all dependencies are resolved first
   swift package resolve
   
   # Build fresh app bundle
   rm -rf dist/ClickIt.app
   ./build_app_unified.sh release
   ```

**Best Practices:**
- Always use `open Package.swift` instead of trying to create/open Xcode project files
- Use `./build_app_unified.sh` for app bundles rather than raw `swift build`
- Commit `Package.resolved` to ensure reproducible builds
- Use `swift package clean` when switching between architectures or configurations

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

## Known Issues & Solutions

### Application Crashes and Debugging (July 2025)

During development of Issue #8 (Visual Feedback System), several critical stability issues were discovered and resolved:

#### 🔐 **Code Signing Issues**
**Problem**: App crashes after running `./scripts/sign-app.sh`
- **Root Cause**: Expired Apple Development certificate (expired June 2021)
- **Secondary Issue**: Original signing script ran `swift build` which overwrote universal release binary with debug binary
- **Solution**: 
  - Updated to use valid certificate: `Apple Development: [DEVELOPER_NAME] ([TEAM_ID])` (certificate must be valid)
  - Fixed signing script to preserve universal binary (removed `swift build` command)
  - Check certificate validity: `security find-certificate -c "CERT_NAME" -p | openssl x509 -text -noout | grep "Not After"`

#### ⚡ **Permission System Crashes**
**Problem**: App crashes when Accessibility permission is toggled ON in System Settings
- **Root Cause**: Concurrency issues in permission monitoring system
- **Specific Issues**:
  - `PermissionManager.updatePermissionStatus()` used `DispatchQueue.main.async` despite being on `@MainActor`
  - `PermissionStatusChecker` timers used `Task { @MainActor in ... }` creating race conditions
- **Solution**:
  - Removed redundant `DispatchQueue.main.async` in `updatePermissionStatus()`
  - Changed Timer callbacks to use `DispatchQueue.main.async` instead of `Task { @MainActor }`
  - Fixed in: `PermissionManager.swift` lines 32-40, `PermissionStatusChecker.swift` lines 30-34

#### 📡 **Permission Detection Not Working**
**Problem**: App doesn't detect when permissions are granted/revoked
- **Root Cause**: Permission monitoring not started automatically
- **Solution**: Added `permissionManager.startPermissionMonitoring()` in ContentView.onAppear

#### 🧪 **Debugging Methodology**
**Approach**: Component isolation testing
1. Created minimal ContentView with only basic permission status
2. Added components incrementally: ClickPointSelector → ConfigurationPanel → Development Tools
3. Tested each addition for crash behavior when toggling permissions
4. **Result**: All UI components were safe; crashes were from underlying permission system issues

### Build & Deployment Pipeline

**Correct SPM Workflow**:
```bash
# 1. Build universal release app bundle
./build_app_unified.sh release

# 2. Sign with valid certificate (preserves binary)
CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)" ./scripts/sign-app.sh

# 3. Launch for testing
open dist/ClickIt.app
```

**Certificate Setup**:
```bash
# List available certificates
security find-identity -v -p codesigning

# Set certificate for session
export CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)"

# Or add to shell profile for persistence
echo 'export CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)"' >> ~/.zshrc
```
**Critical**: Always verify certificate validity before signing. Use `scripts/skip-signing.sh` if only self-signed certificate is needed.

### Permission System Requirements

**Essential for Stability**:
1. **Start monitoring**: Call `permissionManager.startPermissionMonitoring()` in app initialization
2. **Avoid concurrency conflicts**: Use proper `@MainActor` isolation without redundant dispatch
3. **Test permission changes**: Always test toggling permissions ON/OFF during development

## Version Management System

ClickIt uses an automated version management system that synchronizes version numbers between the UI, GitHub releases, and build processes.

### Version Architecture

**Single Source of Truth**: GitHub Release tags (e.g., `v1.4.15`)
- **GitHub Release**: Latest published version
- **Info.plist**: `CFBundleShortVersionString` (synced automatically)
- **UI Display**: Reads from `Bundle.main.infoDictionary` at runtime
- **Build Scripts**: Extract version from Info.plist (no hardcoding)

### Version Management Scripts

**Sync version with GitHub releases**:
```bash
./scripts/sync-version-from-github.sh
```
Automatically updates Info.plist to match the latest GitHub release version.

**Validate version synchronization**:
```bash
./scripts/validate-github-version-sync.sh
```
Checks if local version matches GitHub release. Used in build validation.

**Update to new version**:
```bash
./scripts/update-version.sh 1.5.0    # Creates GitHub release automatically
./scripts/update-version.sh 1.5.0 false  # Update without GitHub release
```
Complete version update workflow including Info.plist update, git commit, tag creation, and optional GitHub release trigger.

### Fastlane Integration

**Sync with GitHub**:
```bash
fastlane sync_version_with_github
```

**Release new version**:
```bash
fastlane release_with_github version:1.5.0
```

**Validate synchronization**:
```bash
fastlane validate_github_sync
```

### Git Hooks (Optional)

**Install version validation hooks**:
```bash
./scripts/install-git-hooks.sh
```
Adds pre-commit hook that validates version synchronization before commits.

### Build Integration

Build scripts automatically:
- Extract version from Info.plist
- Validate sync with GitHub releases
- Display version warnings if mismatched
- Build with correct version in app bundle

### Troubleshooting Version Issues

**UI shows wrong version**:
```bash
# Sync Info.plist with GitHub release
./scripts/sync-version-from-github.sh

# Rebuild app bundle
./build_app_unified.sh release
```

**Version mismatch detected**:
```bash
# Check current status
./scripts/validate-github-version-sync.sh

# Fix automatically
./scripts/sync-version-from-github.sh
```

**Release new version**:
```bash
# Complete workflow (recommended)
./scripts/update-version.sh 1.5.0

# Or use Fastlane
fastlane release_with_github version:1.5.0
```

### CI/CD Integration

The GitHub Actions release workflow (`.github/workflows/release.yml`) automatically:
- Validates version synchronization
- Auto-fixes version mismatches
- Verifies built app version matches tag
- Creates releases with proper version metadata

## Documentation References

- Full product requirements: `docs/clickit_autoclicker_prd.md`
- Implementation plan: `docs/issue1_implementation_plan.md`
- Task tracking: `docs/autoclicker_tasks.md`
- GitHub issues: `docs/github_issues_list.md`

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

## Quick Reference: SPM Development Workflow

### Daily Development
```bash
# 1. Open project in Xcode
open Package.swift

# 2. Develop in Xcode with full IDE support
#    - Use ⌘+B to build
#    - Use ⌘+R to run (for quick testing)
#    - Use breakpoints and debugging tools

# 3. Create app bundle for full testing
./build_app_unified.sh debug    # or 'release'

# 4. Test the app bundle
open dist/ClickIt.app
```

### Release Workflow
```bash
# 1. Final testing
./build_app_unified.sh release

# 2. Code signing (optional)
./scripts/sign-app.sh

# 3. Distribution
# App bundle ready at: dist/ClickIt.app
```

### Key Differences from Traditional Xcode Projects
- **No `.xcodeproj` file**: Use `Package.swift` as the entry point
- **Direct SPM integration**: Dependencies managed via Package.swift, not Xcode project settings
- **Universal builds**: Build script handles multi-architecture builds automatically
- **App bundle creation**: Use build scripts for proper app bundles with frameworks and Info.plist

## Agent OS Documentation

### Product Context
- **Mission & Vision:** @.agent-os/product/mission.md
- **Technical Architecture:** @.agent-os/product/tech-stack.md
- **Development Roadmap:** @.agent-os/product/roadmap.md
- **Decision History:** @.agent-os/product/decisions.md

### Development Standards
- **Code Style:** @~/.agent-os/standards/code-style.md
- **Best Practices:** @~/.agent-os/standards/best-practices.md

### Project Management
- **Active Specs:** @.agent-os/specs/
- **Spec Planning:** Use `@~/.agent-os/instructions/create-spec.md`
- **Tasks Execution:** Use `@~/.agent-os/instructions/execute-tasks.md`

## Workflow Instructions

When asked to work on this codebase:

1. **First**, check @.agent-os/product/roadmap.md for current priorities
2. **Then**, follow the appropriate instruction file:
   - For new features: @.agent-os/instructions/create-spec.md
   - For tasks execution: @.agent-os/instructions/execute-tasks.md
3. **Always**, adhere to the standards in the files listed above

## Important Notes

- Product-specific files in `.agent-os/product/` override any global standards
- User's specific instructions override (or amend) instructions found in `.agent-os/specs/...`
- Always adhere to established patterns, code style, and best practices documented above.
