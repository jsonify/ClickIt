#!/bin/bash

set -e  # Exit on any error

# Unified ClickIt build script supporting both SPM and Xcode workflows

BUILD_MODE="${1:-release}"   # Default to release, allow override
BUILD_SYSTEM="${2:-auto}"    # auto, spm, xcode
APP_VERSION="${3:-pro}"      # pro or lite, default to pro
DIST_DIR="dist"
BUNDLE_ID="com.jsonify.clickit"

# Configure target and names based on version
if [ "$APP_VERSION" = "lite" ]; then
    echo "🔄 Configuring for ClickIt Lite build..."
    SPM_TARGET="ClickItLite"      # SPM target name
    EXECUTABLE_NAME="ClickItLite" # Binary name from Package.swift
    APP_NAME="ClickIt Lite"       # .app bundle display name
    BUNDLE_ID="com.jsonify.clickit.lite"
else
    echo "🔄 Configuring for ClickIt Pro build..."
    SPM_TARGET="ClickIt"          # SPM target name
    EXECUTABLE_NAME="ClickIt"     # Binary name from Package.swift
    APP_NAME="ClickIt"            # .app bundle display name
    BUNDLE_ID="com.jsonify.clickit"
fi
# Get version from Info.plist (synced with GitHub releases)
get_version_from_plist() {
    /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ClickIt/Info.plist 2>/dev/null || echo "1.0.0"
}

VERSION=$(get_version_from_plist)
BUILD_NUMBER=$(date +%Y%m%d%H%M)

echo "🔨 Building $APP_NAME app bundle ($BUILD_MODE mode)..."
echo "📦 Version: $VERSION (from Info.plist, synced with GitHub releases)"
echo "🏷️  Edition: $([ "$APP_VERSION" = "lite" ] && echo "Lite (Simplified)" || echo "Pro (Full Featured)")"

