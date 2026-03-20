# Spec: CI/CD Workflow Audit & Optimization

## Overview
Audit and optimize all three GitHub Actions workflows (`ci.yml`, `cicd.yml`, `release.yml`)
to reduce wall-clock time on every push/PR and establish a complete, reliable end-to-end
release pipeline (build → sign → release → appcast).

## Functional Requirements

### FR1: Eliminate Redundant Work in CI
- Remove the `debug + release` matrix from `ci.yml` — debug-only for push/PR is sufficient
- Add `.build` directory caching to `ci.yml` (currently absent, every run compiles from scratch)
- Pin Xcode version instead of `latest-stable` to avoid unpredictable setup delays

### FR2: Consolidate Overlapping Workflows
- `ci.yml` and `cicd.yml` both trigger on push to `main`, causing duplicate macOS runner
  spin-ups — reconcile into a single source of truth
- Share Xcode setup and cache across jobs where possible
- The `lint-and-quality` job should not spin up a full macOS runner for basic checks

### FR3: Fix and Complete the Release Workflow
- Verify `scripts/generate_signatures.py` exists; create it if missing
- Ensure the release pipeline produces: `.zip`, `.dmg`, Sparkle appcast XML, GitHub Release
- Fix the `deploy_appcast` job's conditional logic — it currently requires BOTH beta AND
  production release to succeed, but they trigger on mutually exclusive tag patterns
- Replace fragile `sed -i ''` version injection with a robust approach

### FR4: Reliable Test Step
- The current test step in `ci.yml` always exits 0 (silently swallows failures) — make test
  failures visible without blocking CI entirely (use `continue-on-error: true` with a
  clear summary annotation)

### FR5: Suppress HighPrecisionTimer Noise in CI
- The `HighPrecisionTimer` component emits a high volume of timing error lines during tests
  on GitHub-hosted runners (target: ~41.67ms, actual: ~6ms — runners lack real-time
  scheduling precision)
- These lines flood logs, slow output rendering, and make real failures hard to spot
- Fix: suppress or skip `HighPrecisionTimer` timing-error logging when running in CI
  (detect via `CI=true` env var), or mark those timing assertions as expected-skip on CI

## Non-Functional Requirements
- Target: reduce CI wall-clock time by ≥30% on a typical push to main
- Workflows must remain functional on `macos-15` GitHub-hosted runners
- No new third-party actions introduced without justification

## Acceptance Criteria
- [ ] A push to `main` triggers at most one macOS runner spin-up for build+test
- [ ] `.build` cache is hit on subsequent runs (verified via cache hit logs)
- [ ] Pushing a `v*` tag produces a complete GitHub Release with `.zip`, `.dmg`,
      and appcast XML deployed to GitHub Pages
- [ ] Test failures are surfaced in the CI summary rather than silently ignored
- [ ] `HighPrecisionTimer` timing error lines do not appear in CI test output
- [ ] All workflows complete in under 15 minutes on a warm cache

## Out of Scope
- Code signing with a paid Apple Developer certificate
- Notarization
- Adding new test coverage
- Changing the build script (`build_app_unified.sh`) internals
