#!/bin/bash

# Setup Code Signing for CI Environment
# Handles certificate installation and keychain setup for GitHub Actions

set -e

echo "🔐 Setting up CI code signing environment..."

# Check if we're in a CI environment
if [ -z "$CI" ]; then
    echo "⚠️  This script is designed for CI environments"
    echo "   For local development, use the regular signing setup"
    exit 1
fi

# Check required environment variables
if [ -z "$CERTIFICATE_BASE64" ] || [ -z "$CERTIFICATE_PASSWORD" ]; then
    echo "❌ Missing required environment variables:"
    echo "   CERTIFICATE_BASE64: Base64 encoded .p12 certificate"
    echo "   CERTIFICATE_PASSWORD: Certificate password"
    echo ""
    echo "💡 Setup instructions:"
    echo "   1. Export your certificate as .p12 from Keychain Access"
    echo "   2. Encode it: base64 -i certificate.p12 | pbcopy"
    echo "   3. Add CERTIFICATE_BASE64 and CERTIFICATE_PASSWORD to GitHub Secrets"
    exit 1
fi

# Create temporary keychain
TEMP_KEYCHAIN="clickit-ci-keychain"
KEYCHAIN_PASSWORD="ci-keychain-password"

echo "🔑 Creating temporary keychain..."
security create-keychain -p "$KEYCHAIN_PASSWORD" "$TEMP_KEYCHAIN"
security set-keychain-settings -lut 21600 "$TEMP_KEYCHAIN"  # 6 hours timeout
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$TEMP_KEYCHAIN"

# Import certificate
echo "📜 Importing certificate..."
echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
security import certificate.p12 -k "$TEMP_KEYCHAIN" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
rm certificate.p12

# Set the keychain in search list
echo "🔧 Configuring keychain search list..."
security list-keychains -d user -s "$TEMP_KEYCHAIN" login.keychain

# Allow codesign to access the certificate
echo "🔓 Configuring certificate access..."
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$TEMP_KEYCHAIN"

# Find and set the code signing identity
echo "🔍 Finding code signing identity..."
CODE_SIGN_IDENTITY=$(security find-identity -v -p codesigning "$TEMP_KEYCHAIN" | grep "Developer" | head -1 | grep -o '".*"' | sed 's/"//g')

if [ -z "$CODE_SIGN_IDENTITY" ]; then
    echo "❌ No valid code signing identity found"
    security find-identity -v -p codesigning "$TEMP_KEYCHAIN"
    exit 1
fi

echo "✅ Code signing identity found: $CODE_SIGN_IDENTITY"
echo "CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY" >> $GITHUB_ENV

echo "🎉 CI code signing setup complete!"

# Cleanup function for later use
cat << 'EOF' > cleanup-ci-signing.sh
#!/bin/bash
# Cleanup CI signing environment
if [ -n "$CI" ]; then
    echo "🧹 Cleaning up CI keychain..."
    security delete-keychain clickit-ci-keychain 2>/dev/null || true
    rm -f cleanup-ci-signing.sh
    echo "✅ Cleanup complete"
fi
EOF
chmod +x cleanup-ci-signing.sh