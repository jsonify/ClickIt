# Track Learnings: lite_stabilization_20260319

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

<!-- No patterns yet - this is the first track -->

---

<!-- Learnings from implementation will be appended below -->

## [2026-03-19] - Phase 2: Build Script & Launch Fixes

- **Implemented:** Fixed arg parsing bug in build script; added ad-hoc signing fallback; confirmed Lite launches and functions correctly on Apple Silicon
- **Files changed:** `build_app_unified.sh`
- **Commit:** b07c5d0
- **Learnings:**
  - Gotchas: macOS 26 (Sequoia) kills unsigned app bundles with `SIGKILL (Code Signature Invalid)` even for local debug builds — ad-hoc signing (`codesign --sign - --force --deep`) is required
  - Gotchas: `build_app_unified.sh` arg order is `BUILD_MODE BUILD_SYSTEM APP_VERSION` — passing `lite` as arg 2 was parsed as build system, not version
  - Patterns: Use value-based arg detection (check if arg is `lite`/`pro`) rather than position-based for optional args
---

## [2026-03-19] - Phase 2: ClickIt Lite Audit

- **Implemented:** Full audit of all 7 Lite source files; fixed 2 build issues
- **Files changed:** `SimplifiedMainView.swift` (preview macro), `Package.swift` (exclude README.md)
- **Commit:** dd177e6
- **Learnings:**
  - Patterns: `#Preview {}` macro requires Xcode's `PreviewsMacros` plugin — use `PreviewProvider` for SPM compatibility
  - Patterns: SPM warns on unhandled files (`.md`, etc.) in target paths — explicitly `exclude:` them in `Package.swift`
  - Gotchas: `SimpleViewModel.deinit` calls `stopMouseMonitoring()` but NOT `stopMonitoring()` — ESC/SPACE keyboard monitors leak on deinit (known issue, non-critical)
  - Gotchas: `SimpleCursorManager` is not `@MainActor` despite using UI APIs — works in practice but inconsistent with codebase style
  - Context: Lite build path is `Sources/ClickIt/Lite/`; resources live in `Sources/ClickIt/Lite/Resources/`
---

## [2026-03-19] - Phase 1: Intel/Universal Binary Removal

- **Implemented:** Removed x86_64 arch detection, lipo universal binary step, Intel CI matrix, and updated docs
- **Files changed:** `build_app_unified.sh`, `build_app.sh`, `.github/workflows/cicd.yml`, `README.md`
- **Commit:** 5ffcc6d
- **Learnings:**
  - Patterns: `build_app_unified.sh` uses `ARCH_LIST` array and a loop for multi-arch; simplifying to single-arch removes the loop entirely and sets `BUILD_PATH` once directly
  - Gotchas: Resource bundle copy loop also iterated `ARCH_LIST` — must simplify that too when removing multi-arch
  - Context: `build_app.sh` is the legacy script; `build_app_unified.sh` is the active one — both needed updating
---
