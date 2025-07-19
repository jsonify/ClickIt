# ClickIt Build & Deploy Guide

This document describes the professional build and deployment system for ClickIt, with full GitHub integration and automated release workflows.

## 🎯 Quick Start

```bash
# Initial setup
make setup

# Local development
make local

# Beta release workflow
git checkout staging
git tag beta-v1.0.0-$(date +%Y%m%d) && git push origin --tags
make beta  # Creates GitHub release with app bundle

# Production release workflow  
git checkout main
git merge staging  # Bring in tested features
git tag v1.0.0 && git push origin --tags
make prod  # Creates GitHub release with app bundle
```

## 📋 Available Commands

### Development Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `make help` | Show all available commands | Getting started |
| `make setup` | Setup development environment | First time setup |
| `make build` | Quick development build | Testing code changes |
| `make test` | Run test suite | Before committing |
| `make lint` | Run SwiftLint checks | Code quality |
| `make clean` | Clean build artifacts | Troubleshooting |

### Release Commands

| Command | Description | Requirements | Output |
|---------|-------------|--------------|--------|
| `make local` | Build + test + sign for local use | Development certificate | `dist/ClickIt.app` |
| `make install` | Install to /Applications | Local testing | App in Applications |
| `make beta` | Create GitHub beta release | `staging` branch + `beta*` tag | GitHub pre-release + app bundle |
| `make prod` | Create GitHub production release | `main` branch + `v*` tag | GitHub latest release + app bundle |
| `make release` | Interactive release helper | Guide through options | Status and next steps |

### Fastlane Commands

| Command | Description | Equivalent |
|---------|-------------|------------|
| `fastlane local` | Build for local development | `make local` |
| `fastlane beta` | Create beta release | `make beta` |
| `fastlane prod` | Create production release | `make prod` |
| `fastlane build_release` | Build release version only | Build step of `make local` |

## 🏗️ Build Architecture

### Multi-Architecture Support
- **Intel x86_64** + **Apple Silicon arm64**
- **Universal binaries** created automatically
- **Optimized builds** for each architecture

### Build Modes
- **Debug**: Fast compilation, debugging symbols
- **Release**: Optimized, smaller binaries (default)

### Quality Gates
1. **Swift Build** - Compilation errors block progress
2. **Unit Tests** - All tests must pass
3. **SwiftLint** - Strict code quality enforcement
4. **Code Signing** - Proper certificate validation

## 🔄 CI/CD Pipeline

### Branch Strategy
- **`main`** → Production releases (`v*` tags)
- **`staging`** → Beta releases (`beta*` tags)  
- **`dev`** → Quality checks only (PRs)

### Automated Workflows

#### Quality Checks (All Branches)
- ✅ Swift build verification
- ✅ Unit test execution
- ✅ SwiftLint enforcement
- ✅ Multi-architecture compilation
- ✅ Code coverage reporting

#### Beta Releases (`staging` + `beta*` tag)
- ✅ **Validation**: Branch and tag pattern verification
- 🏗️ **Build**: Universal app bundle creation (Intel + Apple Silicon)
- 🧪 **Test**: Full test suite and SwiftLint validation
- 📦 **Package**: Automatic ClickIt.app.zip generation
- 🐙 **GitHub Release**: Pre-release with proper formatting
- 📝 **Release Notes**: Installation instructions and testing notes

#### Production Releases (`main` + `v*` tag)
- ✅ **Validation**: Branch and tag pattern verification  
- 🏗️ **Build**: Universal app bundle creation (Intel + Apple Silicon)
- 🧪 **Test**: Full test suite and SwiftLint validation
- 📦 **Package**: Automatic ClickIt.app.zip generation
- 🐙 **GitHub Release**: Latest release with professional presentation
- 📝 **Release Notes**: Feature highlights and installation guide
- 🔐 **Code Signing**: Automatic certificate validation

## 🏷️ Release Management

### Semantic Versioning
- **Major**: `v2.0.0` - Breaking changes
- **Minor**: `v1.1.0` - New features
- **Patch**: `v1.0.1` - Bug fixes

### Tag Patterns
```bash
# Production releases
v1.0.0, v1.1.0, v2.0.0

# Beta releases  
beta-v1.0.0-20250713, beta-v1.1.0-20250714

# Development (no automated releases)
dev-*, feature-*, fix-*
```

### Creating Releases

