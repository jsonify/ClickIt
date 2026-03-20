# ClickIt Build & Deploy Guide

## Quick Start

```bash
# Local development build + launch
fastlane launch            # Pro version
fastlane launch_lite       # Lite version

# Release (let CI do the work)
fastlane bump_and_release bump:patch   # bump version, tag, push → CI handles the rest
```

---

## Local Development Commands

| Command | Description |
|---------|-------------|
| `fastlane build_debug` | Debug build (Pro) |
| `fastlane build_release` | Release build (Pro) |
| `fastlane build_lite_debug` | Debug build (Lite) |
| `fastlane build_lite_release` | Release build (Lite) |
| `fastlane launch` | Build debug + launch (Pro) |
| `fastlane launch_lite` | Build debug + launch (Lite) |
| `fastlane clean` | Remove `dist/` artifacts |
| `fastlane verify_signing` | Check code signing status |
| `fastlane info` | Show app bundle info |
| `make build` | Quick SPM debug build |
| `make test` | Run test suite |
| `make clean` | Clean build artifacts |

---

## Build Versions (Pro vs Lite)

| Target | App Name | Bundle ID | Entry Point |
|--------|----------|-----------|-------------|
| `ClickIt` | `ClickIt.app` | `com.jsonify.clickit` | `ClickItApp.swift` |
| `ClickItLite` | `ClickIt Lite.app` | `com.jsonify.clickit.lite` | `ClickItLiteApp.swift` |

Both targets are defined in `Package.swift`. Each excludes the other's entry point — no file modification needed during builds.

```bash
./build_app_unified.sh [BUILD_MODE] [BUILD_SYSTEM] [APP_VERSION]
# Examples:
./build_app_unified.sh debug spm pro
./build_app_unified.sh release spm lite
```

---

## Release Workflow

**Pushing a tag is all that's needed.** CI handles building, packaging, and publishing.

### Production release (`v*` tag)

```bash
# Option A — recommended (bumps version, tags, pushes)
fastlane bump_and_release bump:patch   # or: bump:minor, bump:major

# Option B — manual tag
git tag v1.5.6 && git push origin v1.5.6
```

What CI does automatically (`cicd.yml:production_release`):
1. Builds release app bundle
2. Creates ZIP + DMG in `dist/`
3. Generates Ed25519 signatures (if `SPARKLE_PRIVATE_KEY` secret is set)
4. Creates GitHub Release with both artifacts
5. Generates `appcast.xml` and deploys to GitHub Pages (`gh-pages`)

### Beta release (`beta*` tag)

```bash
# Option A — recommended
fastlane auto_beta version:1.5.6   # must be on staging branch

# Option B — manual tag
git tag beta-v1.5.6-$(date +%Y%m%d) && git push origin --tags
```

What CI does automatically (`cicd.yml:beta_release`):
1. Builds release app bundle
2. Creates ZIP
3. Creates GitHub pre-release
4. Generates `appcast-beta.xml` and deploys to GitHub Pages

### Tag patterns

```
v1.0.0, v1.1.0, v2.0.0          # production releases
beta-v1.0.0-20260320             # beta pre-releases
```

---

## CI/CD Pipeline

### On push to `main` / PR (ci.yml)

One macOS runner:
- SPM cache restored (keyed on `Package.resolved + Package.swift`)
- Xcode 16.2 (pinned)
- `swift test` with `continue-on-error: true` — failures appear in Step Summary, don't block CI
- Debug app bundle build + verify
- Upload debug artifact

Lint/security checks run on `ubuntu-latest` (no macOS runner needed).

### On `v*` / `beta*` tag (cicd.yml)

Only the matching job runs — the other is skipped:

| Tag | Job | Output |
|-----|-----|--------|
| `v*` | `production_release` | ZIP + DMG + GitHub Release + appcast.xml |
| `beta*` | `beta_release` | ZIP + GitHub pre-release + appcast-beta.xml |

`deploy_appcast` runs after whichever release job succeeded and pushes to GitHub Pages.

### release.yml — manual fallback only

`release.yml` is `workflow_dispatch`-only. Use it if `cicd.yml` fails and you need to manually re-run a release. It does **not** auto-trigger on tags.

---

## Version Management

Version is read from `ClickIt/Info.plist` (`CFBundleShortVersionString`) at build time.

CI release jobs set `RELEASE_VERSION` from the tag, which takes priority over Info.plist:
```bash
export RELEASE_VERSION="1.5.6"
./build_app_unified.sh release spm
```

To sync Info.plist with the latest GitHub release (after bumping via Fastlane):
```bash
fastlane sync_version_with_github
```

To validate sync:
```bash
fastlane validate_github_sync
```

---

## Code Signing

### Local development
Fastlane automatically applies ad-hoc signing (`codesign --sign -`) if no developer certificate is found. macOS 26+ requires at least ad-hoc signing to run.

```bash
# Check available certificates
security find-identity -v -p codesigning
```

### CI
CI builds use `CODE_SIGN_IDENTITY=""` (unsigned). macOS 26+ kills unsigned bundles with `SIGKILL (Code Signature Invalid)` — if distributing locally, always ad-hoc sign after downloading.

For Sparkle update signatures, set the `SPARKLE_PRIVATE_KEY` GitHub secret. Without it, signature generation is skipped gracefully.

---

## Troubleshooting

```bash
# Tests failing locally
make test

# Cache issues — force clean rebuild
rm -rf .build && swift build

# Version out of sync
fastlane validate_github_sync
fastlane sync_version_with_github

# GitHub CLI not authenticated
gh auth login && gh auth status

# Check CI status
gh run list --limit 5
gh run view <run-id>
```
