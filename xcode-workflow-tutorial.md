# 🍎 Xcode Development & Release Workflow Tutorial

**Complete guide to developing and releasing ClickIt using Xcode with automated CI/CD**

---

## 📋 Overview

This tutorial covers the complete workflow for developing and releasing ClickIt using **Xcode as the primary development environment** with **automated GitHub Actions CI/CD** for releases. No more manual build scripts or command-line complexity!

### 🎯 What You'll Learn
- Setting up Xcode for ClickIt development
- Using the automated CI/CD pipeline for releases  
- Best practices for version management
- Troubleshooting common issues

---

## 🚀 Quick Start

### **For Releases** (30 seconds)
```bash
git tag v1.3.0
git push origin v1.3.0
# ✅ Done! GitHub Actions handles the rest
```

### **For Development** (2 minutes)
1. Open `ClickIt.xcodeproj` in Xcode
2. Make your changes
3. Build & test with ⌘+R
4. Commit & push when ready

---

## 🛠️ Development Workflow

### **Step 1: Open Project in Xcode**

```bash
# Navigate to project directory
cd /path/to/clickit

# Open in Xcode
open ClickIt.xcodeproj
```

**Alternative**: Use Finder → double-click `ClickIt.xcodeproj`

### **Step 2: Xcode Project Structure**

Your Xcode project includes:
```
ClickIt.xcodeproj/
├── ClickIt (Target)
│   ├── Sources/ClickIt/          # Main app code
│   │   ├── UI/                   # SwiftUI views & components
│   │   ├── Core/                 # Business logic
│   │   └── Utils/                # Utilities & constants
│   ├── Tests/                    # Unit tests
│   └── Resources/                # Assets, Info.plist
├── Package Dependencies          # SPM dependencies (Sparkle, etc.)
└── Products/                     # Built app
```

### **Step 3: Development Cycle**

#### **🔄 Daily Development**
1. **Open Xcode**: `open ClickIt.xcodeproj`
2. **Select Target**: Ensure "ClickIt" target is selected
3. **Choose Destination**: "My Mac" for local development
4. **Build & Run**: Press ⌘+R or click ▶️ Play button
5. **Test Changes**: Use the app, verify functionality
6. **Debug**: Use Xcode's debugger, breakpoints, console

#### **🧪 Testing**
```bash
# Run unit tests in Xcode
⌘+U (Test menu → Test)

# Or use command line for automated testing
swift test
```

#### **📝 Code Changes**
- **UI Changes**: Edit SwiftUI files in `Sources/ClickIt/UI/`
- **Logic Changes**: Modify files in `Sources/ClickIt/Core/`
- **Dependencies**: Use Xcode's Package Manager integration

### **Step 4: Building for Distribution**

#### **Option A: Automated Build (Recommended)**
Your changes will be automatically built by CI/CD when you create releases.

#### **Option B: Manual Build for Testing**
```bash
# Build release version with Xcode
./build_app_unified.sh release xcode

# App will be created at: dist/ClickIt.app
open dist/ClickIt.app
```

---

## 🚀 Automated Release Process

### **Overview: Tag → Auto-Release**

The new CI/CD system makes releases **completely automated**:

```mermaid
graph LR
    A[Create Version Tag] --> B[Push to GitHub]
    B --> C[GitHub Actions Triggered]
    C --> D[Xcode Build on macOS Runner]
    D --> E[Universal Binary Created]
    E --> F[Release Notes Generated]
    F --> G[GitHub Release Published]
    G --> H[Assets Uploaded]
```

### **Step-by-Step Release Process**

#### **1. Prepare Your Release**

**Ensure your code is ready:**
```bash
# Make sure you're on main branch
git checkout main
git pull origin main

# Verify no uncommitted changes
git status

# Optional: Run local tests
swift test
```

#### **2. Create a Version Tag**

