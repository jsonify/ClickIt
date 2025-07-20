# ClickIt Git Workflow Guide

Complete step-by-step git workflow for ClickIt development, from feature development to production release.

## Table of Contents
- [Overview](#overview)
- [Branch Strategy](#branch-strategy)
- [Feature Development Workflow](#feature-development-workflow)
- [Beta Release Workflow](#beta-release-workflow)
- [Production Release Workflow](#production-release-workflow)
- [Hotfix Workflow](#hotfix-workflow)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)

## Overview

ClickIt uses a **GitFlow-inspired** workflow with automated releases through Fastlane:

```
main (production)     ----*----*----*----*----
                           \    \    \    \
staging (beta)        ------*----*----*----*--
                            \    \    \
feature branches      -------*----*----*------
```

## Branch Strategy

### **`main` Branch**
- **Purpose**: Production-ready code
- **Protection**: No direct commits, only merges from staging
- **Releases**: Production releases with `v*` tags (e.g., `v1.2.0`)
- **Automation**: `fastlane auto_prod` or `fastlane bump_and_release`

### **`staging` Branch**  
- **Purpose**: Integration testing and beta releases
- **Source**: Merges from feature branches
- **Releases**: Beta releases with `beta-*` tags (e.g., `beta-v1.2.0-202507201200`)
- **Automation**: `fastlane auto_beta`

### **Feature Branches**
- **Purpose**: Individual feature development
- **Naming**: `feature/description` or `issue-X-description`
- **Source**: Branched from latest `main`
- **Target**: Merged to `staging` for testing

## Feature Development Workflow

### Step 1: Start New Feature
```bash
# Start from latest main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/click-precision-improvements
# or
git checkout -b issue-15-visual-feedback-system
```

### Step 2: Develop Feature
```bash
# Make your changes
# Edit files, add features, fix bugs...

# Test locally
fastlane dev  # Build and test

# Commit changes
git add .
git commit -m "feat: implement click precision improvements

- Add sub-millisecond timing accuracy
- Improve coordinate targeting system
- Add precision testing tools"
```

### Step 3: Prepare for Integration
```bash
# Make sure you have latest changes
git checkout main
git pull origin main

# Rebase feature branch (optional but recommended)
git checkout feature/click-precision-improvements
git rebase main

# Push feature branch
git push origin feature/click-precision-improvements
```

### Step 4: Merge to Staging for Testing
```bash
# Switch to staging
git checkout staging
git pull origin staging

# Merge feature
git merge feature/click-precision-improvements

# Push staging
git push origin staging

# Clean up feature branch (optional)
git branch -d feature/click-precision-improvements
git push origin --delete feature/click-precision-improvements
```

## Beta Release Workflow

### When to Create Beta Release
- After merging new features to staging
- Before promoting to production
- For testing by beta users

### Step 1: Ensure Staging is Ready
```bash
# Switch to staging
git checkout staging
git pull origin staging

# Verify everything is committed
git status
# Should show "working tree clean"

# Optional: Test build locally
fastlane build_release
fastlane info
```

### Step 2: Create Automated Beta Release
```bash
# One command beta release with auto-tagging
fastlane auto_beta

# Or specify custom version
fastlane auto_beta version:2.1.0
```

**What this does:**
1. ✅ Validates you're on staging branch
2. ✅ Checks for uncommitted changes
3. ✅ Creates `beta-v{version}-{timestamp}` tag automatically
4. ✅ Pushes tag to GitHub
5. ✅ Builds universal app bundle
6. ✅ Creates GitHub pre-release
7. ✅ Uploads `ClickIt.app.zip` as downloadable asset

### Step 3: Test Beta Release
```bash
# Download from GitHub releases and test
# Share with beta testers
# Collect feedback
```

## Production Release Workflow

### When to Promote to Production
- After successful beta testing
- When staging is stable and ready
- Following your release schedule

### Step 1: Merge Staging to Main
```bash
# Switch to main
git checkout main
git pull origin main

# Merge staging (this brings in all tested features)
git merge staging

# Push main
git push origin main
```

### Step 2: Create Production Release

#### Option A: Automatic Version Bumping (Recommended)
```bash
# Smart version detection and bumping
fastlane bump_and_release                # Patch: 1.0.0 → 1.0.1
fastlane bump_and_release bump:minor     # Minor: 1.0.1 → 1.1.0  
fastlane bump_and_release bump:major     # Major: 1.1.0 → 2.0.0

# Skip confirmation prompt for CI/CD
fastlane bump_and_release bump:minor force:true
```

#### Option B: Manual Version
```bash
fastlane auto_prod version:1.2.0
```

**What this does:**
1. ✅ Validates you're on main branch
2. ✅ Checks for uncommitted changes
3. ✅ Creates `v{version}` tag automatically
4. ✅ Prevents duplicate tags
5. ✅ Pushes tag to GitHub
6. ✅ Builds universal app bundle
7. ✅ Creates GitHub release (marked as "latest")
8. ✅ Uploads `ClickIt.app.zip` as downloadable asset

### Step 3: Update Staging (Optional)
```bash
# Keep staging in sync with main after release
git checkout staging
git merge main
git push origin staging
```

## Hotfix Workflow

For urgent production fixes:

### Step 1: Create Hotfix Branch
```bash
# Start from main (production)
git checkout main
git pull origin main

# Create hotfix branch
git checkout -b hotfix/critical-crash-fix
```

### Step 2: Fix and Test
```bash
# Make the fix
# Edit files...

# Test locally
fastlane dev

# Commit fix
git add .
git commit -m "fix: resolve critical crash in window detection

- Handle null window references gracefully
- Add defensive checks in WindowTargeter
- Fixes issue #45"
```

### Step 3: Deploy Hotfix
```bash
# Merge to main
git checkout main
git merge hotfix/critical-crash-fix
git push origin main

# Create emergency release
fastlane bump_and_release bump:patch force:true

# Merge back to staging
git checkout staging
git merge main
git push origin staging

# Clean up
git branch -d hotfix/critical-crash-fix
```

## Common Scenarios

### Scenario 1: Old Staging Branch
**Question**: "What if staging is behind main?"

**Solution**:
```bash
# Update staging with latest main
git checkout staging
git pull origin staging
git merge main
git push origin staging

# Now staging is up to date, proceed with beta release
fastlane auto_beta
```

### Scenario 2: Multiple Features Ready
**Question**: "I have 3 features ready for beta testing"

**Solution**:
```bash
# Merge all features to staging first
git checkout staging
git pull origin staging

git merge feature/feature-1
git merge feature/feature-2  
git merge feature/feature-3

git push origin staging

# Create one beta with all features
fastlane auto_beta
```

### Scenario 3: Need to Skip Beta
**Question**: "Can I go straight from feature to production?"

**Solution**:
```bash
# Not recommended, but possible for hotfixes
git checkout main
git merge feature/urgent-fix
git push origin main

fastlane bump_and_release bump:patch

# Update staging
git checkout staging
git merge main
git push origin staging
```

### Scenario 4: Failed Beta Release
**Question**: "Beta testing revealed issues, what now?"

**Solution**:
```bash
# Create fix
git checkout -b feature/fix-beta-issues
# Make fixes...
git add . && git commit -m "fix: resolve beta testing issues"

# Merge to staging
git checkout staging
git merge feature/fix-beta-issues
git push origin staging

# Create new beta
fastlane auto_beta
```

## Troubleshooting

### "You have uncommitted changes"
```bash
# Check what's uncommitted
git status

# Either commit or stash
git add . && git commit -m "Save work in progress"
# OR
git stash
```

### "Wrong branch for release"
```bash
# Beta release needs staging
git checkout staging

# Production release needs main  
git checkout main
```

### "Tag already exists"
```bash
# Check existing tags
git tag -l

# Use different version
fastlane auto_prod version:1.2.1

# Or delete tag (careful!)
git tag -d v1.2.0
git push origin --delete tag v1.2.0
```

### "GitHub CLI not authenticated"
```bash
# Login to GitHub CLI
gh auth login

# Follow prompts to authenticate
```

### "Cannot merge branch"
```bash
# Usually merge conflicts, resolve manually
git status
# Edit conflicted files
git add .
git commit -m "resolve merge conflicts"
```

## Quick Reference

### Daily Development
```bash
# Start feature
git checkout main && git pull && git checkout -b feature/my-feature

# Develop & test  
# ... make changes ...
fastlane dev

# Merge to staging
git checkout staging && git merge feature/my-feature

# Beta release
fastlane auto_beta
```

### Production Release
```bash
# Promote to production
git checkout main && git merge staging

# Automated release
fastlane bump_and_release bump:minor
```

### Emergency Hotfix
```bash
# Fix from main
git checkout main && git checkout -b hotfix/urgent

# ... make fix ...

# Deploy immediately
git checkout main && git merge hotfix/urgent
fastlane bump_and_release bump:patch force:true
```

---

*This workflow integrates with the automated Fastlane release system. For Fastlane-specific commands, see [fastlane-guide.md](fastlane-guide.md)*