# Validate version is synchronized with GitHub (optional validation)
if command -v gh > /dev/null 2>&1; then
    GITHUB_TAG=$(gh release list --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$GITHUB_TAG" ]; then
        GITHUB_VERSION=${GITHUB_TAG#v}
        if [ "$VERSION" != "$GITHUB_VERSION" ]; then
            echo "⚠️  Warning: Version mismatch detected!"
            echo "   Building: v$VERSION"
            echo "   GitHub: $GITHUB_TAG"
            echo "   Run './scripts/sync-version-from-github.sh' to sync versions"
        else
            echo "✅ Version synchronized with GitHub release $GITHUB_TAG"
        fi
    fi
fi

# Detect build system
detect_build_system() {
    if [ "$BUILD_SYSTEM" = "auto" ]; then
        if [ -f "ClickIt.xcodeproj/project.pbxproj" ]; then
            echo "🔍 Detected Xcode project - using Xcode build"
            BUILD_SYSTEM="xcode"
        elif [ -f "Package.swift" ]; then
            echo "🔍 Detected Package.swift - using SPM build"
            BUILD_SYSTEM="spm"
        else
            echo "❌ No build system detected (no Package.swift or ClickIt.xcodeproj found)"
            echo "💡 Make sure you're running this script from the project directory"
            exit 1
        fi
    fi
    echo "📦 Using build system: $BUILD_SYSTEM"
}

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$DIST_DIR/$APP_NAME.app"
rm -rf "$DIST_DIR/binaries"
mkdir -p "$DIST_DIR/binaries"

detect_build_system

if [ "$BUILD_SYSTEM" = "xcode" ]; then
    echo "🏗️  Building with Xcode..."
    
    # Find Xcode project
    XCODE_PROJECT=""
    if [ -f "ClickIt.xcodeproj/project.pbxproj" ]; then
        XCODE_PROJECT="ClickIt.xcodeproj"
    else
        echo "❌ Xcode project not found in current directory"
        echo "💡 Make sure you're running this script from /Users/jsonify/code/macOS/ClickIt/"
        exit 1
    fi
    
    # Convert SPM build mode to Xcode configuration
    XCODE_CONFIG="Debug"
    if [ "$BUILD_MODE" = "release" ]; then
        XCODE_CONFIG="Release"
    fi
    
    echo "⚙️  Building with configuration: $XCODE_CONFIG"
    
    # Build with Xcode using custom Info.plist
    echo "🔧 Configuring Xcode build to use custom Info.plist..."
    
    # Prepare build settings
    BUILD_SETTINGS="INFOPLIST_FILE=ClickIt/Info.plist GENERATE_INFOPLIST_FILE=NO"
    
    # Add code signing settings if specified (for CI)
    if [ -n "$CODE_SIGN_IDENTITY" ]; then
        BUILD_SETTINGS="$BUILD_SETTINGS CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY"
    fi
    if [ -n "$CODE_SIGNING_REQUIRED" ]; then
        BUILD_SETTINGS="$BUILD_SETTINGS CODE_SIGNING_REQUIRED=$CODE_SIGNING_REQUIRED"
    fi
    if [ -n "$CODE_SIGNING_ALLOWED" ]; then
        BUILD_SETTINGS="$BUILD_SETTINGS CODE_SIGNING_ALLOWED=$CODE_SIGNING_ALLOWED"
    fi
    if [ -n "$MACOSX_DEPLOYMENT_TARGET" ]; then
        BUILD_SETTINGS="$BUILD_SETTINGS MACOSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET"
    fi
    
    xcodebuild -project "$XCODE_PROJECT" -scheme ClickIt -configuration "$XCODE_CONFIG" \
        $BUILD_SETTINGS \
        build
    
    # Find the built app
    DERIVED_DATA_PATH=$(xcodebuild -project "$XCODE_PROJECT" -scheme ClickIt -configuration "$XCODE_CONFIG" -showBuildSettings | grep "BUILT_PRODUCTS_DIR" | cut -d'=' -f2 | xargs)
    BUILT_APP="$DERIVED_DATA_PATH/ClickIt.app"
    
    if [ ! -d "$BUILT_APP" ]; then
        # Fallback to default DerivedData location
        BUILT_APP="$HOME/Library/Developer/Xcode/DerivedData/ClickIt-*/Build/Products/$XCODE_CONFIG/ClickIt.app"
        BUILT_APP=$(ls -d $BUILT_APP 2>/dev/null | head -1)
    fi
    
    if [ ! -d "$BUILT_APP" ]; then
        echo "❌ Built app not found"
        exit 1
    fi
    
    echo "📁 Found built app at: $BUILT_APP"
    
    # Copy the built app to dist directory
    cp -R "$BUILT_APP" "$DIST_DIR/"
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    
    echo "✅ Xcode build completed successfully!"

else
    echo "🏗️  Building with Swift Package Manager..."
    
    # Detect available architectures (original SPM logic)
    echo "🔍 Detecting available architectures..."
    ARCH_LIST=()
    if swift build -c "$BUILD_MODE" --arch x86_64 --product "$SPM_TARGET" --show-bin-path > /dev/null 2>&1; then
        ARCH_LIST+=("x86_64")
    fi
    if swift build -c "$BUILD_MODE" --arch arm64 --product "$SPM_TARGET" --show-bin-path > /dev/null 2>&1; then
        ARCH_LIST+=("arm64")
    fi

    if [ ${#ARCH_LIST[@]} -eq 0 ]; then
        echo "❌ No supported architectures found"
        exit 1
    fi

    echo "📱 Building for architectures: ${ARCH_LIST[*]}"
    echo "🎯 Building target: $SPM_TARGET"

    # Build for each architecture
    BINARY_PATHS=()
    for arch in "${ARCH_LIST[@]}"; do
        echo "⚙️  Building $SPM_TARGET for $arch..."
        if ! swift build -c "$BUILD_MODE" --arch "$arch" --product "$SPM_TARGET"; then
            echo "❌ Build failed for $arch"
            exit 1
        fi

        # Get the actual build path
        BUILD_PATH=$(swift build -c "$BUILD_MODE" --arch "$arch" --product "$SPM_TARGET" --show-bin-path)
        BINARY_PATH="$BUILD_PATH/$EXECUTABLE_NAME"  # Use executable name, not app name
        
        if [ ! -f "$BINARY_PATH" ]; then
            echo "❌ Binary not found at $BINARY_PATH"
            exit 1
        fi
        
        # Copy binary to dist directory
        cp "$BINARY_PATH" "$DIST_DIR/binaries/$APP_NAME-$arch"
        BINARY_PATHS+=("$DIST_DIR/binaries/$APP_NAME-$arch")
    done

    # Create universal binary if multiple architectures
    if [ ${#BINARY_PATHS[@]} -gt 1 ]; then
        echo "🔗 Creating universal binary..."
        lipo -create -output "$DIST_DIR/binaries/$APP_NAME-universal" "${BINARY_PATHS[@]}"
        FINAL_BINARY="$DIST_DIR/binaries/$APP_NAME-universal"
    else
        echo "📦 Using single architecture binary..."
        FINAL_BINARY="${BINARY_PATHS[0]}"
    fi

    # Verify binary
    echo "🔍 Verifying binary architectures..."
    file "$FINAL_BINARY"
    lipo -info "$FINAL_BINARY" 2>/dev/null || echo "Single architecture binary"

    # Create app bundle structure
    echo "📁 Creating app bundle structure..."
    APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"

    # Copy executable
    cp "$FINAL_BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    
    # Bundle Sparkle framework for SPM builds
    echo "📦 Bundling Sparkle framework..."
    SPARKLE_FRAMEWORK_PATH=".build/checkouts/Sparkle/Sparkle.framework"
    if [ -d "$SPARKLE_FRAMEWORK_PATH" ]; then
        mkdir -p "$APP_BUNDLE/Contents/Frameworks"
        cp -R "$SPARKLE_FRAMEWORK_PATH" "$APP_BUNDLE/Contents/Frameworks/"
        echo "✅ Sparkle framework bundled successfully"
    else
        echo "⚠️  Sparkle framework not found at $SPARKLE_FRAMEWORK_PATH"
        echo "🔍 Searching for Sparkle framework..."
        SPARKLE_SEARCH=$(find .build -name "Sparkle.framework" -type d 2>/dev/null | head -1)
        if [ -n "$SPARKLE_SEARCH" ]; then
            mkdir -p "$APP_BUNDLE/Contents/Frameworks"
            cp -R "$SPARKLE_SEARCH" "$APP_BUNDLE/Contents/Frameworks/"
            echo "✅ Found and bundled Sparkle framework from $SPARKLE_SEARCH"
        else
            echo "❌ Sparkle framework not found - app will crash on launch"
            echo "💡 Run 'swift package resolve' to ensure dependencies are downloaded"
        fi
    fi

    # Create Info.plist with required permissions
    cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>ClickIt needs to send Apple Events to simulate mouse clicks in target applications.</string>
    <key>NSSystemAdministrationUsageDescription</key>
    <string>ClickIt requires accessibility access to simulate mouse clicks and detect window information.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>ClickIt needs accessibility access to control mouse clicks and interact with other applications.</string>
    <key>NSScreenCaptureUsageDescription</key>
    <string>ClickIt needs screen recording access to detect windows and provide visual feedback overlays.</string>
</dict>
</plist>
EOF

    # Make executable
    chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

    # Copy SPM resource bundles to app bundle
    echo "📦 Copying resource bundles..."
    # For ClickItLite: ClickIt_ClickItLite.bundle
    # For ClickIt: ClickIt_ClickIt.bundle
    RESOURCE_BUNDLE_NAME="ClickIt_${SPM_TARGET}.bundle"

    # Find the resource bundle in the build output
    for arch in "${ARCH_LIST[@]}"; do
        BUILD_PATH=$(swift build -c "$BUILD_MODE" --arch "$arch" --product "$SPM_TARGET" --show-bin-path)
        RESOURCE_BUNDLE_PATH="$BUILD_PATH/$RESOURCE_BUNDLE_NAME"

        if [ -d "$RESOURCE_BUNDLE_PATH" ]; then
            echo "✅ Found resource bundle at: $RESOURCE_BUNDLE_PATH"
            cp -R "$RESOURCE_BUNDLE_PATH" "$APP_BUNDLE/Contents/Resources/"
            echo "✅ Copied $RESOURCE_BUNDLE_NAME to app bundle"
            break
        fi
    done

    if [ ! -d "$APP_BUNDLE/Contents/Resources/$RESOURCE_BUNDLE_NAME" ]; then
        echo "⚠️  Warning: Resource bundle $RESOURCE_BUNDLE_NAME not found"
        echo "   App may not be able to load custom resources"
    fi

    # Fix rpath for bundled frameworks (SPM builds)
    echo "🔧 Adding Frameworks directory to rpath..."
    install_name_tool -add_rpath "@loader_path/../Frameworks" "$APP_BUNDLE/Contents/MacOS/$APP_NAME" 2>/dev/null || echo "  rpath already exists or modification failed"

    echo "✅ SPM build completed successfully!"
fi

# Common post-build steps for both systems
# Skip code signing if explicitly disabled (CI environment)
if [ "$CODE_SIGNING_ALLOWED" = "NO" ] || [ "$CODE_SIGNING_REQUIRED" = "NO" ]; then
    echo "⏭️  Skipping code signing (disabled for CI)"
    CERT_NAME=""
else
    echo "🔐 Attempting to code sign the app..."
    CERT_NAME=""

    # Try to find a suitable code signing certificate
    echo "🔍 Looking for code signing certificates..."

# First, check if ClickIt Developer Certificate exists (even if not shown by find-identity)
if security find-certificate -c "ClickIt Developer Certificate" >/dev/null 2>&1; then
    CERT_NAME="ClickIt Developer Certificate"
    echo "✅ Found ClickIt Developer Certificate (self-signed)"
else
    # Fall back to other available certificates
    AVAILABLE_CERTS=$(security find-identity -v -p codesigning 2>/dev/null | grep -E '".*"' | head -5)
    
    if [ -n "$AVAILABLE_CERTS" ]; then
        echo "📜 Available certificates:"
        echo "$AVAILABLE_CERTS"
        
        # Look for ClickIt-specific certificate first in the list
        CLICKIT_CERT=$(echo "$AVAILABLE_CERTS" | grep -i "clickit" | head -1 | sed 's/.*"\(.*\)".*/\1/')
        if [ -n "$CLICKIT_CERT" ]; then
            CERT_NAME="$CLICKIT_CERT"
            echo "✅ Found ClickIt-specific certificate: $CERT_NAME"
        else
            # Fall back to first available certificate
            FIRST_CERT=$(echo "$AVAILABLE_CERTS" | head -1 | sed 's/.*"\(.*\)".*/\1/')
            if [ -n "$FIRST_CERT" ]; then
                CERT_NAME="$FIRST_CERT"
                echo "⚠️  Using first available certificate: $CERT_NAME"
            fi
        fi
    fi
fi

if [ -n "$CERT_NAME" ]; then
    echo "🔐 Code signing with certificate: $CERT_NAME"
    
    # Sign frameworks first (if they exist)
    if [ -d "$APP_BUNDLE/Contents/Frameworks" ]; then
        echo "🔐 Signing embedded frameworks..."
        for framework in "$APP_BUNDLE/Contents/Frameworks"/*.framework; do
            if [ -d "$framework" ]; then
                echo "  Signing $(basename "$framework")..."
                codesign --deep --force --sign "$CERT_NAME" "$framework" 2>/dev/null || echo "    ⚠️  Failed to sign $(basename "$framework")"
            fi
        done
    fi
    
    # Sign the main app bundle (after all modifications including rpath changes)
    # Use entitlements if they exist
    ENTITLEMENTS_FILE="ClickIt/ClickIt.entitlements"
    if [ -f "$ENTITLEMENTS_FILE" ]; then
        echo "🔐 Using entitlements from $ENTITLEMENTS_FILE"
        codesign --deep --force --sign "$CERT_NAME" --entitlements "$ENTITLEMENTS_FILE" "$APP_BUNDLE"
        CODESIGN_RESULT=$?
    else
        echo "⚠️  No entitlements file found at $ENTITLEMENTS_FILE"
        codesign --deep --force --sign "$CERT_NAME" "$APP_BUNDLE"
        CODESIGN_RESULT=$?
    fi
    
    if [ $CODESIGN_RESULT -eq 0 ]; then
        echo "✅ Code signing successful!"
        
        # Verify the signature
        if codesign --verify --verbose "$APP_BUNDLE" 2>/dev/null; then
            echo "✅ Code signature verification passed"
        else
            echo "⚠️  Code signature verification failed, but app was signed"
        fi
    else
        echo "⚠️  Code signing failed, but app will still work (permissions may not persist)"
    fi
else
    echo "⚠️  No code signing certificates found"
    echo "📋 To improve permission persistence, create a self-signed certificate:"
    echo "   See CERTIFICATE_SETUP.md for instructions"
fi

fi  # End of code signing conditional

# Create build metadata
echo "📋 Creating build metadata..."
cat > "$DIST_DIR/build-info.txt" << EOF
Build Date: $(date)
Mode: $BUILD_MODE
Build System: $BUILD_SYSTEM
$([ "$BUILD_SYSTEM" = "spm" ] && echo "Architectures: ${ARCH_LIST[*]}")
$([ "$BUILD_SYSTEM" = "spm" ] && echo "Binary Type: $([ ${#BINARY_PATHS[@]} -gt 1 ] && echo "Universal" || echo "Single Architecture")")
Version: $VERSION
Build Number: $BUILD_NUMBER
Bundle ID: $BUNDLE_ID
Code Signed: $([ -n "$CERT_NAME" ] && echo "Yes ($CERT_NAME)" || echo "No")
EOF

echo "✅ $APP_NAME.app created successfully!"
echo "📂 Location: $APP_BUNDLE"
echo "📱 Launch with: open \"$APP_BUNDLE\""
echo "🔧 The app should now appear in System Settings > Accessibility"
echo "📋 Build info: $DIST_DIR/build-info.txt"
echo ""
echo "🔄 Build system used: $BUILD_SYSTEM"
if [ "$BUILD_SYSTEM" = "xcode" ]; then
    echo "💡 To build with SPM instead: $0 $BUILD_MODE spm"
else
    echo "💡 To build with Xcode instead: $0 $BUILD_MODE xcode"
fi