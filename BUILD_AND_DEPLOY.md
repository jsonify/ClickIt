# ClickIt Build & Deploy Guide

This document describes the professional build and deployment system for ClickIt, inspired by enterprise-grade practices and adapted for Swift Package Manager.

## 🎯 Quick Start

```bash
# Initial setup
make setup

# Local development
make local

# Create releases (with proper git tags)
git tag v1.0.0 && git push origin --tags  # Production
git tag beta-v1.0.0-20250713 && git push origin --tags  # Beta
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

| Command | Description | Requirements |
|---------|-------------|--------------|
| `make local` | Build + test + sign for local use | Development certificate |
| `make install` | Install to /Applications | Local testing |
| `make beta` | Create beta release | `staging` branch + `beta*` tag |
| `make prod` | Create production release | `main` branch + `v*` tag |
| `make release` | Interactive release helper | Guide through options |

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
- 🚀 Automated app bundle creation
- 📦 ZIP asset generation
- 🐙 GitHub release with prerelease flag
- 📝 Automatic changelog from commits

#### Production Releases (`main` + `v*` tag)
- 🚀 Automated app bundle creation
- 📦 ZIP + DMG asset generation
- 🐙 GitHub release (stable)
- 📝 Professional changelog
- 🔐 Full code signing pipeline

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

#### Manual Process
```bash
# Beta release
git checkout staging
git tag beta-v1.0.0-$(date +%Y%m%d)
git push origin --tags

# Production release
git checkout main
git tag v1.0.0
git push origin --tags
```

#### With Git Aliases (after `make setup`)
```bash
git release-beta 1.0.0   # Creates beta-v1.0.0-YYYYMMDD
git release-prod 1.0.0   # Creates v1.0.0
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

### Release Assets
```
# Beta releases
ClickIt-1.0.0-beta-abc123.zip

# Production releases  
ClickIt-1.0.0.zip
ClickIt-1.0.0.dmg
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
# Via Fastlane directly
bundle exec fastlane mac local       # Local build
bundle exec fastlane mac beta        # Beta release
bundle exec fastlane mac production  # Production release

# Via Makefile (recommended)
make local  # Runs fastlane mac local
make beta   # Runs fastlane mac beta  
make prod   # Runs fastlane mac production
```

### Ruby Dependencies
```bash
# Install
bundle install

# Update
bundle update
```

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
```

#### Code Signing Issues
```bash
# Check certificates
security find-identity -v -p codesigning

# Reset signing
./scripts/skip-signing.sh  # Skip signing temporarily
./scripts/sign-app.sh      # Manual signing
```

#### SwiftLint Failures
```bash
# Check rules
swiftlint lint

# Auto-fix (when possible)
swiftlint --fix

# Temporarily disable
# Add "# swiftlint:disable rule_name" to file
```

### Getting Help
```bash
make help           # Available commands
make release        # Interactive guide
git log --oneline   # Recent changes
```

## 🚀 Advanced Features

### Performance Optimizations
- **Parallel builds** for multiple architectures
- **Cached dependencies** in CI
- **Incremental builds** for faster iteration

### Security Features
- **Automatic keychain management** in CI
- **Certificate validation** before signing
- **Secure environment variable** handling

### Developer Experience
- **Pre-commit hooks** prevent bad commits
- **Commit templates** guide proper formatting
- **Rich terminal output** with colors and emojis
- **Interactive guides** for complex operations

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