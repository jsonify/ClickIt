#!/bin/bash
# scripts/sync-version-from-github.sh
# Sync Info.plist version with latest GitHub release
set -e

echo "🔄 Syncing version from GitHub releases..."

# Get latest GitHub release tag
LATEST_TAG=$(gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null || git describe --tags --abbrev=0)
VERSION=${LATEST_TAG#v}  # Remove 'v' prefix

echo "📦 Latest GitHub release: $LATEST_TAG"
echo "📝 Extracted version: $VERSION"

# Current Info.plist version
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ClickIt/Info.plist)

if [ "$VERSION" != "$CURRENT_VERSION" ]; then
    echo "⚠️  Version mismatch detected!"
    echo "   Info.plist: $CURRENT_VERSION"
    echo "   GitHub: $VERSION"
    echo ""
    echo "🔧 Updating Info.plist to match GitHub release..."
    
    # Update Info.plist
    /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" ClickIt/Info.plist
    
    echo "✅ Info.plist updated to v$VERSION"
    echo "🔄 UI will now display v$VERSION"
else
    echo "✅ Versions are synchronized (v$VERSION)"
fi

echo ""
echo "📋 Final Status:"
echo "   GitHub Release: $LATEST_TAG"
echo "   Info.plist: v$VERSION"
echo "   UI will show: v$VERSION"