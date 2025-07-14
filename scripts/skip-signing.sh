#!/bin/bash

# Skip additional signing - app already works with self-signed certificate
# Usage: ./scripts/skip-signing.sh

echo "🔐 Skipping additional code signing..."
echo "✅ App is already signed with ClickIt Developer Certificate"
echo "📱 Launch with: open dist/ClickIt.app"

# Verify current signature
echo "📋 Current signature:"
codesign -dv dist/ClickIt.app

echo "🎉 Ready to use!"