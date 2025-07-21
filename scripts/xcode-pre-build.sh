#!/bin/bash

# Pre-build script for Xcode to ensure correct Info.plist is used
# This script runs before each Xcode build to fix the Info.plist configuration

echo "🔧 ClickIt Pre-Build: Configuring Info.plist for Xcode build..."

# Ensure we're in the project root
cd "${PROJECT_DIR}" || exit 1

# Check if our custom Info.plist exists
CUSTOM_INFOPLIST="ClickIt/Info.plist"
if [ ! -f "$CUSTOM_INFOPLIST" ]; then
    echo "❌ Custom Info.plist not found at $CUSTOM_INFOPLIST"
    exit 1
fi

echo "✅ Found custom Info.plist with permission descriptions"

# Verify it has permission descriptions
if grep -q "NSAccessibilityUsageDescription" "$CUSTOM_INFOPLIST" && \
   grep -q "NSAppleEventsUsageDescription" "$CUSTOM_INFOPLIST"; then
    echo "✅ Permission descriptions verified in custom Info.plist"
else
    echo "❌ Custom Info.plist missing permission descriptions"
    exit 1
fi

echo "🔧 Xcode build will use custom Info.plist with proper permissions"