#### Complete Beta Release Workflow
```bash
# 1. Switch to staging and ensure it's current
git checkout staging
git pull origin staging

# 2. Create and push beta tag
git tag beta-v1.0.0-$(date +%Y%m%d)
git push origin --tags

# 3. Create GitHub release with app bundle
make beta
# ✅ Validates staging branch + beta tag
# 🏗️ Builds universal app bundle  
# 🐙 Creates GitHub pre-release
# 📦 Uploads ClickIt.app.zip automatically
```

#### Complete Production Release Workflow
```bash
# 1. Merge tested features from staging to main
git checkout main
git pull origin main
git merge staging
git push origin main

# 2. Create and push production tag
git tag v1.0.0
git push origin --tags

# 3. Create GitHub release with app bundle
make prod
# ✅ Validates main branch + v* tag
# 🏗️ Builds universal app bundle
# 🐙 Creates GitHub latest release
# 📦 Uploads ClickIt.app.zip automatically
# 📝 Professional release notes with features
```

#### Alternative: Fastlane Workflow
```bash
# Beta release (same validation)
fastlane beta

# Production release (same validation)  
fastlane prod
```

## 🔐 Code Signing

### Local Development
```bash
# Check available certificates
security find-identity -v -p codesigning

# Set certificate for session
export CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)"

# Build and sign
make local
```

### CI Environment
1. **Export certificate** as .p12 from Keychain Access
2. **Encode to base64**: `base64 -i certificate.p12 | pbcopy`
3. **Add GitHub Secrets**:
   - `CERTIFICATE_BASE64`: The base64 certificate
   - `CERTIFICATE_PASSWORD`: Certificate password
4. **CI automatically** sets up signing during builds

## 📁 Asset Management

### Local Builds
```
dist/
├── ClickIt.app/              # App bundle
├── binaries/
│   ├── ClickIt-x86_64       # Intel binary
│   ├── ClickIt-arm64        # Apple Silicon binary
│   └── ClickIt-universal    # Universal binary
└── build-info.txt           # Build metadata
```

### GitHub Release Assets

#### Beta Releases
```
📦 Assets (2):
├── ClickIt.app.zip          # Universal app bundle (972KB)
└── Source code (zip)        # Automatic GitHub archive
└── Source code (tar.gz)     # Automatic GitHub archive

🏷️ Release Type: Pre-release
📝 Release Notes: Testing instructions + installation guide
```

#### Production Releases  
```
📦 Assets (3):
├── ClickIt.app.zip          # Universal app bundle (972KB)
└── Source code (zip)        # Automatic GitHub archive  
└── Source code (tar.gz)     # Automatic GitHub archive

🏷️ Release Type: Latest release
📝 Release Notes: Full feature descriptions + professional presentation
```

## 🔍 Code Quality

### SwiftLint Configuration
- **140+ rules** with analyzer integration
- **Custom SwiftUI rules** for @State privacy
- **Strict mode** - warnings treated as errors
- **Fast feedback** - Ubuntu runner for quick checks

### Conventional Commits
```bash
# Setup (included in make setup)
./scripts/setup-git-hooks.sh

# Format
<type>(<scope>): <description>

# Examples
feat(ui): add dark mode toggle to settings
fix(permissions): resolve accessibility detection bug
docs: update installation instructions
```

## 🛠️ Fastlane Integration

### Available Lanes
```bash
# Build and development
fastlane build_debug        # Debug build
fastlane build_release      # Release build  
fastlane run                # Build debug + launch app
fastlane local              # Same as 'make local'

# Release workflows
fastlane beta               # Same as 'make beta' - GitHub release
fastlane prod               # Same as 'make prod' - GitHub release

# Utility lanes
fastlane clean              # Clean build artifacts
fastlane verify_signing     # Check code signing status
fastlane info               # Show app bundle information
fastlane release            # Full release workflow
fastlane dev                # Development workflow (build + run)
```

### Installation
```bash
# Install Fastlane
brew install fastlane

# Verify installation
fastlane --version
```

### Integration with Make
- **`make beta`** internally calls **`fastlane beta`**
- **`make prod`** internally calls **`fastlane prod`**  
- Both approaches provide identical functionality
- Choose based on your preference: Make (simple) or Fastlane (detailed)

## 🔧 Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean and rebuild
make clean
make build

# Check dependencies
swift package resolve
swift package update

