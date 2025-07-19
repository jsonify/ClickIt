# ClickIt Fastlane User Guide

This guide explains how to use Fastlane for automating ClickIt development and release workflows.

## Table of Contents
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Available Lanes](#available-lanes)
- [Development Workflows](#development-workflows)
- [Release Workflows](#release-workflows)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Installation

### Prerequisites
- macOS with Xcode installed
- Ruby (comes with macOS)
- Homebrew (recommended)

### Install Fastlane

**Option 1: Homebrew (Recommended)**
```bash
brew install fastlane
```

**Option 2: RubyGems**
```bash
gem install fastlane
```

**Option 3: Bundler (for team consistency)**
```bash
# Add to Gemfile if you create one
gem 'fastlane'
bundle install
```

### Verify Installation
```bash
fastlane --version
```

## Quick Start

Navigate to your ClickIt project directory and run:

```bash
# Quick development workflow
fastlane dev

# Full release workflow  
fastlane release

# See all available lanes
fastlane lanes
```

## Available Lanes

### Development Lanes

#### `fastlane build_debug`
**Purpose**: Build a debug version of ClickIt
**Output**: `dist/ClickIt.app` (debug build)
**Use when**: 
- Developing new features
- Testing changes
- Need debug symbols for debugging

```bash
fastlane build_debug
```

#### `fastlane build_release`
**Purpose**: Build a release version of ClickIt
**Output**: `dist/ClickIt.app` (optimized build)
**Use when**:
- Preparing for distribution
- Performance testing
- Creating final builds

```bash
fastlane build_release
```

#### `fastlane run`
**Purpose**: Build debug version and launch the app
**Use when**: Quick testing during development

```bash
fastlane run
```

### Utility Lanes

#### `fastlane clean`
**Purpose**: Clean all build artifacts
**What it cleans**:
- `dist/` directory contents
- Xcode DerivedData for ClickIt
**Use when**:
- Build issues occur
- Starting fresh
- Before major releases

```bash
fastlane clean
```

#### `fastlane verify_signing`
**Purpose**: Check code signing status of built app
**Shows**:
- Whether app is signed
- Certificate details
- Signing validity
**Use when**:
- Troubleshooting distribution issues
- Verifying certificates

```bash
fastlane verify_signing
```

#### `fastlane info`
**Purpose**: Display comprehensive app bundle information
**Shows**:
- Bundle size
- Version and build numbers
- Supported architectures
- Required permissions
**Use when**:
- Preparing release notes
- Checking build details

```bash
fastlane info
```

### Workflow Lanes

#### `fastlane dev`
**Purpose**: Complete development workflow
**Steps**:
1. Build debug version
2. Launch the app
**Use when**: Starting a development session

```bash
fastlane dev
```

#### `fastlane release`
**Purpose**: Complete release workflow
**Steps**:
1. Clean previous builds
2. Build release version
3. Verify code signing
4. Display app information
**Use when**: Preparing a release

```bash
fastlane release
```

## Development Workflows

### Daily Development
```bash
# Start your development session
fastlane dev

# Make code changes in Xcode...

# Quick rebuild and test
fastlane run

# Clean and rebuild if issues
fastlane clean
fastlane dev
```

### Feature Development
```bash
# Clean start
fastlane clean

# Build and test
fastlane build_debug
fastlane verify_signing

# Check app details
fastlane info
```

### Bug Fixing
```bash
# Build debug with symbols
fastlane build_debug

# Launch for testing
fastlane run

# Verify fixes work
fastlane build_release
fastlane verify_signing
```

## Release Workflows

### Pre-Release Testing
```bash
# Full clean build
fastlane clean
fastlane build_release

# Verify everything looks good
fastlane verify_signing
fastlane info
```

### Release Preparation
```bash
# Complete release workflow
fastlane release

# Manual steps after Fastlane:
# 1. Test the app thoroughly
# 2. Update version numbers if needed
# 3. Create release notes
# 4. Package for distribution (DMG, etc.)
```

### Distribution Ready
```bash
# Final release build
fastlane release

# Optional: Create DMG or other distribution format
# (not automated by Fastlane currently)
```

## Troubleshooting

### Common Issues

#### "fastlane command not found"
**Problem**: Fastlane not installed or not in PATH
**Solution**:
```bash
# Check if installed
which fastlane

# Install if missing
brew install fastlane

# Add to PATH if needed (add to ~/.zshrc or ~/.bash_profile)
export PATH="$HOME/.fastlane/bin:$PATH"
```

#### "Build failed"
**Problem**: Xcode build errors
**Solution**:
```bash
# Clean and retry
fastlane clean
fastlane build_debug

# Check Xcode project directly
open ClickIt.xcodeproj
```

#### "Code signing failed"
**Problem**: Certificate issues
**Solution**:
```bash
# Check signing status
fastlane verify_signing

# Check available certificates
security find-identity -v -p codesigning

# Use manual build script if needed
./build_app_unified.sh debug
```

#### "App won't launch"
**Problem**: Permissions or build issues
**Solution**:
```bash
# Try manual launch
open dist/ClickIt.app

# Check app info
fastlane info

# Rebuild if needed
fastlane clean
fastlane build_debug
```

### Debug Mode
Add `--verbose` to any Fastlane command for detailed output:
```bash
fastlane build_debug --verbose
```

## Advanced Usage

### Custom Environments
You can set environment variables for specific builds:
```bash
# Example: Set custom build number
BUILD_NUMBER=12345 fastlane build_release
```

### Integration with CI/CD
For continuous integration, use:
```bash
# Non-interactive mode
fastlane build_release --skip_docs

# With custom configuration
FASTLANE_SKIP_UPDATE_CHECK=1 fastlane release
```

### Extending Fastlane
To add custom lanes, edit `fastlane/Fastfile`:

```ruby
lane :my_custom_lane do
  # Your custom automation
  UI.message("Running custom workflow...")
  build_debug
  # Add more steps...
end
```

### Multiple Configurations
You can create different app configurations:
```bash
# Edit fastlane/Appfile to add multiple targets
# Then use specific lanes for different builds
```

## Tips and Best Practices

### Performance
- Use `fastlane clean` when switching between debug/release builds
- Keep Xcode closed during automated builds for better performance

### Development
- Use `fastlane dev` for quick iteration
- Use `fastlane release` before important demos or releases
- Always run `fastlane verify_signing` before distributing

### Team Workflow
- Commit `fastlane/` directory to version control
- Document any custom lanes you add
- Use consistent lane names across projects

### Automation
- Set up aliases for common commands:
  ```bash
  alias fdev="fastlane dev"
  alias frel="fastlane release"
  alias fclean="fastlane clean"
  ```

## Integration with Existing Scripts

Fastlane wraps your existing build scripts:
- `fastlane build_debug` → `./build_app_unified.sh debug`
- `fastlane build_release` → `./build_app_unified.sh release`
- `fastlane run` → build + `./run_clickit_unified.sh app`

You can still use the original scripts directly when needed.

## Getting Help

```bash
# List all available lanes
fastlane lanes

# Get help for a specific lane
fastlane action_name --help

# Fastlane documentation
fastlane docs
```

For ClickIt-specific issues, check:
- `README.md` - Project overview
- `CLAUDE.md` - Development guidance
- `scripts/README.md` - Build script details

---

*This guide covers the Fastlane setup specific to ClickIt. For general Fastlane documentation, visit [docs.fastlane.tools](https://docs.fastlane.tools)*