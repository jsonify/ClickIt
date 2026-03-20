# Codebase Patterns

Reusable patterns discovered during development. Read this before starting new work.

## Code Conventions
- Use `PreviewProvider` struct instead of `#Preview {}` macro — the macro requires Xcode's `PreviewsMacros` plugin and fails with `swift build` (from: lite_stabilization_20260319, 2026-03-19)
- Explicitly `exclude:` non-source files (`.md`, `.txt`) from SPM targets in `Package.swift` to avoid unhandled file warnings (from: lite_stabilization_20260319, 2026-03-19)

## Architecture
- CI/CD separation: `ci.yml` = PR/push pipeline (build+test); `cicd.yml` = tag-only release pipeline (`v*` → production, `beta*` → beta) — never mix the two concerns (from: cicd_optimization_20260319, 2026-03-20)

## CI/CD
- SPM cache key: `${{ runner.os }}-spm-${{ hashFiles('Package.resolved', 'Package.swift') }}` with `restore-keys: ${{ runner.os }}-spm-` — standard pattern for GitHub Actions (from: cicd_optimization_20260319, 2026-03-20)
- Lint/grep-only CI jobs should use `ubuntu-latest`, not `macos-15` — macOS runners are ~10× more expensive and unnecessary for shell/static checks (from: cicd_optimization_20260319, 2026-03-20)
- Detect GitHub Actions in Swift: `ProcessInfo.processInfo.environment["CI"] == nil` — GitHub Actions always sets `CI=true`; use this to suppress CI-unfriendly logging (from: cicd_optimization_20260319, 2026-03-20)
- Shell script version override pattern: `VERSION="${RELEASE_VERSION:-$(get_version_from_plist)}"` — env var takes priority, falls back to Info.plist; set `RELEASE_VERSION` from the git tag in CI (from: cicd_optimization_20260319, 2026-03-20)

## Gotchas
- macOS 26 (Sequoia) kills unsigned app bundles with `SIGKILL (Code Signature Invalid)` even for local debug builds — always ad-hoc sign with `codesign --sign - --force --deep <app.bundle>` when no developer cert is available (from: lite_stabilization_20260319, 2026-03-19)
- Mock drift: when a struct adds fields, mocks using its initializer break silently until next build — audit mocks when changing structs with many fields (from: lite_stabilization_20260319, 2026-03-19)
- Build script arg parsing: `build_app_unified.sh` arg order is `BUILD_MODE BUILD_SYSTEM APP_VERSION` — passing `lite` as arg 2 was parsed as build system; fixed with value-based detection (from: lite_stabilization_20260319, 2026-03-19)

## Testing
- Swift 6 strict concurrency: test classes that access `@MainActor`-isolated types must be annotated `@MainActor`, and test functions using `await fulfillment(of:)` must be `async` (from: lite_stabilization_20260319, 2026-03-19)
- Run Xcode tests without `sudo xcode-select`: prefix with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` and use full toolchain path `...Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test` (from: lite_stabilization_20260319, 2026-03-19)
- 3 known flaky tests in the suite: `testPatternBreakup` (random boundary condition), `testHighFrequencyCPSAccuracy` (timing precision, fails in debug mode), `testErrorRecoveryIntegration` (timing-sensitive) — not regressions (from: lite_stabilization_20260319 + cicd_optimization_20260319, 2026-03-20)

---
Last refreshed: 2026-03-20
