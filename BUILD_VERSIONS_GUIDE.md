# Building Pro vs Lite Versions Guide

This guide explains how to build either **ClickIt Pro** (full-featured) or **ClickIt Lite** (simplified) using fastlane.

## Quick Start

### Build ClickIt Pro (Full Version)

```bash
# Debug build
fastlane build_debug

# Release build
fastlane build_release

# Build and launch
fastlane launch
```

### Build ClickIt Lite (Simplified Version)

```bash
# Debug build
fastlane build_lite_debug

# Release build
fastlane build_lite_release

# Build and launch
fastlane launch_lite
```

## How It Works

### 1. Toggle Script

The `toggle_version.sh` script automatically switches between Pro and Lite by:
- Commenting/uncommenting `@main` in `ClickItApp.swift` (Pro)
- Uncommenting/commenting `@main` in `ClickItLiteApp.swift` (Lite)

### 2. Build Script

The `build_app_unified.sh` script now accepts a third parameter:

```bash
./build_app_unified.sh [BUILD_MODE] [BUILD_SYSTEM] [APP_VERSION]
```

**Parameters:**
- `BUILD_MODE`: `debug` or `release` (default: `release`)
- `BUILD_SYSTEM`: `spm`, `xcode`, or `auto` (default: `auto`)
- `APP_VERSION`: `pro` or `lite` (default: `pro`)

**Examples:**

```bash
# Build Pro version (default)
./build_app_unified.sh debug spm pro

# Build Lite version
./build_app_unified.sh release spm lite

# Default parameters build Pro
./build_app_unified.sh
```

### 3. Fastlane Lanes

New lanes have been added:

#### Pro Version (Full ClickIt)
- `fastlane build_debug` - Build Pro in debug mode
- `fastlane build_release` - Build Pro in release mode
- `fastlane launch` - Build and launch Pro version

#### Lite Version (Simplified ClickIt)
- `fastlane build_lite_debug` - Build Lite in debug mode
- `fastlane build_lite_release` - Build Lite in release mode
- `fastlane launch_lite` - Build and launch Lite version

## What Changes Between Versions

### ClickIt Pro (Full Version)
- **App Name**: `ClickIt.app`
- **Bundle ID**: `com.jsonify.clickit`
- **Features**: All 139 source files, 5 tabs, full feature set
- **Output**: `dist/ClickIt.app`

### ClickIt Lite (Simplified Version)
- **App Name**: `ClickIt Lite.app`
- **Bundle ID**: `com.jsonify.clickit.lite`
- **Features**: 7 source files, single window, core features only
- **Output**: `dist/ClickIt Lite.app`

## Manual Switching (Advanced)

If you need to manually switch without using the build system:

```bash
# Switch to Lite
./toggle_version.sh lite

# Switch to Pro
./toggle_version.sh pro
```

## Build Output

After building, you'll find:

```
dist/
├── ClickIt.app           # Pro version (if built)
├── ClickIt Lite.app      # Lite version (if built)
├── binaries/             # Intermediate build artifacts
└── build-info.txt        # Build metadata
```

## Build Metadata

Each build includes metadata showing which version was built:

```
🔨 Building ClickIt Lite app bundle (release mode)...
📦 Version: 1.5.5 (from Info.plist, synced with GitHub releases)
🏷️  Edition: Lite (Simplified)
```

Or for Pro:

```
🔨 Building ClickIt app bundle (release mode)...
📦 Version: 1.5.5 (from Info.plist, synced with GitHub releases)
🏷️  Edition: Pro (Full Featured)
```

## Testing Both Versions

You can have both versions built simultaneously:

```bash
# Build Pro
fastlane build_release

# Build Lite
fastlane build_lite_release

# Both apps now exist in dist/
ls dist/
# ClickIt.app
# ClickIt Lite.app
```

Both can be installed and run side-by-side since they have different bundle IDs.

## CI/CD Integration

For automated builds, you can specify which version to build:

```yaml
# GitHub Actions example
- name: Build Pro Version
  run: fastlane build_release

- name: Build Lite Version
  run: fastlane build_lite_release
```

## Troubleshooting

### Build fails with "duplicate @main"

The toggle script should handle this automatically, but if it fails:

```bash
# Manually fix by running:
./toggle_version.sh pro   # or lite

# Then rebuild
fastlane build_debug
```

### Wrong version being built

Check which `@main` is active:

```bash
# Check ClickItApp.swift (Pro)
grep "@main" Sources/ClickIt/ClickItApp.swift

# Check ClickItLiteApp.swift (Lite)
grep "@main" Sources/ClickIt/Lite/ClickItLiteApp.swift
```

Only ONE should be uncommented at a time.

### Clean and rebuild

```bash
fastlane clean
fastlane build_lite_debug  # or build_debug for Pro
```

## Summary

| Command | Version | Mode | Output |
|---------|---------|------|--------|
| `fastlane build_debug` | Pro | Debug | `dist/ClickIt.app` |
| `fastlane build_release` | Pro | Release | `dist/ClickIt.app` |
| `fastlane build_lite_debug` | Lite | Debug | `dist/ClickIt Lite.app` |
| `fastlane build_lite_release` | Lite | Release | `dist/ClickIt Lite.app` |
| `fastlane launch` | Pro | Debug | Builds and launches Pro |
| `fastlane launch_lite` | Lite | Debug | Builds and launches Lite |

---

**Note**: The toggle script runs automatically during the build process, so you don't need to manually run it when using fastlane.