# Verify architectures
./build_app_unified.sh debug
```

#### Release Issues
```bash
# Missing ClickIt.app.zip in GitHub release
# This indicates upload failure - re-run the command
make beta   # or make prod

# GitHub CLI not authenticated
gh auth login
gh auth status

# Tag/branch validation failures
git status              # Check current branch
git describe --tags     # Check current tag
make release           # Interactive guide
```

#### Code Signing Issues
```bash
# Check available certificates
security find-identity -v -p codesigning

# Set certificate environment variable
export CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)"

# Skip signing for testing
./scripts/skip-signing.sh

# Manual signing with validation
./scripts/sign-app.sh
```

#### SwiftLint Failures
```bash
# Check specific violations
swiftlint lint --strict

# Auto-fix where possible
swiftlint --fix

# Temporarily disable specific rules
# Add "# swiftlint:disable rule_name" to problematic lines
```

### Getting Help
```bash
make help           # Available commands with descriptions
make release        # Interactive release guide with status
fastlane --help     # Fastlane command reference
gh release --help   # GitHub CLI release help
git log --oneline   # Recent changes
```

### Verification Commands
```bash
# Verify release workflow is working
make release        # Shows current status and next steps

# Test local build pipeline
make local && open dist/ClickIt.app

# Check GitHub CLI authentication and permissions
gh auth status
gh release list --limit 5

# Validate current release setup
git status && git describe --tags 2>/dev/null || echo "No tag on current commit"
```

## ✅ Recently Implemented (July 2025)

### GitHub Integration Fixes
- **✅ App Bundle Upload**: Fixed missing ClickIt.app.zip in releases
- **✅ Release Notes Formatting**: Fixed broken line breaks in GitHub releases  
- **✅ Automated Workflows**: Complete beta and production release automation
- **✅ Professional Presentation**: Proper formatting and installation instructions

### Validated Workflows
- **✅ Beta Release**: `staging` branch → `beta-*` tag → `make beta` → GitHub pre-release
- **✅ Production Release**: `main` branch → `v*` tag → `make prod` → GitHub latest release
- **✅ Fastlane Integration**: All lanes working with proper GitHub integration

### Current Release Status
- **🔗 Latest Beta**: [beta-v1.0.0-20250718](https://github.com/jsonify/ClickIt/releases/tag/beta-v1.0.0-20250718)
- **🔗 Latest Production**: [v1.0.0](https://github.com/jsonify/ClickIt/releases/tag/v1.0.0)
- **📦 App Bundle Size**: ~972KB (Universal binary)
- **🔐 Code Signing**: Working with development certificates

## 🚀 Advanced Features

### Performance Optimizations
- **Parallel builds** for multiple architectures (Intel + Apple Silicon)
- **Universal binaries** automatically created
- **Build validation** with quality gates (build → test → lint → sign)
- **Incremental builds** for faster development iteration

### GitHub Integration
- **Automatic release creation** with proper formatting
- **Asset management** with automatic app bundle uploads
- **Pre-release vs Latest** release type handling
- **Rich release notes** with installation instructions and feature highlights

### Developer Experience
- **Interactive release guide** via `make release`
- **Comprehensive validation** prevents common mistakes
- **Rich terminal output** with colors and progress indicators
- **Dual workflow support** (Make + Fastlane) for different preferences

## 📈 Metrics & Monitoring

### Build Performance
- **Local builds**: ~30-60 seconds
- **CI builds**: ~5-10 minutes
- **Release creation**: ~10-15 minutes

### Quality Metrics
- **Test Coverage**: Tracked via CodeCov
- **Lint Compliance**: 100% strict enforcement
- **Build Success Rate**: Monitored via GitHub Actions

## 🔮 Future Enhancements

### Planned Features
- [ ] **Notarization** for external distribution
- [ ] **App Store Connect** integration
- [ ] **Semantic Release** plugin for automatic versioning
- [ ] **Custom DMG styling** with app icons
- [ ] **Crashlytics** integration for error tracking
- [ ] **Performance profiling** in CI

### Integration Opportunities
- [ ] **Slack notifications** for releases
- [ ] **Jira integration** for issue tracking
- [ ] **SonarQube** for advanced code analysis
- [ ] **TestFlight** distribution for beta testing

---

**Built with ❤️ using Claude Code** | **Inspired by enterprise macOS development practices**