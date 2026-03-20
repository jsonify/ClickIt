# Plan: CI/CD Workflow Audit & Optimization

## Phase 1: Fix HighPrecisionTimer CI Noise
<!-- execution: parallel -->
<!-- depends: -->

- [x] Task: Find HighPrecisionTimer source file and timing error log call sites <!-- ea2177c -->
      <!-- files: Sources/ -->
- [x] Task: Add CI environment detection to suppress timing error output on CI <!-- ea2177c -->
      <!-- files: Sources/ -->
- [x] Task: Run `swift test` locally to confirm timing errors no longer appear <!-- ea2177c -->
- [x] Task: Commit with `fix(tests): suppress HighPrecisionTimer timing noise in CI` <!-- ea2177c -->
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Optimize ci.yml
<!-- execution: parallel -->
<!-- depends: -->

- [x] Task: Remove debug/release matrix — debug only for push/PR <!-- cdf9dfb -->
      <!-- files: .github/workflows/ci.yml -->
- [x] Task: Add .build cache step keyed on Package.resolved + Package.swift <!-- cdf9dfb -->
      <!-- files: .github/workflows/ci.yml -->
- [x] Task: Pin xcode-version to specific stable version instead of latest-stable <!-- cdf9dfb -->
      <!-- files: .github/workflows/ci.yml -->
- [x] Task: Fix test step — continue-on-error + GITHUB_STEP_SUMMARY annotation <!-- cdf9dfb -->
      <!-- files: .github/workflows/ci.yml -->
- [x] Task: Commit with `ci: optimize ci.yml — cache, single config, pin xcode` <!-- cdf9dfb -->
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: Consolidate Overlapping Workflows
<!-- execution: sequential -->
<!-- depends: phase2 -->

- [x] Task: Audit exact trigger overlap between ci.yml and cicd.yml <!-- eb77eea -->
- [x] Task: Designate ci.yml as single PR/push pipeline; strip redundant jobs from cicd.yml <!-- eb77eea -->
- [x] Task: Ensure cicd.yml retains only release-path jobs with tag-only triggers <!-- eb77eea -->
- [x] Task: Commit with `ci: consolidate overlapping workflow triggers` <!-- eb77eea -->
- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: Complete the Release Pipeline
<!-- execution: sequential -->
<!-- depends: phase3 -->

- [x] Task: Check/create scripts/generate_signatures.py for Ed25519 asset signing <!-- c270773 -->
      <!-- files: scripts/generate_signatures.py -->
- [x] Task: Fix deploy_appcast conditional logic (fires on either release succeeding) <!-- c270773 -->
      <!-- files: .github/workflows/cicd.yml -->
- [x] Task: Replace fragile sed version injection with robust env-var approach <!-- c270773 -->
      <!-- files: .github/workflows/release.yml, .github/workflows/cicd.yml -->
- [x] Task: Verify end-to-end release pipeline produces zip + dmg + GitHub Release + appcast <!-- c270773 -->
- [x] Task: Commit with `ci: complete release pipeline — signatures, appcast, deployment` <!-- c270773 -->
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
