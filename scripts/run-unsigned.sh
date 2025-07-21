#!/bin/bash

# Script to run ClickIt app bypassing Gatekeeper restrictions

APP_PATH="dist/ClickIt.app"

echo "🔓 Removing all extended attributes from ClickIt.app..."

# Remove all extended attributes
sudo xattr -cr "$APP_PATH" 2>/dev/null || true

# Additional cleanup
xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null || true
xattr -d com.apple.provenance "$APP_PATH" 2>/dev/null || true

echo "🚀 Launching ClickIt..."
open "$APP_PATH"

echo "✅ If the app still doesn't launch, you can try:"
echo "   1. Right-click ClickIt.app → Open"
echo "   2. Or run: sudo spctl --master-disable (temporarily disable Gatekeeper)"