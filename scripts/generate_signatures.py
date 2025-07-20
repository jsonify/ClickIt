#!/usr/bin/env python3
"""
Signature generation script for Sparkle updates.
Generates EdDSA signatures for release assets using the Sparkle sign_update tool.
"""

import os
import sys
import subprocess
import json
import tempfile
from pathlib import Path

def run_command(cmd, check=True, capture_output=True):
    """Run a shell command and return the result."""
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, check=check, capture_output=capture_output, text=True)
    if result.stdout:
        print(f"Output: {result.stdout.strip()}")
    if result.stderr:
        print(f"Error: {result.stderr.strip()}")
    return result

def generate_eddsa_signature(file_path, private_key):
    """Generate EdDSA signature for a file using Sparkle's sign_update tool."""
    try:
        # Check if sign_update is available
        which_result = run_command(['which', 'sign_update'], check=False)
        if which_result.returncode != 0:
            print("⚠️  sign_update not found. Attempting to use Python implementation...")
            return generate_eddsa_signature_python(file_path, private_key)
        
        # Create temporary file for private key
        with tempfile.NamedTemporaryFile(mode='w', suffix='.pem', delete=False) as temp_key:
            temp_key.write(private_key)
            temp_key_path = temp_key.name
        
        try:
            # Use Sparkle's sign_update tool
            result = run_command([
                'sign_update', 
                file_path,
                temp_key_path
            ])
            
            return result.stdout.strip()
            
        finally:
            # Clean up temporary key file
            os.unlink(temp_key_path)
            
    except subprocess.CalledProcessError as e:
        print(f"Error generating signature: {e}")
        return None

def generate_eddsa_signature_python(file_path, private_key):
    """
    Fallback Python implementation for EdDSA signature generation.
    This is a basic implementation - in production, use Sparkle's official tools.
    """
    try:
        import nacl.signing
        import nacl.encoding
        import base64
        
        # Parse private key (assuming it's base64 encoded)
        private_key_bytes = base64.b64decode(private_key.replace('-----BEGIN PRIVATE KEY-----', '')
                                          .replace('-----END PRIVATE KEY-----', '')
                                          .replace('\n', ''))
        
        # Create signing key
        signing_key = nacl.signing.SigningKey(private_key_bytes[:32])
        
        # Read file content
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        # Generate signature
        signature = signing_key.sign(file_content)
        
        # Return base64 encoded signature
        return base64.b64encode(signature.signature).decode('utf-8')
        
    except ImportError:
        print("⚠️  PyNaCl not available. Signature generation skipped.")
        return None
    except Exception as e:
        print(f"Error in Python signature generation: {e}")
        return None

def update_appcast_with_signatures(appcast_path, asset_signatures):
    """Update appcast XML with signature information."""
    try:
        with open(appcast_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Add signatures to enclosure tags
        for asset_name, signature in asset_signatures.items():
            if signature:
                # Find the enclosure tag for this asset
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if f'url=' in line and asset_name in line and 'enclosure' in line:
                        # Add signature attribute to the enclosure tag
                        if 'sparkle:edSignature=' not in line:
                            line = line.rstrip(' />')
                            line += f' sparkle:edSignature="{signature}" />'
                            lines[i] = line
                            break
                
                content = '\n'.join(lines)
        
        # Write updated content back
        with open(appcast_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Updated {appcast_path} with signatures")
        
    except Exception as e:
        print(f"Error updating appcast: {e}")

def main():
    """Main execution function."""
    # Get environment variables
    private_key = os.environ.get('SPARKLE_PRIVATE_KEY')
    if not private_key:
        print("⚠️  SPARKLE_PRIVATE_KEY environment variable not set. Skipping signature generation.")
        return 0
    
    # Get assets directory
    assets_dir = sys.argv[1] if len(sys.argv) > 1 else 'dist'
    assets_path = Path(assets_dir)
    
    if not assets_path.exists():
        print(f"❌ Assets directory {assets_dir} does not exist")
        return 1
    
    print(f"🔐 Generating signatures for assets in {assets_dir}")
    
    # Find ZIP and DMG files
    asset_signatures = {}
    
    for file_path in assets_path.glob('*.zip'):
        print(f"📦 Processing {file_path.name}")
        signature = generate_eddsa_signature(str(file_path), private_key)
        if signature:
            asset_signatures[file_path.name] = signature
            print(f"✅ Generated signature for {file_path.name}")
        else:
            print(f"⚠️  Could not generate signature for {file_path.name}")
    
    for file_path in assets_path.glob('*.dmg'):
        print(f"📦 Processing {file_path.name}")
        signature = generate_eddsa_signature(str(file_path), private_key)
        if signature:
            asset_signatures[file_path.name] = signature
            print(f"✅ Generated signature for {file_path.name}")
        else:
            print(f"⚠️  Could not generate signature for {file_path.name}")
    
    # Save signatures to JSON file for later use
    signatures_file = assets_path / 'signatures.json'
    with open(signatures_file, 'w') as f:
        json.dump(asset_signatures, f, indent=2)
    
    print(f"💾 Saved signatures to {signatures_file}")
    
    # Update appcast files if they exist
    docs_path = Path('docs')
    if docs_path.exists():
        for appcast_file in ['appcast.xml', 'appcast-beta.xml']:
            appcast_path = docs_path / appcast_file
            if appcast_path.exists():
                update_appcast_with_signatures(str(appcast_path), asset_signatures)
    
    print("🔐 Signature generation completed")
    return 0

if __name__ == '__main__':
    sys.exit(main())