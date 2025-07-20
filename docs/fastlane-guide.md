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

### Most Common Commands (Post-July 2025 Fixes)
```bash
# Daily development
fastlane dev              # Build debug + launch app
fastlane launch           # Quick build + launch for testing
fastlane clean            # Clean when build issues occur

# Release preparation  
fastlane build_release    # Production build
fastlane info            # Check app details
fastlane release         # Complete release workflow

# 🤖 AUTOMATED RELEASES (NEW)
fastlane auto_beta        # Zero-friction beta release with auto-tagging
fastlane auto_prod        # Zero-friction production release with auto-tagging  
fastlane bump_and_release # Smart version bump + automated release

# Troubleshooting
fastlane verify_signing  # Check code signing status
fastlane clean           # Fresh start when needed
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

#### `fastlane launch`
**Purpose**: Build debug version and launch the app
**Use when**: Quick testing during development

```bash
fastlane launch
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

#### `fastlane beta`
**Purpose**: Create beta release using Makefile workflow
**Steps**:
1. Validates staging branch
2. Creates beta-* tag
3. Builds release version
4. Creates GitHub release
**Use when**: Creating beta releases for testing

```bash
fastlane beta
```

#### `fastlane prod`
**Purpose**: Create production release using Makefile workflow  
**Steps**:
1. Validates main branch
2. Creates v* tag
3. Builds release version
4. Creates GitHub release
**Use when**: Creating official production releases

```bash
fastlane prod
```

### 🤖 Automated Release Lanes (NEW)

#### `fastlane auto_beta`
**Purpose**: Fully automated beta release with auto-generated tags
**What it does**:
1. Validates you're on `staging` branch
2. Checks for uncommitted changes
3. **Automatically creates** `beta-v{version}-{timestamp}` tag
4. Pushes tag to remote
5. Builds and creates GitHub release
**Use when**: You want zero-friction beta releases

```bash
# Use default version (1.0.0)
fastlane auto_beta

# Specify custom version
fastlane auto_beta version:2.1.0
```

#### `fastlane auto_prod`
**Purpose**: Fully automated production release with auto-generated tags
**What it does**:
1. Validates you're on `main` branch  
2. Checks for uncommitted changes
3. **Automatically creates** `v{version}` tag
4. Validates tag doesn't already exist
5. Pushes tag to remote
6. Builds and creates GitHub release
**Use when**: You want zero-friction production releases

```bash
# Use default version (1.0.0)
fastlane auto_prod

# Specify custom version  
fastlane auto_prod version:2.1.0
```

#### `fastlane bump_and_release`
**Purpose**: Intelligent version bumping with automated release
**What it does**:
1. Validates you're on `main` branch
2. **Automatically detects** current version from git tags
3. **Automatically bumps** version (patch/minor/major)
4. Shows preview and asks for confirmation
5. Creates production release with new version
**Use when**: You want semantic versioning automation

```bash
# Bump patch version (1.0.0 → 1.0.1)
fastlane bump_and_release

# Bump minor version (1.0.1 → 1.1.0)
fastlane bump_and_release bump:minor

# Bump major version (1.1.0 → 2.0.0)
fastlane bump_and_release bump:major

# Skip confirmation prompt
fastlane bump_and_release bump:minor force:true
```

## Development Workflows

### 🤖 Automated Release Workflows (RECOMMENDED)

#### Zero-Friction Beta Release
```bash
# Switch to staging branch
git checkout staging

# Make sure everything is committed
git add . && git commit -m "Ready for beta"

# One command beta release with auto-tagging
fastlane auto_beta
# Creates: beta-v1.0.0-202507201145
```

#### Zero-Friction Production Release  
```bash
# Switch to main branch
git checkout main

# Make sure everything is committed  
git add . && git commit -m "Ready for production"

# One command production release with auto-tagging
fastlane auto_prod version:1.2.0
# Creates: v1.2.0
```

#### Smart Version Bumping
```bash
# Switch to main branch
git checkout main

# Automatic version detection and bumping
fastlane bump_and_release bump:minor
# Detects current v1.1.0 → creates v1.2.0
```

