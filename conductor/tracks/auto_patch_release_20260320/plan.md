# Plan: Auto Patch Release on Main Merge

## Phase 1: Implement Workflow

- [x] Task 1: Verify Info.plist path and fields
  - Confirm `ClickIt/Info.plist` exists and contains both
    `CFBundleShortVersionString` and `CFBundleVersion`
  - Note: path is referenced in fastlane/Fastfile — verify it's repo-relative

- [ ] Task 2: Create `.github/workflows/auto-release.yml`
  - Trigger: `on: push: branches: [main]`
  - Job-level guard: skip if commit message contains `[skip ci]`
    (prevents the workflow's own bump commit from re-triggering it)
  - Permissions: `contents: write`
  - Steps:
    1. Checkout with `fetch-depth: 0` (required for full tag history)
    2. Read latest `v*` semantic tag; default to `v0.0.0` if none exist
    3. Compute next patch version (`major.minor.(patch+1)`)
    4. Update `Info.plist` with `/usr/libexec/PlistBuddy`
       (both `CFBundleShortVersionString` and `CFBundleVersion`)
    5. Configure git identity: `github-actions[bot]`
    6. Commit Info.plist with message: `chore: bump version to vX.Y.Z [skip ci]`
    7. Push the commit to `main`
    8. Check if tag `vX.Y.Z` already exists; exit 0 if so
    9. Create and push tag `vX.Y.Z` → triggers `cicd.yml`

- [ ] Task 3: Update README.md Production Release section
  - Replace the "Legacy: Manual Release (Deprecated)" Fastlane block
    with a clear description of the new automatic behavior
  - Explain: merge to main → auto patch bump → tag → release pipeline

- [ ] Task: Conductor - User Manual Verification 'Implement Workflow'
  (Protocol in workflow.md)
