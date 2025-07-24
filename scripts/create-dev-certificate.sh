#!/bin/bash

# Create ClickIt Development Certificate for consistent app signing
# This creates a permanent self-signed certificate that maintains app identity across builds

set -e

CERT_NAME="ClickIt Developer Certificate"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
TEMP_DIR=$(mktemp -d)

echo "🔐 Creating ClickIt development certificate..."

# Delete existing certificate if it exists
security delete-certificate -c "$CERT_NAME" 2>/dev/null && echo "  Removed existing certificate" || true

# Create certificate configuration
cat > "$TEMP_DIR/cert.conf" << EOF
[req]
default_bits = 2048
prompt = no
distinguished_name = dn
req_extensions = v3_req

[dn]
CN=ClickIt Developer Certificate
O=ClickIt Development
OU=ClickIt Team
C=US

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
EOF

echo "📝 Generating private key and certificate..."

# Generate private key
openssl genrsa -out "$TEMP_DIR/private.key" 2048

# Generate self-signed certificate (valid for 10 years)
openssl req -new -x509 -key "$TEMP_DIR/private.key" -out "$TEMP_DIR/cert.crt" -days 3650 -config "$TEMP_DIR/cert.conf" -extensions v3_req

echo "🔑 Importing certificate and private key into keychain..."

# Import certificate first
security import "$TEMP_DIR/cert.crt" -k "$KEYCHAIN" -T /usr/bin/codesign -T /usr/bin/security

# Import private key
security import "$TEMP_DIR/private.key" -k "$KEYCHAIN" -T /usr/bin/codesign -T /usr/bin/security

echo "✅ Certificate imported successfully"

# Set trust settings for code signing (allow without password)
security set-key-partition-list -S apple-tool:,apple: -s -k "" -D "$CERT_NAME" -t private "$KEYCHAIN" 2>/dev/null || echo "  Trust settings configured"

# Add trust settings for code signing (this makes it appear in find-identity)
echo "🔐 Setting certificate trust for code signing..."
security add-trusted-cert -d -r trustRoot -k "$KEYCHAIN" "$TEMP_DIR/cert.crt" 2>/dev/null || echo "  Certificate already trusted"

# Verify certificate was created
if security find-certificate -c "$CERT_NAME" >/dev/null 2>&1; then
    echo "✅ Certificate verification passed"
    
    # Show certificate details
    echo "📋 Certificate details:"
    security find-certificate -c "$CERT_NAME" -p | openssl x509 -subject -dates -noout 2>/dev/null
else
    echo "❌ Certificate verification failed"
    exit 1
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo ""
echo "🎯 Certificate setup complete!"
echo "   Name: $CERT_NAME"
echo "   This certificate will provide consistent app identity across builds"
echo "   Permissions should now persist after rebuilding the app"