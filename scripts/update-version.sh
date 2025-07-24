#!/bin/bash
# scripts/update-version.sh
# Enhanced version update with GitHub Release integration
set -e

NEW_VERSION="$1"
CREATE_RELEASE="${2:-true}"

if [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <version> [create_release]"
    echo ""
    echo "Examples:"
    echo "  $0 1.5.0              # Update to 1.5.0 and trigger GitHub release"
    echo "  $0 1.5.0 false        # Update to 1.5.0 without GitHub release"
    echo ""
    echo "This script will:"
    echo "  1. Update Info.plist CFBundleShortVersionString"
    echo "  2. Commit the change to git"
    echo "  3. Create and push git tag"
    echo "  4. Optionally trigger GitHub release via CI/CD"
    exit 1
fi

echo "🔄 Updating ClickIt to version $NEW_VERSION"

# Validate version format (basic semantic versioning)
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format. Use semantic versioning (e.g., 1.5.0)"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ClickIt/Info.plist)
echo "📦 Current version: $CURRENT_VERSION"
echo "📦 New version: $NEW_VERSION"

# Check if version already exists
if [ "$CURRENT_VERSION" = "$NEW_VERSION" ]; then
    echo "⚠️  Version $NEW_VERSION is already current"
    exit 0
fi

# Check if git tag already exists
if git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
    echo "❌ Git tag v$NEW_VERSION already exists"
    exit 1
fi

# Update Info.plist
echo "🔧 Updating Info.plist..."
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $NEW_VERSION" ClickIt/Info.plist

# Verify the change
UPDATED_VERSION=$(/usr/libexec/PListBuddy -c "Print CFBundleShortVersionString" ClickIt/Info.plist)
if [ "$UPDATED_VERSION" != "$NEW_VERSION" ]; then
    echo "❌ Failed to update Info.plist"
    exit 1
fi

echo "✅ Info.plist updated to v$NEW_VERSION"

# Git operations
echo "📝 Committing changes..."
git add ClickIt/Info.plist
git commit -m "chore: bump version to v$NEW_VERSION

- Update CFBundleShortVersionString to $NEW_VERSION  
- UI will now display v$NEW_VERSION
- Synchronized with GitHub release workflow"

# Create and push tag
echo "🏷️  Creating git tag v$NEW_VERSION..."
git tag "v$NEW_VERSION"

echo "🚀 Pushing to remote..."
git push origin main
git push origin "v$NEW_VERSION"

if [ "$CREATE_RELEASE" = "true" ]; then
    echo ""
    echo "🎉 Version v$NEW_VERSION pushed successfully!"
    echo ""
    echo "🚀 GitHub Release will be created automatically:"
    echo "   - Monitor CI/CD: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
    echo "   - Release will be at: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/releases/tag/v$NEW_VERSION"
    echo ""
    echo "📦 The release will include:"
    echo "   - Universal macOS app bundle (ClickIt.app.zip)"
    echo "   - Automatic release notes with changelog"
    echo "   - Build metadata and verification"
else
    echo ""
    echo "📝 Version v$NEW_VERSION updated locally without GitHub release"
    echo "   - Git tag created and pushed"
    echo "   - To create release later, push the tag: git push origin v$NEW_VERSION"
fi

echo ""
echo "✅ Version update complete!"
echo "   Previous: v$CURRENT_VERSION"
echo "   Current: v$NEW_VERSION"
echo "   UI will display: v$NEW_VERSION"