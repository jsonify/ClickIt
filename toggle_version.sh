#!/bin/bash

# Script to toggle between ClickIt Pro and ClickIt Lite
# Usage: ./toggle_version.sh [pro|lite]

set -e

VERSION="${1:-pro}"  # Default to pro

CLICKIT_APP="Sources/ClickIt/ClickItApp.swift"
CLICKIT_LITE_APP="Sources/ClickIt/Lite/ClickItLiteApp.swift"

if [ "$VERSION" = "lite" ]; then
    echo "🔄 Switching to ClickIt Lite..."

    # Comment out @main in ClickItApp.swift
    if grep -q "^@main" "$CLICKIT_APP"; then
        sed -i.bak 's/^@main$/\/\/ @main/' "$CLICKIT_APP"
        echo "✅ Commented out @main in ClickItApp.swift"
    else
        echo "ℹ️  @main already commented in ClickItApp.swift"
    fi

    # Uncomment @main in ClickItLiteApp.swift
    if grep -q "^\/\/ @main" "$CLICKIT_LITE_APP"; then
        sed -i.bak 's/^\/\/ @main/@main/' "$CLICKIT_LITE_APP"
        echo "✅ Uncommented @main in ClickItLiteApp.swift"
    else
        echo "ℹ️  @main already uncommented in ClickItLiteApp.swift"
    fi

    # Clean up backup files
    rm -f "$CLICKIT_APP.bak" "$CLICKIT_LITE_APP.bak"

    echo "✅ Switched to ClickIt Lite"

elif [ "$VERSION" = "pro" ]; then
    echo "🔄 Switching to ClickIt Pro..."

    # Uncomment @main in ClickItApp.swift
    if grep -q "^\/\/ @main" "$CLICKIT_APP"; then
        sed -i.bak 's/^\/\/ @main/@main/' "$CLICKIT_APP"
        echo "✅ Uncommented @main in ClickItApp.swift"
    else
        echo "ℹ️  @main already uncommented in ClickItApp.swift"
    fi

    # Comment out @main in ClickItLiteApp.swift
    if grep -q "^@main" "$CLICKIT_LITE_APP"; then
        sed -i.bak 's/^@main$/\/\/ @main/' "$CLICKIT_LITE_APP"
        echo "✅ Commented out @main in ClickItLiteApp.swift"
    else
        echo "ℹ️  @main already commented in ClickItLiteApp.swift"
    fi

    # Clean up backup files
    rm -f "$CLICKIT_APP.bak" "$CLICKIT_LITE_APP.bak"

    echo "✅ Switched to ClickIt Pro"

else
    echo "❌ Invalid version: $VERSION"
    echo "Usage: $0 [pro|lite]"
    exit 1
fi
