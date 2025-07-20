# ClickIt

A lightweight, native macOS Auto-Clicker application with precision timing and advanced targeting capabilities. Designed for gamers, automation enthusiasts, and productivity users who need reliable, accurate clicking automation.

## Features

- **Native macOS Application**: Built with SwiftUI for optimal performance
- **Universal Binary**: Supports both Intel x64 and Apple Silicon
- **Advanced Window Targeting**: Works with any application, even when minimized
- **Precision Timing**: Sub-10ms click timing accuracy with customizable intervals
- **Visual Feedback**: Shows click points with overlay indicators
- **Preset System**: Save and load custom clicking configurations
- **Global Hotkeys**: System-wide controls for start/stop operations
- **Variable Timing**: Human-like randomization patterns
- **Background Operation**: Continues operation without requiring app focus

## Use Cases

- **Gaming**: Automated clicking for various games and applications
- **Testing**: UI testing and automation workflows
- **Productivity**: Repetitive task automation
- **Accessibility**: Assistance for users with mobility limitations

## Requirements

- macOS 15.0 or later
- Accessibility permissions (for mouse event simulation)
- Screen Recording permissions (for window detection and targeting)

## Installation

[Installation instructions will be added once the app is ready for distribution]

## Development

This project supports both Xcode and Swift Package Manager workflows for flexible development.

### Quick Start

#### 🎯 **For Development**
```bash
# Open in Xcode for development
open ClickIt.xcodeproj
```

#### 🏗️ **For Building and Running**
```bash
# Build (auto-detects best method)
./build_app_unified.sh

# Run the built app
./run_clickit_unified.sh

# Or run directly with Xcode
./run_clickit_unified.sh xcode
```

### Prerequisites
- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 15.0 or later

### Build Commands

#### Unified Build System
```bash
./build_app_unified.sh              # Build release version
./build_app_unified.sh debug        # Build debug version  
./build_app_unified.sh release xcode # Force Xcode build system
```

#### Traditional Swift Package Manager
```bash
# Build for current architecture (debug)
swift build

# Run directly
swift run

# Build for release
swift build -c release
```

#### Legacy Build System
```bash
# Create universal app bundle (Intel + Apple Silicon)
./build_app.sh

# Create debug app bundle
./build_app.sh debug
```

### Run Commands  
```bash
./run_clickit_unified.sh            # Auto-detect best run method
./run_clickit_unified.sh app        # Run from dist/ClickIt.app
./run_clickit_unified.sh xcode      # Build and run with Xcode
```

### Development Workflow
1. **Daily Development**: Use Xcode for coding, debugging, and testing
2. **Release Builds**: Use `./build_app_unified.sh release` for distribution
3. **Quick Testing**: Use `./run_clickit_unified.sh` for fast app launches

### Build Output Structure
- `dist/ClickIt.app` - Final app bundle
- `dist/binaries/` - Individual architecture binaries
- `dist/build-info.txt` - Build metadata
- `.build/` - Swift Package Manager build cache

### Universal Binary Support
The build system automatically detects available architectures and creates universal binaries when possible:
- **Intel x64**: `x86_64-apple-macosx`
- **Apple Silicon**: `arm64-apple-macosx`
- **Universal**: Combined binary supporting both architectures

### Code Signing for Permission Persistence

The build script automatically attempts to code sign the app to improve permission persistence. This helps avoid having to re-grant Accessibility and Screen Recording permissions after each rebuild.

**Automatic Signing:**
The build script will automatically:
1. Look for ClickIt-specific certificates first
2. Fall back to any available Apple Developer certificates
3. Display the signing status in the build output

**For Self-Signed Certificates:**
If you don't have an Apple Developer account, you can create a self-signed certificate:
```bash
# See detailed instructions
cat CERTIFICATE_SETUP.md
```

**Verify Code Signing:**
```bash
# Check if app is signed
codesign --display --verbose dist/ClickIt.app

# Verify signature
codesign --verify --verbose dist/ClickIt.app
```

### Testing
```bash
# Run unit tests
swift test

# Build and test specific configuration
swift build -c release
swift test -c release
```

## Documentation

### 📋 **Complete Development Workflow**
- **[Git Workflow Guide](docs/git-workflow-guide.md)** - Complete step-by-step git workflow from feature development to production release
- **[Fastlane Guide](docs/fastlane-guide.md)** - Automated build and release system documentation

### 🚀 **Quick Reference**

#### **Daily Development**
```bash
# 1. Start new feature
git checkout main && git pull && git checkout -b feature/my-feature

# 2. Develop and test
fastlane dev  # Build and launch for testing

# 3. Merge to staging for beta testing
git checkout staging && git merge feature/my-feature

# 4. Create beta release
fastlane auto_beta
```

#### **Production Release**
```bash
# 1. Promote staging to main
git checkout main && git merge staging

# 2. Automated release with version bumping
fastlane bump_and_release bump:minor  # 1.0.0 → 1.1.0
```

### 📚 **Additional Documentation**
- **[CLAUDE.md](CLAUDE.md)** - Development guidance and project overview
- **[BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md)** - Manual build and deployment instructions
- **[CERTIFICATE_SETUP.md](CERTIFICATE_SETUP.md)** - Code signing certificate setup

## Contributing

Contributions are welcome! Please read our contributing guidelines and check the Issues tab for open tasks.

**Before contributing**: Read the [Git Workflow Guide](docs/git-workflow-guide.md) to understand our branch strategy and release process.

## License

MIT License - see LICENSE file for details

## Disclaimer

This software is intended for legitimate automation purposes. Users are responsible for ensuring their use complies with the terms of service of any applications they target and applicable laws and regulations.
