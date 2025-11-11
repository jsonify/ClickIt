# Release Process with Release Please

## Overview

ClickIt uses [Release Please](https://github.com/googleapis/release-please) to automate version management and releases. Release Please automatically:

- 📝 Generates changelogs based on conventional commits
- 🔢 Bumps version numbers in `ClickIt/Info.plist`
- 🏷️ Creates git tags
- 📦 Creates GitHub releases
- 🔄 Updates `CHANGELOG.md`

## How It Works

### 1. Conventional Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) format for your commit messages:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types that trigger releases:**
- `feat:` - New feature (bumps minor version)
- `fix:` - Bug fix (bumps patch version)
- `feat!:` or `fix!:` - Breaking change (bumps major version)
- `perf:` - Performance improvement (bumps patch version)

**Other types (included in changelog but don't trigger releases):**
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Test updates
- `chore:` - Maintenance tasks
- `ci:` - CI/CD changes
- `build:` - Build system changes

**Examples:**
```bash
git commit -m "feat: add click interval presets"
git commit -m "fix: correct emergency stop behavior"
git commit -m "feat!: redesign UI with new navigation"
git commit -m "perf: optimize click timing accuracy"
```

### 2. Release Please Workflow

When you push commits to `main`:

1. **Release Please analyzes commits** since the last release
2. **Creates/updates a Release PR** with:
   - Updated `CHANGELOG.md`
   - Bumped version in `ClickIt/Info.plist`
   - Updated `.release-please-manifest.json`
3. **When you merge the Release PR:**
   - Creates a git tag (e.g., `v1.6.0`)
   - Creates a GitHub release with changelog
   - Triggers the build workflow to attach binaries

### 3. Build Workflow

The build workflow (`.github/workflows/release.yml`):

1. Triggered by the tag created by Release Please
2. Builds the universal macOS app bundle
3. Creates `.zip` archive
4. Uploads artifacts to the GitHub release

## Creating a Release

### Standard Release (Recommended)

1. **Make changes using conventional commits:**
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git commit -m "feat: add new click pattern"
   git push origin feature/new-feature
   ```

2. **Create and merge PR to main:**
   - Open PR on GitHub
   - Get code review
   - Merge to `main`

3. **Release Please creates a Release PR:**
   - Automatically created after merge to `main`
   - Reviews version bump and changelog
   - Title: "chore(main): release X.Y.Z"

4. **Review and merge the Release PR:**
   - Check the version bump is correct
   - Review the generated changelog
   - Merge when ready to release

5. **Automated release process:**
   - Tag created automatically
   - GitHub release created with changelog
   - Build workflow triggered
   - Binaries uploaded to release

### Manual Release (Emergency)

If you need to create a release manually:

1. **Update version in Info.plist:**
   ```bash
   /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString 1.6.0" ClickIt/Info.plist
   ```

2. **Update manifest:**
   ```bash
   echo '{ ".": "1.6.0" }' > .release-please-manifest.json
   ```

3. **Commit and tag:**
   ```bash
   git add ClickIt/Info.plist .release-please-manifest.json CHANGELOG.md
   git commit -m "chore: release 1.6.0"
   git tag v1.6.0
   git push origin main
   git push origin v1.6.0
   ```

## Version Bumping Rules

Release Please determines version bumps based on commit types:

| Commit Type | Version Bump | Example |
|------------|--------------|---------|
| `fix:` | Patch (1.5.5 → 1.5.6) | Bug fixes |
| `feat:` | Minor (1.5.5 → 1.6.0) | New features |
| `feat!:` or `fix!:` | Major (1.5.5 → 2.0.0) | Breaking changes |
| `perf:` | Patch (1.5.5 → 1.5.6) | Performance |

**Breaking Changes:**
- Add `!` after type: `feat!:` or `fix!:`
- Or add `BREAKING CHANGE:` in commit footer

## Beta Releases

Beta releases still use the manual tag approach:

```bash
git tag beta-v1.6.0-20250111
git push origin beta-v1.6.0-20250111
```

Beta releases trigger the `beta_release` job in `cicd.yml`.

## Configuration Files

- `.release-please-manifest.json` - Current version tracking
- `release-please-config.json` - Release Please configuration
- `CHANGELOG.md` - Auto-generated changelog
- `ClickIt/Info.plist` - App version file, updated by Release Please

## Troubleshooting

### Release PR not created

- Check that commits follow conventional commit format
- Ensure commits were pushed to `main` branch
- Check GitHub Actions logs for release-please workflow

### Wrong version bump

- Review commit messages for types
- Breaking changes need `!` or `BREAKING CHANGE:` footer
- Manually edit the Release PR if needed

### Build failed

- Check release workflow logs in GitHub Actions
- Verify Xcode version compatibility
- Check build script: `build_app_unified.sh`

## Migration from Manual Releases

The old manual process (`scripts/update-version.sh`) is deprecated but still available for emergencies. The new process is:

**Old:** Manual script → Manual tag → Release workflow
**New:** Conventional commits → Release Please PR → Auto tag → Release workflow

## Resources

- [Release Please Documentation](https://github.com/googleapis/release-please)
- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
