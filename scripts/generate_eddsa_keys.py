#!/usr/bin/env python3
"""
EdDSA key pair generation script for Sparkle updates.
Generates a private/public key pair for signing and verifying updates.
"""

import os
import sys
import base64
import tempfile
import subprocess
from pathlib import Path

def generate_with_sparkle_tools():
    """Generate keys using Sparkle's generate_keys tool if available."""
    try:
        # Check if generate_keys is available
        which_result = subprocess.run(['which', 'generate_keys'], capture_output=True, text=True)
        if which_result.returncode != 0:
            return None
        
        # Use Sparkle's generate_keys tool
        result = subprocess.run(['generate_keys'], capture_output=True, text=True, check=True)
        
        # Parse output
        lines = result.stdout.strip().split('\n')
        private_key = None
        public_key = None
        
        for line in lines:
            if 'Private key:' in line:
                private_key = line.split('Private key:')[1].strip()
            elif 'Public key:' in line:
                public_key = line.split('Public key:')[1].strip()
        
        return private_key, public_key
        
    except subprocess.CalledProcessError as e:
        print(f"Error with Sparkle tools: {e}")
        return None

def generate_with_python():
    """Generate keys using Python cryptography libraries."""
    try:
        import nacl.signing
        import nacl.encoding
        
        # Generate private key
        private_key = nacl.signing.SigningKey.generate()
        public_key = private_key.verify_key
        
        # Encode keys as base64
        private_key_b64 = base64.b64encode(private_key.encode()).decode('utf-8')
        public_key_b64 = base64.b64encode(public_key.encode()).decode('utf-8')
        
        return private_key_b64, public_key_b64
        
    except ImportError:
        print("⚠️  PyNaCl not available. Please install it with: pip install PyNaCl")
        return None
    except Exception as e:
        print(f"Error generating keys with Python: {e}")
        return None

def save_keys_to_files(private_key, public_key, output_dir="."):
    """Save keys to separate files."""
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    # Save private key
    private_key_file = output_path / "sparkle_private_key.txt"
    with open(private_key_file, 'w') as f:
        f.write(private_key)
    
    # Save public key
    public_key_file = output_path / "sparkle_public_key.txt"
    with open(public_key_file, 'w') as f:
        f.write(public_key)
    
    # Set restrictive permissions on private key
    os.chmod(private_key_file, 0o600)
    
    return private_key_file, public_key_file

def generate_info_plist_snippet(public_key):
    """Generate Info.plist snippet for the public key."""
    return f"""
<!-- Add this to your app's Info.plist -->
<key>SUPublicEDKey</key>
<string>{public_key}</string>
"""

def generate_github_secrets_instructions(private_key):
    """Generate instructions for setting up GitHub secrets."""
    return f"""
# GitHub Secrets Setup Instructions

1. Go to your repository on GitHub
2. Navigate to Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Name: SPARKLE_PRIVATE_KEY
5. Value: {private_key}
6. Click "Add secret"

This private key will be used to sign your release assets automatically.
"""

def main():
    """Main execution function."""
    print("🔐 Generating EdDSA key pair for Sparkle updates...")
    
    # Try to generate keys
    keys = generate_with_sparkle_tools()
    if not keys:
        print("📦 Sparkle tools not found, using Python implementation...")
        keys = generate_with_python()
    
    if not keys:
        print("❌ Could not generate keys. Please ensure you have either:")
        print("   - Sparkle framework tools installed")
        print("   - PyNaCl Python library installed (pip install PyNaCl)")
        return 1
    
    private_key, public_key = keys
    
    # Determine output directory
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    
    # Save keys to files
    private_key_file, public_key_file = save_keys_to_files(private_key, public_key, output_dir)
    
    print(f"✅ Keys generated successfully!")
    print(f"📁 Private key saved to: {private_key_file}")
    print(f"📁 Public key saved to: {public_key_file}")
    print()
    
    # Generate instructions
    print("📋 Setup Instructions:")
    print("=" * 50)
    
    print("\n1. Info.plist Configuration:")
    print(generate_info_plist_snippet(public_key))
    
    print("\n2. GitHub Secrets Setup:")
    instructions_file = Path(output_dir) / "github_secrets_setup.md"
    with open(instructions_file, 'w') as f:
        f.write(generate_github_secrets_instructions(private_key))
    
    print(f"   📄 Detailed instructions saved to: {instructions_file}")
    
    print("\n⚠️  IMPORTANT SECURITY NOTES:")
    print("   - Keep the private key secure and never commit it to version control")
    print("   - The private key is used to sign releases - treat it like a password")
    print("   - The public key should be embedded in your app for signature verification")
    print("   - Consider using different keys for development and production")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())