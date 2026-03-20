# Track Learnings: auto_patch_release_20260320

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

- CI/CD separation: `ci.yml` = PR/push pipeline (build+test); `cicd.yml` = tag-only release pipeline (`v*` → production, `beta*` → beta) — never mix the two concerns
- SPM cache key: `${{ runner.os }}-spm-${{ hashFiles('Package.resolved', 'Package.swift') }}` with `restore-keys: ${{ runner.os }}-spm-`
- Lint/grep-only CI jobs should use `ubuntu-latest`, not `macos-15`
- Shell script version override pattern: `VERSION="${RELEASE_VERSION:-$(get_version_from_plist)}"` — env var takes priority, falls back to Info.plist

---

<!-- Learnings from implementation will be appended below -->

## [2026-03-20] - Phase 1 Task 1: Verify Info.plist path and fields
- **Implemented:** Confirmed source Info.plist at `ClickIt/Info.plist` (repo root–relative)
- **Files changed:** none (verification only)
- **Commit:** 7062eb1
- **Learnings:**
  - Patterns: Info.plist is at `ClickIt/Info.plist`, not `Sources/`
  - Gotchas: `CFBundleVersion` = `$(CURRENT_PROJECT_VERSION)` — Xcode build variable; do NOT overwrite it in CI. Only `CFBundleShortVersionString` should be updated.
  - Context: Fastlane's `sync_version_with_github` lane only updates `CFBundleShortVersionString`, confirming this is the right field.
---

## [2026-03-20] - Phase 1 Task 2: Create auto-release.yml
- **Implemented:** New `.github/workflows/auto-release.yml` — triggers on push to main, bumps patch, updates Info.plist, commits [skip ci], pushes tag
- **Files changed:** `.github/workflows/auto-release.yml`
- **Commit:** 0e8c466
- **Learnings:**
  - Gotchas: `GITHUB_TOKEN` pushes do NOT trigger other workflows (GitHub anti-loop). A PAT (`RELEASE_TOKEN`) is required for the tag push to trigger `cicd.yml`.
  - Patterns: Use `ubuntu-latest` + Python `plistlib` to edit XML plists without a macOS runner — saves ~10x runner cost.
  - Patterns: `[skip ci]` in commit message + `if: "!contains(..., '[skip ci]')"` on the job is the correct guard against recursive workflow triggering.
  - Context: `sort -V` for semantic version sorting; `git ls-remote --tags` to check remote tag existence before pushing.
---

## [2026-03-20] - Phase 1 Task 3: Update README.md
- **Implemented:** Replaced outdated Release Please + deprecated Fastlane sections with auto-release flow diagram and RELEASE_TOKEN setup instructions
- **Files changed:** `README.md`
- **Commit:** 8814255
- **Learnings:**
  - Context: README had references to Release Please (not used) and deprecated `fastlane bump_and_release` — both needed replacing.
---
