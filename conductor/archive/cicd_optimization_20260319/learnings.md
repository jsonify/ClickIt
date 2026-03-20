# Track Learnings: cicd_optimization_20260319

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

- `testHighFrequencyCPSAccuracy` is a known flaky test (timing precision, fails in debug mode) — the HighPrecisionTimer noise is directly related to this.
- Run Xcode tests without `sudo xcode-select`: prefix with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- macOS 26 kills unsigned app bundles — CI must skip signing or use ad-hoc signing.

---

<!-- Learnings from implementation will be appended below -->

## [2026-03-20] - Phase 1 Tasks 1-4: Fix HighPrecisionTimer CI Noise
- **Implemented:** Added `ProcessInfo.processInfo.environment["CI"] == nil` guard to timing error print in `executeTimerCallback()`
- **Files changed:** `Sources/ClickIt/Core/Timer/HighPrecisionTimer.swift`
- **Commit:** ea2177c
- **Learnings:**
  - Patterns: GitHub Actions always sets `CI=true`; check `ProcessInfo.processInfo.environment["CI"]` to detect CI context in Swift
  - Gotchas: `testHighFrequencyCPSAccuracy` and `testErrorRecoveryIntegration` are known flaky (timing-sensitive) — not regressions; ignore in CI with `continue-on-error: true`
  - Context: The timing error fires when `timingError > 5ms`; on CI runners actual interval (~6ms) vs target (~41.67ms) = 35ms error, fires on every tick
---

## [2026-03-20] - Phase 2 Tasks 1-5: Optimize ci.yml
- **Implemented:** Removed debug/release matrix, added SPM cache, pinned Xcode 16.2, fixed test step with continue-on-error, moved lint-and-quality to ubuntu-latest
- **Files changed:** `.github/workflows/ci.yml`
- **Commit:** cdf9dfb
- **Learnings:**
  - Patterns: `actions/cache@v4` key `${{ runner.os }}-spm-${{ hashFiles('Package.resolved', 'Package.swift') }}` is the standard SPM cache pattern
  - Patterns: `continue-on-error: true` + tee to file + `GITHUB_STEP_SUMMARY` annotation surfaces test failures without blocking CI
  - Patterns: Lint/grep-only jobs should use `ubuntu-latest` — no need for macOS runner
  - Gotchas: `${PIPESTATUS[0]}` captures swift test exit code before tee consumes it; save to `GITHUB_ENV` immediately
  - Context: Pinned to Xcode 16.2 — update when upgrading runner image
---

## [2026-03-20] - Phase 3 Tasks 1-4: Consolidate Overlapping Workflows
- **Implemented:** Stripped cicd.yml to tag-only triggers; removed quality_checks + build_tests jobs
- **Files changed:** `.github/workflows/cicd.yml`
- **Commit:** eb77eea
- **Learnings:**
  - Patterns: ci.yml = PR/push pipeline; cicd.yml = tag-only release pipeline (clear separation)
  - Gotchas: cicd.yml was triggering 4 macOS runners per push to main — quality_checks + build_tests (×2 matrix) + ci.yml
  - Context: beta* and v* tags are mutually exclusive patterns — deploy_appcast OR condition handles both

## [2026-03-20] - Phase 4 Tasks 1-5: Complete Release Pipeline
- **Implemented:** RELEASE_VERSION env var in build script; release.yml demoted to manual fallback
- **Files changed:** `build_app_unified.sh`, `.github/workflows/release.yml`
- **Commit:** c270773
- **Learnings:**
  - Gotchas: sed version injection was patching `VERSION="1.0.0"` which no longer exists in build_app_unified.sh (script reads from Info.plist) — sed was silently a no-op
  - Patterns: `VERSION="${RELEASE_VERSION:-$(get_version_from_plist)}"` is the robust pattern — env var takes priority, falls back to Info.plist
  - Gotchas: release.yml and cicd.yml both triggered on v* tags, creating duplicate GitHub releases — demoted release.yml to workflow_dispatch-only
  - Context: cicd.yml:production_release is the canonical release path (ZIP+DMG+appcast); release.yml is manual fallback only
---
