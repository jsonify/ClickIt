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

## Development Guidelines

### Workflow Reminders
- Always check most recent agent os spec task lists for next feature to work on

### Image Resource Updates

When updating image assets (like `target-64.png`), you **must** rebuild the app to see changes:

**Why:** Swift Package Manager bundles resources into `.bundle` files at build time. The app loads from the bundle, not the source file.

**Steps to update an image:**
1. Replace the image file in `Sources/ClickIt/Lite/Resources/`
2. Clean the build: `swift package clean` or in Xcode: `Product > Clean Build Folder` (⇧⌘K).
3. Rebuild: `swift build` or in Xcode: `Product > Build` (⌘B).
4. The new image will now be bundled and loaded

**Quick command:**
```bash
rm -rf .build && swift build
```

**Note:** The cursor image is loaded once at app launch and cached in memory. You must restart the app after rebuilding to see the updated image.