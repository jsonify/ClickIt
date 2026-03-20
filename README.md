# ClickIt

[![CI - Build & Test](https://github.com/jsonify/ClickIt/actions/workflows/ci.yml/badge.svg)](https://github.com/jsonify/ClickIt/actions/workflows/ci.yml)
[![Release](https://github.com/jsonify/ClickIt/actions/workflows/release.yml/badge.svg)](https://github.com/jsonify/ClickIt/actions/workflows/release.yml)
[![Latest Release](https://img.shields.io/github/v/release/jsonify/ClickIt)](https://github.com/jsonify/ClickIt/releases/latest)

**Professional macOS Auto-Clicker with Enterprise-Grade Precision**

A native macOS automation tool built with SwiftUI that delivers sub-10ms timing accuracy and advanced window targeting. Perfect for gamers, QA testers, automation professionals, and power users who demand reliable, feature-rich clicking automation.

## 🌟 Key Highlights

**Unlike other auto-clickers, ClickIt offers:**

1. **True Native Performance** - Built specifically for macOS with SwiftUI, not a cross-platform port
2. **Advanced Window Targeting** - Click on specific apps even when they're minimized or in background
3. **Sub-10ms Precision** - Professional-grade timing accuracy that competitors can't match
4. **Apple Silicon Native** - Built and optimized for Apple Silicon (M1/M2/M3/M4)
5. **Enterprise Features** - Timer automation, preset management, and performance analytics
6. **Zero Telemetry** - Your automation stays completely private and offline

## Why Choose ClickIt?

- ⚡ **Lightning Fast** - Sub-10ms click timing accuracy with precision interval control
- 🎯 **Smart Targeting** - Advanced window detection that works even when apps are minimized
- 🌐 **Apple Silicon Native** - Optimized for Apple Silicon (M1/M2/M3/M4)
- 🎮 **Always Active** - Background operation without requiring app focus or interruption
- ⌨️ **Global Control** - System-wide hotkey support (ESC key) for instant start/stop
- 💾 **Preset System** - Save and instantly load custom clicking configurations
- 👁️ **Visual Feedback** - Clear overlay indicators show exactly where clicks will occur
- 🔒 **Permission Aware** - Streamlined permission setup with real-time monitoring
- 📊 **Performance Stats** - Built-in analytics and monitoring dashboard

## Core Features

### 🎯 Advanced Click Automation
- **Sub-10ms Precision** - Industry-leading timing accuracy for demanding automation tasks
- **Window-Specific Targeting** - Click on specific applications, even when minimized or in background
- **Multiple Click Modes** - Single clicks, double clicks, and hold/release patterns
- **Coordinate Lock** - Pin clicks to exact screen coordinates or dynamic window positions
- **Human-like Variation** - Optional randomization to mimic natural clicking patterns

### ⚙️ Intelligent Configuration
- **Preset Management** - Save unlimited custom configurations and switch instantly
- **Timer Automation** - Schedule automatic start/stop times for unattended operation
- **Interval Control** - Millisecond-level precision with CPS (Clicks Per Second) display
- **Hotkey System** - Global ESC key control that works from any application
- **Auto-Save States** - Automatically preserves your settings between sessions

### 📊 Professional Tools
- **Real-Time Performance Dashboard** - Monitor click rate, accuracy, and system performance
- **Statistics Tracking** - View elapsed time, total clicks, and success rates
- **Permission Monitoring** - Live status display for Accessibility and Screen Recording permissions
- **Visual Feedback System** - Customizable overlay indicators show target locations
- **Smart Status Bar** - Always-visible controls with compact, unobtrusive design

### 🔒 Security & Reliability
- **Permission-First Design** - Streamlined permission request flow with detailed instructions
- **Automatic Permission Detection** - Real-time monitoring of required system permissions
- **Safe Operation Mode** - Prevents accidental system-wide clicks during setup
- **Crash Recovery** - Robust error handling ensures stable operation
- **Privacy Focused** - No data collection, no analytics, completely offline operation

## Who Uses ClickIt?

### 🎮 Gamers
- **Idle/Clicker Games** - Automate repetitive clicking in incremental games
- **MMO Grinding** - Streamline repetitive tasks in online games
- **Farming Simulators** - Automate resource collection and harvesting
- **Achievement Hunting** - Complete click-intensive achievements efficiently

### 🧪 QA & Testing Professionals
- **UI/UX Testing** - Simulate user interactions for interface testing
- **Load Testing** - Generate consistent user input patterns
- **Regression Testing** - Automate repetitive test scenarios
- **Browser Testing** - Click through web application workflows

### 💼 Business & Productivity
- **Data Entry** - Automate repetitive form filling and data input
- **Batch Processing** - Handle large volumes of similar tasks
- **Presentation Auto-Advance** - Automatic slideshow progression
- **Monitoring Systems** - Keep applications active and responsive

### ♿ Accessibility & Ergonomics
- **Mobility Assistance** - Reduce physical strain for users with limited mobility
- **Repetitive Strain Prevention** - Minimize manual clicking to prevent RSI
- **Adaptive Computing** - Enable custom interaction patterns for accessibility needs
- **Fatigue Reduction** - Automate long-duration clicking tasks

## System Requirements

### Minimum Requirements
- **Operating System**: macOS 15.0 (Sequoia) or later
- **Processor**: Apple Silicon (M1/M2/M3/M4)
- **Memory**: 50 MB RAM
- **Storage**: 10 MB available disk space
- **Permissions**:
  - Accessibility (required for click simulation)
  - Screen Recording (required for window targeting)

### Recommended
- **Operating System**: Latest macOS version for optimal performance
- **Processor**: Apple Silicon for best energy efficiency
- **Display**: Any resolution supported (tested on 1080p - 5K displays)

## Installation

### Download & Install
1. Download the latest `.dmg` from the [Releases page](https://github.com/jsonify/ClickIt/releases/latest)
2. Open the DMG and drag `ClickIt.app` to your `/Applications` folder

### macOS Security Warning (Required Step)

Because ClickIt is not signed with an Apple Developer certificate, macOS will block it with a **"damaged and can't be opened"** message. This is a Gatekeeper false positive — the app is safe.

**Fix it with one command in Terminal:**

```bash
xattr -cr /Applications/ClickIt.app
```

Then double-click the app normally. You only need to do this once.

> **Alternative:** Right-click (or Control-click) the app and choose **Open**. macOS will show an "Open Anyway" button on the warning dialog. After opening once this way, you can double-click normally going forward.
>
> Or go to **System Settings → Privacy & Security** and click **"Open Anyway"** after your first blocked launch attempt.

### First Launch Setup
1. **Launch ClickIt** - Double-click the app from Applications
2. **Grant Permissions** - The app will guide you through:
   - ✅ **Accessibility Permission** - Required for click automation
   - ✅ **Screen Recording Permission** - Required for window targeting
3. **Start Automating** - Configure your first preset and start clicking!

### Troubleshooting Installation
If permissions aren't working after granting them:
- Click "Refresh Status" in the permission gate screen
- Restart the application
- Check System Settings → Privacy & Security to verify permissions are enabled

## 🚀 Quick Start Guide

### Basic Workflow
1. **Select Target** - Choose "Current Mouse Position" or select a specific window
2. **Set Timing** - Configure click interval (supports milliseconds or CPS)
3. **Start/Stop** - Press ESC key or use the in-app controls
4. **Monitor** - View real-time statistics and performance metrics

### Pro Tips
- **Save Presets** - Create configurations for different games or applications
- **Use Window Targeting** - Target specific apps to avoid accidental clicks
- **Enable Visual Feedback** - See exactly where clicks will occur
- **Timer Automation** - Schedule unattended clicking sessions
- **Performance Dashboard** - Monitor click accuracy and system impact

### Common Workflows

**Gaming Setup:**
```
1. Launch your game
2. Select game window as target
3. Set desired CPS (clicks per second)
4. Position mouse on target location
5. Press ESC to start/stop
```

**Testing Automation:**
```
1. Create preset for test scenario
2. Configure click sequence with precise timing
3. Enable visual feedback for verification
4. Use timer automation for repeated tests
```

**Productivity Tasks:**
```
1. Target specific application window
2. Set conservative click interval
3. Use preset for quick configuration switching
4. Monitor performance dashboard
```

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
# Create app bundle (Apple Silicon / arm64)
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

### Architecture Support
ClickIt targets Apple Silicon (arm64) exclusively:
- **Apple Silicon**: `arm64-apple-macosx` (M1/M2/M3/M4)

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

#### **Production Release (Automatic)**

Patch releases are **fully automatic**. Simply merge your feature branch into `main`:

```
merge PR → main
    ↓
auto-release.yml fires
    ↓
patch version bumped (e.g. 1.5.5 → 1.5.6)
Info.plist updated, committed [skip ci]
v1.5.6 tag pushed
    ↓
cicd.yml triggers → builds, signs, creates GitHub release
```

No manual steps required. The workflow (`auto-release.yml`) handles everything.

**For major or minor bumps** (not automatic — do these manually):
```bash
# Get the latest tag, then create the next tag manually
git tag v2.0.0 && git push origin v2.0.0   # major bump
git tag v1.6.0 && git push origin v1.6.0   # minor bump
# cicd.yml picks up the tag and runs the full release pipeline
```

**Setup requirement:** Add a Personal Access Token with `repo` scope as a
repository secret named `RELEASE_TOKEN` (Settings → Secrets → Actions).
Without it, the workflow falls back to `GITHUB_TOKEN` and the tag push
will NOT trigger `cicd.yml`.

### 📚 **Additional Documentation**
- **[CLAUDE.md](CLAUDE.md)** - Development guidance and project overview
- **[BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md)** - Manual build and deployment instructions
- **[CERTIFICATE_SETUP.md](CERTIFICATE_SETUP.md)** - Code signing certificate setup
- **[docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md)** - Automated release process with Release Please

## 🤝 Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, improving documentation, or helping with translations, your help is appreciated.

### How to Contribute

1. **Check Existing Issues** - Browse the [Issues](https://github.com/jsonify/ClickIt/issues) tab for tasks that need help
2. **Fork & Branch** - Create a feature branch from `main` following our [Git Workflow Guide](docs/git-workflow-guide.md)
3. **Make Changes** - Write clean, well-documented code following our style guidelines
4. **Test Thoroughly** - Ensure your changes work on Apple Silicon
5. **Submit PR** - Use [Conventional Commits](https://www.conventionalcommits.org/) format for commit messages

### Areas We Need Help With
- 🐛 **Bug Reports** - Found an issue? Report it with detailed steps to reproduce
- ✨ **Feature Requests** - Have ideas for improvements? Open a feature request
- 📝 **Documentation** - Help improve guides, tutorials, and code comments
- 🌍 **Localization** - Translate ClickIt to other languages
- 🧪 **Testing** - Test on different macOS versions and hardware configurations

### Development Setup
See the [Development](#development) section below for setup instructions and our comprehensive [Git Workflow Guide](docs/git-workflow-guide.md).

## 🗺️ Roadmap

ClickIt is under active development. Here's what's coming:

### In Progress
- ⏳ **UI Optimization** - Tabbed interface with improved space utilization (v2.0)
- ⏳ **Timer Automation** - Schedule automatic start/stop times
- ⏳ **Performance Dashboard** - Real-time analytics and monitoring

### Planned Features
- 🔄 **Click Recording** - Record and replay complex click sequences
- 🎯 **Multi-Point Patterns** - Click multiple locations in sequence
- 🎨 **Custom Themes** - Dark/light mode and custom color schemes
- 🌍 **Localization** - Multi-language support
- 📊 **Advanced Analytics** - Export statistics and performance reports
- ⌨️ **Custom Hotkeys** - Configure your own keyboard shortcuts
- 🔌 **AppleScript Support** - Integrate with system automation

Want to see a feature added? [Open a feature request](https://github.com/jsonify/ClickIt/issues/new)!

## 💬 Support & Community

### Getting Help
- 📖 **Documentation** - Check the docs in the `/docs` folder
- 🐛 **Bug Reports** - [Open an issue](https://github.com/jsonify/ClickIt/issues/new) with detailed information
- 💡 **Feature Requests** - Share your ideas in the Issues tab
- 🤔 **Questions** - Ask in GitHub Discussions or open an issue

### Reporting Issues
When reporting bugs, please include:
- macOS version and Apple Silicon chip (M1/M2/M3/M4)
- ClickIt version number
- Steps to reproduce the issue
- Expected vs. actual behavior
- Relevant error messages or logs

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## ⚖️ Disclaimer

ClickIt is intended for **legitimate automation purposes only**. Users are responsible for ensuring their use complies with:
- Terms of service of applications they interact with
- Applicable local, state, and federal laws
- Gaming platform policies and fair play guidelines
- Workplace automation policies

**Use responsibly and ethically.** The developers of ClickIt are not responsible for misuse of this software.
