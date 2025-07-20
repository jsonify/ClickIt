# Sparkle Auto-Update Setup Guide

This guide explains how to set up the auto-update system for ClickIt using the Sparkle framework.

## Overview

The auto-update system consists of:
- **Client Side**: Sparkle framework integrated into the app
- **Server Side**: GitHub Pages hosting appcast XML feeds
- **Security**: EdDSA signatures for release verification
- **Automation**: GitHub Actions for release and appcast generation

## 🔐 Security Setup

### 1. Generate EdDSA Key Pair

Run the key generation script:

```bash
python3 scripts/generate_eddsa_keys.py
```

This will generate:
- `sparkle_private_key.txt` - Keep this secure, used for signing releases
- `sparkle_public_key.txt` - Embed in your app for verification
- `github_secrets_setup.md` - Instructions for GitHub configuration

### 2. Configure GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings > Secrets and variables > Actions**
3. Click **"New repository secret"**
4. Add the following secret:
   - **Name**: `SPARKLE_PRIVATE_KEY`
   - **Value**: Contents of `sparkle_private_key.txt`

### 3. Update Info.plist Configuration

Add the following to your app's `Info.plist` or build script:

```xml
<!-- Sparkle Auto-Update Configuration -->
<key>SUFeedURL</key>
<string>https://yourusername.github.io/clickit/appcast.xml</string>

<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>

<key>SUEnableAutomaticChecks</key>
<true/>

<key>SUScheduledCheckInterval</key>
<integer>86400</integer>

<key>SUAllowsAutomaticUpdates</key>
<true/>
```

Replace:
- `yourusername` with your GitHub username
- `YOUR_PUBLIC_KEY_HERE` with the content from `sparkle_public_key.txt`

## 📡 Appcast Configuration

### Production Feed
- **URL**: `https://yourusername.github.io/clickit/appcast.xml`
- **Content**: Stable releases only
- **Updates**: Triggered by tags like `v1.0.0`

### Beta Feed  
- **URL**: `https://yourusername.github.io/clickit/appcast-beta.xml`
- **Content**: Pre-release versions
- **Updates**: Triggered by tags like `beta-v1.0.0-20250120`

## 🚀 Release Process

### Production Release
```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

This automatically:
1. Builds the app bundle
2. Creates ZIP and DMG files
3. Generates EdDSA signatures
4. Creates GitHub release
5. Updates production appcast
6. Deploys to GitHub Pages

### Beta Release
```bash
# Create and push a beta tag
git tag beta-v1.0.0-20250120
git push origin beta-v1.0.0-20250120
```

This automatically:
1. Builds the app bundle
2. Creates ZIP file
3. Generates EdDSA signatures
4. Creates pre-release on GitHub
5. Updates beta appcast
6. Deploys to GitHub Pages

## 🔍 Testing Updates

### 1. Enable GitHub Pages
1. Go to **Settings > Pages** in your repository
2. Select **Deploy from a branch**
3. Choose **gh-pages** branch
4. Set folder to **/ (root)**

### 2. Test Update Feeds
- Production: `https://yourusername.github.io/clickit/appcast.xml`
- Beta: `https://yourusername.github.io/clickit/appcast-beta.xml`
- Index: `https://yourusername.github.io/clickit/`

### 3. App Configuration
```swift
// UpdaterManager configuration
let updaterManager = UpdaterManager()

// For beta testing, set this to true:
updaterManager.checkForBetaUpdates = true

// Manually check for updates:
updaterManager.checkForUpdates()
```

## 🛡️ Security Best Practices

### Private Key Security
- ✅ Store private key in GitHub Secrets only
- ✅ Never commit private key to repository
- ✅ Use different keys for development/production
- ✅ Rotate keys periodically

### Signature Verification
- ✅ Always verify signatures in production
- ✅ Public key embedded in app bundle
- ✅ Reject unsigned updates
- ✅ Validate appcast SSL/TLS

### Release Security
- ✅ Sign all release assets
- ✅ Use HTTPS for all communications
- ✅ Validate update sources
- ✅ Implement rollback mechanisms

## 🐛 Troubleshooting

### Common Issues

**"No updates found"**
- Check appcast URL in Info.plist
- Verify GitHub Pages is enabled
- Ensure appcast.xml is accessible

**"Signature verification failed"**
- Verify public key in Info.plist matches private key
- Check that signatures are being generated
- Ensure SPARKLE_PRIVATE_KEY secret is set

**"Updates not triggering"**
- Check version comparison logic
- Verify tag format (v1.0.0 for production)
- Ensure automatic checks are enabled

### Debug Tools

```swift
// Enable verbose logging
updaterManager.updaterController.updater.sendsSystemProfile = false

// Check current configuration
print("Feed URL: \(updaterManager.updaterController.updater.feedURL)")
print("Auto-check enabled: \(updaterManager.autoUpdateEnabled)")
print("Current version: \(updaterManager.currentVersion)")
```

### Manual Testing

```bash
# Test signature generation locally
python3 scripts/generate_signatures.py dist

# Validate appcast XML
curl -s https://yourusername.github.io/clickit/appcast.xml | xmllint --format -

# Check release assets
ls -la dist/
cat dist/signatures.json
```

## 📋 Checklist

### Initial Setup
- [ ] Generate EdDSA key pair
- [ ] Configure GitHub Secrets
- [ ] Update Info.plist configuration
- [ ] Enable GitHub Pages
- [ ] Test appcast accessibility

### Before Each Release
- [ ] Update version numbers
- [ ] Test app functionality
- [ ] Verify build scripts work
- [ ] Check GitHub Actions are enabled

### After Each Release
- [ ] Verify GitHub release was created
- [ ] Check appcast was updated
- [ ] Test update mechanism
- [ ] Monitor for issues

## 📚 Additional Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [EdDSA Signatures](https://sparkle-project.org/documentation/security/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GitHub Pages](https://docs.github.com/en/pages)

---

🤖 Generated with [Claude Code](https://claude.ai/code)

For questions or issues, please check the [GitHub Issues](https://github.com/yourusername/clickit/issues) page.