#!/bin/bash

# Sign ClickIt app for stable permissions
# Usage: ./scripts/sign-app.sh

set -e

echo "🔐 Signing ClickIt app..."

# Build the app first
swift build

# Copy to app bundle (if not already done by build script)
if [ ! -d "dist/ClickIt.app" ]; then
    echo "❌ App bundle not found at dist/ClickIt.app"
    echo "   Run the build script first to create the app bundle"
    exit 1
fi

# Sign with development certificate (trying the other cert)
codesign --force --sign "Apple Development: jrueckert@costco.com (826L9Z2Y4X)" --timestamp dist/ClickIt.app

# Verify signing
echo "✅ Verifying signature..."
codesign -dv dist/ClickIt.app

echo "🎉 App signed successfully!"
echo "   Identifier: $(codesign -dr - dist/ClickIt.app 2>&1 | grep 'Identifier=')"
echo "   Authority: $(codesign -dv dist/ClickIt.app 2>&1 | grep 'Authority=' | head -1)"