### Daily Development
```bash
# Start your development session
fastlane dev

# Make code changes in Xcode...

# Quick rebuild and test
fastlane launch

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
fastlane launch

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

## Recent Improvements (July 2025)

### Fixed Issues
✅ **Build Output Location**: Fixed issue where builds were created in `fastlane/dist/` instead of project root `dist/`
✅ **Warning Suppression**: Eliminated verbose Gemfile and plugin warnings for cleaner output
✅ **Lane Naming**: Renamed `run` lane to `launch` to avoid Fastlane reserved keyword conflicts
✅ **Directory Context**: All commands now execute from correct project root directory

### Clean Output
Fastlane now provides clean, focused output without unnecessary warnings:
- No more "bundle exec" suggestions
- No more plugin loading messages
- No more Gemfile detection warnings
- Analytics and usage tracking disabled for faster execution

### Verified Working Features
- ✅ Universal binary builds (Intel x64 + Apple Silicon)
- ✅ Automatic code signing with self-signed certificates  
- ✅ App icon processing and bundle creation
- ✅ Build metadata generation
- ✅ All lanes create outputs in correct `dist/` directory

## Troubleshooting

### Common Issues

#### "App builds but not found in dist/"
**Problem**: Build completes successfully but `dist/ClickIt.app` doesn't exist
**Solution**: This was a known issue (fixed July 2025). If you encounter this:
```bash
# Verify the fix is in place - check Fastfile contains Dir.chdir("..") 
grep -n "Dir.chdir" fastlane/Fastfile

# If missing, update your Fastfile or re-clone the repository
# The build should now create files in the correct location
```

#### "Too many warnings from Fastlane"
**Problem**: Verbose Gemfile and plugin warnings clutter output
**Solution**: Already fixed (July 2025) by:
- Adding `opt_out_usage` and `skip_docs` to Fastfile
- Renaming `Gemfile` to `Gemfile.unused`
- Disabling unused plugins
```bash
# Verify clean output
fastlane info
# Should show minimal warning messages
```

#### "Lane name 'run' is invalid"
**Problem**: Reserved keyword conflict with Fastlane
**Solution**: Lane renamed to `launch` (fixed July 2025)
```bash
# Use the new command
fastlane launch  # Instead of fastlane run
```

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
- `fastlane launch` → build + `./run_clickit_unified.sh app`

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

## Verification & Testing

### Verify Your Setup Works
After installation, test these core commands:

```bash
# 1. Check Fastlane is working
fastlane lanes
# Should list all available lanes without errors

# 2. Test info command (works without building)
fastlane info
# Should show app information or "App not found" message

# 3. Test a quick build
fastlane build_debug
# Should create dist/ClickIt.app

# 4. Verify output location
ls -la dist/
# Should show ClickIt.app, binaries/, and build-info.txt

# 5. Test complete workflow
fastlane dev
# Should build and launch the app
```

### Expected Output Locations
After successful builds, you should see:
```
dist/
├── ClickIt.app/           # Main app bundle
├── binaries/              # Architecture-specific binaries
└── build-info.txt         # Build metadata
```

### Manual vs Automated Workflow Comparison

#### ❌ Manual Workflow (Old Way)
```bash
# Beta release - multiple manual steps
git checkout staging
git tag beta-v1.0.0-20250720
git push origin --tags
fastlane beta

# Production release - multiple manual steps  
git checkout main
git tag v1.0.0
git push origin --tags
fastlane prod
```

#### ✅ Automated Workflow (New Way)
```bash
# Beta release - one command
git checkout staging
fastlane auto_beta

# Production release - one command
git checkout main  
fastlane auto_prod version:1.0.0

# Smart version bumping - one command
fastlane bump_and_release bump:patch
```

**Benefits of Automation**:
- ✅ **Zero tag management** - No manual tag creation or pushing
- ✅ **Version validation** - Prevents duplicate tags automatically
- ✅ **Git state validation** - Ensures clean working directory
- ✅ **Branch validation** - Enforces correct branch for release type
- ✅ **Intelligent versioning** - Auto-detects current version and bumps appropriately
- ✅ **One-command releases** - Complete automation from commit to GitHub release

**Important**: If builds appear successful but `dist/ClickIt.app` is missing, you may have an older version of the Fastfile. Update to the latest version with the July 2025 fixes.

---

*This guide covers the Fastlane setup specific to ClickIt. For general Fastlane documentation, visit [docs.fastlane.tools](https://docs.fastlane.tools)*