**Choose your version number** using [Semantic Versioning](https://semver.org/):
- `v1.3.0` - New features (minor release)
- `v1.2.1` - Bug fixes (patch release)  
- `v2.0.0` - Breaking changes (major release)

```bash
# Create version tag
git tag v1.3.0

# Add annotated tag with message (optional but recommended)
git tag -a v1.3.0 -m "Release v1.3.0: Add new timer features and UI improvements"
```

#### **3. Push the Tag**

```bash
# Push tag to trigger release
git push origin v1.3.0
```

**🎉 That's it!** GitHub Actions will now:
- Build the app with Xcode on a macOS runner
- Create universal binary (Intel + Apple Silicon)
- Generate professional release notes
- Create GitHub release
- Upload `ClickIt.app.zip` and build metadata

#### **4. Monitor the Release**

**Track progress:**
1. Go to your GitHub repository
2. Click **"Actions"** tab
3. Watch the **"🚀 Build and Release ClickIt"** workflow
4. Release will appear in **"Releases"** section when complete

**Timeline:** Typically completes in 5-10 minutes.

### **🎨 Release Notes (Auto-Generated)**

The CI/CD system automatically creates professional release notes including:

```markdown
# ClickIt v1.3.0

🎉 **Native macOS Auto-Clicker Application**

## ✨ Features
- 🖱️ **Precision Clicking**: Sub-10ms timing accuracy
- 🌐 **Universal Binary**: Native support for Intel x64 + Apple Silicon
- 🎯 **Background Operation**: Works without requiring app focus
- ⚡ **Global Hotkeys**: ESC key controls for instant stop
- 🔧 **Advanced Configuration**: CPS rates, click types, and presets

## 📈 Changes Since v1.2.0
- feat: Add new timer configuration options
- fix: Resolve permission dialog issues  
- ui: Improve visual feedback system

---
🏗️ **Built with**: Xcode on GitHub Actions
📅 **Build Date**: 2025-01-15 14:30:22 UTC
```

---

## 🔧 Advanced Workflows

### **Development Branches**

#### **Feature Development**
```bash
# Create feature branch
git checkout -b feature/new-timer-controls
# ... make changes in Xcode ...
git commit -am "Add new timer controls"
git push origin feature/new-timer-controls

# Create pull request on GitHub
# CI will automatically test your branch
```

#### **Beta Testing**
```bash
# Create beta release
git checkout develop  # or staging branch
git tag v1.3.0-beta1
git push origin v1.3.0-beta1

# GitHub Actions will create a pre-release
```

### **Hotfix Process**
```bash
# For urgent fixes
git checkout main
git checkout -b hotfix/critical-bug-fix
# ... fix in Xcode ...
git commit -am "Fix critical clicking bug"
git push origin hotfix/critical-bug-fix

# After PR merge:
git tag v1.2.2
git push origin v1.2.2  # Auto-release
```

### **Manual Release Trigger**

You can also manually trigger releases via GitHub:

1. Go to **Actions** tab in your repository
2. Select **"🚀 Build and Release ClickIt"** workflow
3. Click **"Run workflow"**
4. Enter tag name (e.g., `v1.3.0`)
5. Click **"Run workflow"**

---

## 📊 Monitoring & Quality Assurance

### **CI/CD Pipeline Overview**

Every push and pull request triggers **automated quality checks**:

#### **CI Workflow Features**
- ✅ **Matrix Testing**: Tests both Xcode and SPM builds
- ✅ **Multiple Configurations**: Debug and Release modes
- ✅ **Code Quality**: SwiftLint integration
- ✅ **Security Scanning**: Basic secret detection
- ✅ **Build Artifacts**: Saves builds for download

#### **Viewing CI Results**
1. **GitHub Repository** → **Actions** tab
2. **Click on workflow run** to see detailed logs
3. **Check status badges** in README.md

### **Status Badges**

Your README now includes live status indicators:
- ![CI Badge](https://github.com/jsonify/ClickIt/actions/workflows/ci.yml/badge.svg) - Build & test status
- ![Release Badge](https://github.com/jsonify/ClickIt/actions/workflows/release.yml/badge.svg) - Release workflow status
- ![Version Badge](https://img.shields.io/github/v/release/jsonify/ClickIt) - Latest version

---

## 🛠️ Troubleshooting

### **Common Issues & Solutions**

#### **🔴 "Xcode project not found" Error**
```bash
# Ensure you're in the correct directory
pwd
# Should show: /path/to/clickit

# Verify Xcode project exists
ls -la ClickIt.xcodeproj/
```

#### **🔴 Build Fails with Code Signing Issues**
```bash
# Check available certificates
security find-identity -v -p codesigning

# Build script automatically uses best available certificate
# For development, self-signed certificates are fine
```

#### **🔴 GitHub Actions Workflow Doesn't Trigger**
```bash
# Ensure tag follows correct format
git tag v1.3.0  # ✅ Correct
git tag 1.3.0   # ❌ Missing 'v' prefix

# Verify tag was pushed
git ls-remote --tags origin
```

#### **🔴 Release Fails to Build**
**Check GitHub Actions logs:**
1. Go to **Actions** tab
2. Click failed workflow
3. Check **"🔨 Build Universal App with Xcode"** step
4. Common fixes:
   - Update Xcode version in workflow
   - Fix any new SwiftLint errors
   - Verify Xcode project integrity

#### **🔴 App Won't Launch After Build**
```bash
# Check app bundle structure
ls -la dist/ClickIt.app/Contents/

# Verify executable exists and has correct permissions
ls -la dist/ClickIt.app/Contents/MacOS/ClickIt
file dist/ClickIt.app/Contents/MacOS/ClickIt

# Check code signing
codesign -dv dist/ClickIt.app
```

### **Debug Build Issues**

#### **Enable Verbose Logging**
```bash
# Build with detailed output
./build_app_unified.sh release xcode 2>&1 | tee build.log

# Check build log
cat build.log
```

#### **Xcode Build from Command Line**
```bash
# Direct Xcode build for debugging
xcodebuild -project ClickIt.xcodeproj -scheme ClickIt -configuration Release build

# Show build settings
xcodebuild -project ClickIt.xcodeproj -scheme ClickIt -configuration Release -showBuildSettings
```

---

## 💡 Best Practices

### **Version Management**

#### **Semantic Versioning Guidelines**
- **Major (v2.0.0)**: Breaking changes, major rewrites
- **Minor (v1.3.0)**: New features, enhancements
- **Patch (v1.2.1)**: Bug fixes, small improvements

#### **Pre-release Versions**
```bash
# Beta releases
git tag v1.3.0-beta1
git tag v1.3.0-beta2

# Release candidates  
git tag v1.3.0-rc1

# Final release
git tag v1.3.0
```

### **Development Best Practices**

#### **Code Quality**
- **Use Xcode's built-in SwiftLint integration**
- **Write unit tests for critical functionality**
- **Use meaningful commit messages**
- **Test on multiple macOS versions when possible**

#### **Testing Strategy**
```bash
# Local testing before commits
swift test                    # Unit tests
./build_app_unified.sh debug  # Build verification
open dist/ClickIt.app         # Manual testing
```

#### **Commit Message Conventions**
```bash
git commit -m "feat: Add new timer configuration panel"
git commit -m "fix: Resolve clicking accuracy issue"  
git commit -m "docs: Update API documentation"
git commit -m "refactor: Improve code organization"
```

### **Release Strategy**

#### **Release Frequency**
- **Patch releases**: As needed for bugs (1-2 weeks)
- **Minor releases**: Monthly or bi-monthly  
- **Major releases**: Quarterly or when significant changes accumulate

#### **Release Checklist**
- [ ] All tests passing locally
- [ ] No critical bugs reported
- [ ] Release notes prepared (auto-generated, but review)
- [ ] Version number follows semantic versioning
- [ ] Tag created and pushed

---

## 🚦 Workflow Comparison

### **Before: Manual Process**
```bash
# Old workflow (manual, error-prone)
make clean
make prod                    # Often failed due to lint issues
./build_app.sh              # Different from development
# Manual GitHub release creation
# Manual asset uploads
# Manual release notes
```

### **After: Automated Xcode Workflow**
```bash
# New workflow (automated, reliable)
git tag v1.3.0
git push origin v1.3.0
# ✅ Everything else is automatic!
```

### **Benefits Summary**
- ✅ **Consistency**: Same Xcode build everywhere
- ✅ **Reliability**: Tested CI/CD pipeline
- ✅ **Speed**: 30 seconds to trigger release
- ✅ **Quality**: Automated testing and validation
- ✅ **Professional**: Auto-generated release notes
- ✅ **Maintainable**: Standard GitHub Actions patterns

---

## 📚 Additional Resources

### **Documentation**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Build System Guide](https://developer.apple.com/documentation/xcode)
- [Swift Package Manager](https://swift.org/package-manager/)
- [Semantic Versioning](https://semver.org/)

### **Project Files**
- **CI/CD Workflows**: `.github/workflows/`
- **Build Script**: `build_app_unified.sh`
- **Xcode Project**: `ClickIt.xcodeproj`
- **Package Definition**: `Package.swift`

### **Getting Help**
- **GitHub Issues**: Report bugs or request features
- **GitHub Discussions**: Community support
- **GitHub Actions Logs**: Detailed build information

---

## 🎉 Conclusion

You now have a **professional, automated development and release workflow** using Xcode as your primary development environment. The CI/CD pipeline handles all the complexity of building, testing, and releasing your app.

### **Key Takeaways**
1. **Development**: Use Xcode for all development work
2. **Releases**: Just create and push version tags
3. **Quality**: Automated testing ensures reliability
4. **Monitoring**: GitHub Actions provides full visibility

**Happy coding!** 🚀