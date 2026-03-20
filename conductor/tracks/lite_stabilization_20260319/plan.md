# Plan: ClickIt Lite Stabilization & Intel Removal

## Phase 1: Intel/Universal Binary Removal

- [x] Task: Remove x86_64 arch detection from `build_app_unified.sh`
- [x] Task: Remove `lipo` universal binary creation step from `build_app_unified.sh`
- [x] Task: Remove x86_64 from `build_app.sh` (legacy script)
- [x] Task: Update `.github/workflows/cicd.yml` to remove Intel arch from CI
- [x] Task: Update `README.md` — system requirements and build docs (arm64 only)
- [x] Task: Conductor - User Manual Verification 'Phase 1: Intel/Universal Binary Removal' (Protocol in workflow.md)

## Phase 2: ClickIt Lite Audit

- [x] Task: Read and document all Lite source files — identify bugs, rough edges, TODOs
- [x] Task: Verify ClickIt Lite builds successfully (`swift build --product ClickItLite`)
- [x] Task: Verify Lite app launches and core click loop functions on Apple Silicon
- [x] Task: Fix any critical bugs or crashes found during audit
- [x] Task: Document remaining known issues in `learnings.md`
- [x] Task: Conductor - User Manual Verification 'Phase 2: ClickIt Lite Audit' (Protocol in workflow.md)

## Phase 3: Test Coverage Baseline

- [!] Task: Run `swift test` and document current pass/fail state — BLOCKED: XCTest/Swift Testing unavailable without full Xcode app (CLT only installed)
- [!] Task: Identify untested Lite-specific code paths — BLOCKED: depends on working test run
- [!] Task: Write tests for critical untested Lite paths (target ≥80% Core coverage) — BLOCKED: no test framework available
- [!] Task: Ensure all tests pass on arm64 (`swift test`) — BLOCKED: no test framework available
- [!] Task: Conductor - User Manual Verification 'Phase 3: Test Coverage Baseline' (Protocol in workflow.md) — BLOCKED
