# ClickIt - macOS Auto-Clicker (Xcode Project)

This is the primary development directory for ClickIt, supporting both Xcode and Swift Package Manager workflows.

## Quick Start

### 🎯 **For Development**
```bash
# Open in Xcode for development
open ClickIt.xcodeproj
```

### 🏗️ **For Building and Running**
```bash
# Build (auto-detects Xcode project)
./build_app_unified.sh

# Run the built app
./run_clickit_unified.sh

# Or run directly with Xcode
./run_clickit_unified.sh xcode
```

## Available Commands

### Build Commands
```bash
./build_app_unified.sh              # Build release version
./build_app_unified.sh debug        # Build debug version  
./build_app_unified.sh release xcode # Force Xcode build system
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

## Directory Structure

```
/Users/jsonify/code/macOS/ClickIt/     # Primary development directory
├── ClickIt.xcodeproj/                 # Xcode project
├── ClickIt/                          # Source code
├── dist/                             # Built app bundles  
├── scripts/                          # Utility scripts
├── build_app_unified.sh             # Unified build script
└── run_clickit_unified.sh           # Unified run script
```

## Related Directories

- **Original SPM Project**: `/Users/jsonify/code/clickit/` (archived)
- **Primary Xcode Project**: `/Users/jsonify/code/macOS/ClickIt/` ← **You are here**

## Features

✅ **Dual Build System**: Supports both Xcode and Swift Package Manager  
✅ **Auto-Detection**: Scripts automatically choose the best build method  
✅ **Complete App**: Full auto-clicker functionality with advanced features  
✅ **Professional Development**: Xcode integration for debugging and profiling

## Getting Started

1. Open the project in Xcode: `open ClickIt.xcodeproj`
2. Build and run with ⌘R, or use the scripts above
3. Grant accessibility permissions when prompted
4. Start auto-clicking with precision timing and window targeting

For more details, see the main project documentation in `/Users/jsonify/code/clickit/CLAUDE.md`.