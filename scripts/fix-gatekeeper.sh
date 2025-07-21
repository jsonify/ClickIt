#!/bin/bash

# Fix Gatekeeper issues for ClickIt.app
# Use this script to resolve "damaged app" issues on Apple Silicon Macs

set -e

APP_PATH="${1:-dist/ClickIt.app}"

echo "🔧 Fixing Gatekeeper issues for $APP_PATH..."

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH"
    echo "💡 Usage: $0 [path/to/ClickIt.app]"
    exit 1
fi

echo "🔍 Removing quarantine attributes..."
xattr -rd com.apple.quarantine "$APP_PATH" 2>/dev/null || echo "  No quarantine attributes found"

echo "🔍 Removing extended attributes..."
xattr -c "$APP_PATH" 2>/dev/null || echo "  No extended attributes found"

echo "🔍 Checking Gatekeeper status..."
if spctl --assess --type exec "$APP_PATH" 2>/dev/null; then
    echo "✅ App passes Gatekeeper assessment"
else
    echo "⚠️  App rejected by Gatekeeper (expected with self-signed certificate)"
    echo "🔧 To run the app despite Gatekeeper:"
    echo "   1. Try to open the app normally"
    echo "   2. When blocked, go to System Settings > Privacy & Security"
    echo "   3. Click 'Open Anyway' next to the ClickIt warning"
    echo "   OR"
    echo "   4. Disable Gatekeeper temporarily: sudo spctl --master-disable"
    echo "   5. Re-enable after testing: sudo spctl --master-enable"
fi

echo "✅ Gatekeeper fixes applied successfully!"
echo "📱 Try opening: open '$APP_PATH'"