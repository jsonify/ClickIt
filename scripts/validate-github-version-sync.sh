#!/bin/bash
# scripts/validate-github-version-sync.sh
# Validate version synchronization between Info.plist and GitHub releases
set -e

echo "🔍 Validating version synchronization with GitHub..."

# Get versions
PLIST_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ClickIt/Info.plist)
GITHUB_TAG=$(gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null || git describe --tags --abbrev=0)
GITHUB_VERSION=${GITHUB_TAG#v}

echo "📋 Version Status:"
echo "   Info.plist (UI): $PLIST_VERSION"
echo "   GitHub Release: $GITHUB_VERSION"

if [ "$PLIST_VERSION" != "$GITHUB_VERSION" ]; then
    echo ""
    echo "❌ VERSION MISMATCH DETECTED!"
    echo "   The UI will show v$PLIST_VERSION"
    echo "   But the latest release is $GITHUB_TAG"
    echo ""
    echo "🔧 To fix, run: ./scripts/sync-version-from-github.sh"
    exit 1
else
    echo "✅ Versions are synchronized"
    echo "   UI will display: v$PLIST_VERSION"
    echo "   GitHub release: $GITHUB_TAG"
fi