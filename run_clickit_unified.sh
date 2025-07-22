#!/bin/bash

# Unified ClickIt run script supporting both SPM and Xcode workflows

BUILD_SYSTEM="${1:-auto}"  # auto, spm, xcode, app
APP_NAME="ClickIt"

echo "🚀 Running ClickIt..."

# Detect available run methods
detect_run_method() {
    if [ "$BUILD_SYSTEM" = "auto" ]; then
        # Check for existing app bundle first
        if [ -d "dist/ClickIt.app" ]; then
            echo "🔍 Found dist/ClickIt.app - running app bundle"
            BUILD_SYSTEM="app"
        elif [ -f "ClickIt.xcodeproj/project.pbxproj" ]; then
            echo "🔍 Detected Xcode project - using Xcode run"
            BUILD_SYSTEM="xcode"
        elif [ -f "Package.swift" ]; then
            echo "🔍 Detected Package.swift - using SPM run"
            BUILD_SYSTEM="spm"
        else
            echo "❌ No run method detected"
            echo "💡 Make sure you're running this script from the project directory"
            exit 1
        fi
    fi
    echo "📦 Using run method: $BUILD_SYSTEM"
}

detect_run_method

case "$BUILD_SYSTEM" in
    "app")
        echo "📱 Running app bundle..."
        if [ ! -d "dist/ClickIt.app" ]; then
            echo "❌ App bundle not found at dist/ClickIt.app"
            echo "💡 Build first with: ./build_app.sh"
            exit 1
        fi
        
        echo "🚀 Launching ClickIt.app..."
        if open "dist/ClickIt.app" 2>/dev/null; then
            echo "✅ ClickIt launched successfully!"
            echo "🔧 The app should appear in your Dock and System Settings > Accessibility"
        else
            echo "⚠️  App bundle launch failed - trying direct executable..."
            if [ -f "dist/ClickIt.app/Contents/MacOS/ClickIt" ]; then
                echo "🚀 Launching executable directly..."
                "./dist/ClickIt.app/Contents/MacOS/ClickIt" &
                echo "✅ ClickIt launched via direct executable!"
                echo "🔧 The app should appear in your Dock and System Settings > Accessibility"
            else
                echo "❌ Could not launch ClickIt"
                echo "💡 Try: codesign --force --deep --sign - dist/ClickIt.app"
                exit 1
            fi
        fi
        ;;
        
    "xcode")
        echo "🏗️  Building and running with Xcode..."
        
        # Find Xcode project
        XCODE_PROJECT=""
        
        if [ -f "ClickIt.xcodeproj/project.pbxproj" ]; then
            XCODE_PROJECT="ClickIt.xcodeproj"
        else
            echo "❌ Xcode project not found in current directory"
            echo "💡 Make sure you're running this script from /Users/jsonify/code/macOS/ClickIt/"
            exit 1
        fi
        
        echo "⚙️  Building and running with Xcode..."
        
        # Build and run
        xcodebuild -project "$XCODE_PROJECT" -scheme ClickIt -configuration Debug build
        
        # Find the built app and run it
        DERIVED_DATA_PATH=$(xcodebuild -project "$XCODE_PROJECT" -scheme ClickIt -configuration Debug -showBuildSettings | grep "BUILT_PRODUCTS_DIR" | cut -d'=' -f2 | xargs)
        BUILT_APP="$DERIVED_DATA_PATH/ClickIt.app"
        
        if [ ! -d "$BUILT_APP" ]; then
            # Fallback to default DerivedData location
            BUILT_APP="$HOME/Library/Developer/Xcode/DerivedData/ClickIt-*/Build/Products/Debug/ClickIt.app"
            BUILT_APP=$(ls -d $BUILT_APP 2>/dev/null | head -1)
        fi
        
        if [ ! -d "$BUILT_APP" ]; then
            echo "❌ Built app not found"
            exit 1
        fi
        
        echo "🚀 Launching ClickIt..."
        open "$BUILT_APP"
        
        echo "✅ ClickIt launched successfully!"
        ;;
        
    "spm")
        echo "🏗️  Building and running with Swift Package Manager..."
        
        # Build first
        echo "⚙️  Building..."
        swift build
        
        if [ $? -ne 0 ]; then
            echo "❌ Build failed"
            exit 1
        fi
        
        echo "🚀 Launching ClickIt..."
        
        # Get the build path
        BUILD_PATH=$(swift build --show-bin-path)
        BINARY_PATH="$BUILD_PATH/$APP_NAME"
        
        if [ ! -f "$BINARY_PATH" ]; then
            echo "❌ Binary not found at $BINARY_PATH"
            exit 1
        fi
        
        # Run in background and get PID
        "$BINARY_PATH" &
        APP_PID=$!
        
        # Wait a moment for app to initialize
        sleep 2
        
        # Force activation using osascript
        osascript -e 'tell application "System Events" to tell process "ClickIt" to set frontmost to true' 2>/dev/null
        
        # Also try activating by process name
        osascript -e 'tell application "ClickIt" to activate' 2>/dev/null
        
        echo "✅ ClickIt launched with PID: $APP_PID"
        echo "🔧 If window doesn't appear, check Activity Monitor or Dock"
        echo "⚠️  Press Ctrl+C to quit"
        
        # Wait for app to finish
        wait $APP_PID
        ;;
        
    *)
        echo "❌ Unknown build system: $BUILD_SYSTEM"
        echo "💡 Valid options: auto, app, xcode, spm"
        exit 1
        ;;
esac

echo "🎉 Run completed!"