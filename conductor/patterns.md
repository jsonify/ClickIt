# Codebase Patterns

Reusable patterns discovered during development. Read this before starting new work.

## Code Conventions
- Use `PreviewProvider` struct instead of `#Preview {}` macro — the macro requires Xcode's `PreviewsMacros` plugin and fails with `swift build` (from: lite_stabilization_20260319, 2026-03-19)
- Explicitly `exclude:` non-source files (`.md`, `.txt`) from SPM targets in `Package.swift` to avoid unhandled file warnings (from: lite_stabilization_20260319, 2026-03-19)

## Architecture
<!-- Patterns will be added as tracks are completed -->

## Gotchas
- macOS 26 (Sequoia) kills unsigned app bundles with `SIGKILL (Code Signature Invalid)` even for local debug builds — always ad-hoc sign with `codesign --sign - --force --deep <app.bundle>` when no developer cert is available (from: lite_stabilization_20260319, 2026-03-19)
- Mock drift: when a struct adds fields, mocks using its initializer break silently until next build — audit mocks when changing structs with many fields (from: lite_stabilization_20260319, 2026-03-19)
- Build script arg parsing: `build_app_unified.sh` arg order is `BUILD_MODE BUILD_SYSTEM APP_VERSION` — passing `lite` as arg 2 was parsed as build system; fixed with value-based detection (from: lite_stabilization_20260319, 2026-03-19)

## Testing
- Swift 6 strict concurrency: test classes that access `@MainActor`-isolated types must be annotated `@MainActor`, and test functions using `await fulfillment(of:)` must be `async` (from: lite_stabilization_20260319, 2026-03-19)
- Run Xcode tests without `sudo xcode-select`: prefix with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` and use full toolchain path `...Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test` (from: lite_stabilization_20260319, 2026-03-19)
- 2 known flaky tests in the suite: `testPatternBreakup` (random boundary condition) and `testHighFrequencyCPSAccuracy` (timing precision, fails in debug mode) — not regressions (from: lite_stabilization_20260319, 2026-03-19)

---
Last refreshed: 2026-03-19
