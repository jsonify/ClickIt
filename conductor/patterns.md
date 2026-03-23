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
- Use `ubuntu-latest` + Python `plistlib` to edit XML `.plist` files in CI — avoids macOS runner cost; `plistlib.dump(plist, f, fmt=plistlib.FMT_XML)` preserves XML format (from: auto_patch_release_20260320, 2026-03-20)
- `GITHUB_TOKEN` pushes do NOT trigger other workflows (GitHub anti-loop protection) — use a PAT (e.g. `RELEASE_TOKEN` secret) when a workflow push/tag needs to trigger a downstream workflow like a release pipeline (from: auto_patch_release_20260320, 2026-03-20)
- Prevent recursive workflow triggering: add `[skip ci]` to the bot commit message AND add `if: "!contains(github.event.head_commit.message, '[skip ci]')"` to the job condition (from: auto_patch_release_20260320, 2026-03-20)
- Detect GitHub Actions in Swift: `ProcessInfo.processInfo.environment["CI"] == nil` — GitHub Actions always sets `CI=true`; use this to suppress CI-unfriendly logging (from: cicd_optimization_20260319, 2026-03-20)
- Shell script version override pattern: `VERSION="${RELEASE_VERSION:-$(get_version_from_plist)}"` — env var takes priority, falls back to Info.plist; set `RELEASE_VERSION` from the git tag in CI (from: cicd_optimization_20260319, 2026-03-20)

## Info.plist
- Source `Info.plist` is at `ClickIt/Info.plist` (repo-root-relative). Only update `CFBundleShortVersionString` in CI — `CFBundleVersion` is `$(CURRENT_PROJECT_VERSION)`, an Xcode build variable that must not be overwritten (from: auto_patch_release_20260320, 2026-03-20)

## SwiftUI Window Management (macOS)
- **In-place mode switching**: For single-window apps that swap content based on a mode, use `@AppStorage` + `switch` in the root view body. Resize the window in `onChange` via `NSApp.mainWindow?.setContentSize()` + `center()`. Never use `openWindow(id:)` + `dismiss()` — `openWindow` always spawns a *new* `WindowGroup` instance and combining it with `dismiss` causes a double-window race condition. (from: pro_lite_switcher_20260320, 2026-03-20)
- **`NSApp.keyWindow` is unreliable** when a floating overlay window (e.g. `VisualFeedbackOverlay`) is present — it returns the overlay, not the main window. Use `NSApp.mainWindow` instead. (from: pro_lite_switcher_20260320, 2026-03-20)
- **`@Environment` in `CommandMenu`**: To access `@Environment` values (like `openWindow`, `dismiss`) inside a `CommandMenu`, wrap the content in a private `View` struct — closures in `CommandMenu` don't participate in SwiftUI environment injection. (from: pro_lite_switcher_20260320, 2026-03-20)

## SPM Multi-Target Sharing
- **Swift 5.9 `package` access level**: Use `package` instead of `public` to share types across targets within the same SPM package. All targets in a package compile with `-package-name <name>`, so `package` types are visible across modules without the overhead of `public`. (from: pro_lite_switcher_20260320, 2026-03-20)
- **SwiftUI `View` access level**: If a struct is `package`, its `var body` must also be `package` — SwiftUI's `View` protocol requires `body` to match the enclosing type's access level. (from: pro_lite_switcher_20260320, 2026-03-20)
- **Partitioning one directory into multiple SPM targets**: Use `exclude:` lists in `Package.swift` to assign disjoint file sets to different targets that share the same `path`. (from: pro_lite_switcher_20260320, 2026-03-20)
- **New `Lite/` source files must be excluded from `ClickItLite` target**: Every `.swift` file added to `Sources/ClickIt/Lite/` must be added to the `exclude:` list in the `ClickItLite` executableTarget in `Package.swift` — otherwise SPM reports "overlapping sources" at build time. (from: datetime_scheduler_20260320, 2026-03-21)
- **Testing `ClickItLiteUI` internals**: Use `@testable import ClickItLiteUI` (not `@testable import ClickIt`) and add `ClickItLiteUI` to `ClickItTests` dependencies in `Package.swift` — `@testable import` only exposes internals of the directly-named module, not transitive dependencies. (from: datetime_scheduler_20260320, 2026-03-21)

## SwiftUI Date/Time Pickers
- **Truncate seconds for `DatePicker` with `.hourAndMinute`**: The picker displays only hour:minute, but `Date()` carries seconds. Always zero out seconds before scheduling: extract `[.year, .month, .day, .hour, .minute]` components and set `second = 0`. Initialize picker defaults with a `nextMinute()` helper (same truncation) so displayed time matches fired time. (from: datetime_scheduler_20260320, 2026-03-21)

## Swift Actor Isolation
- **`nonisolated` + `MainActor.assumeIsolated` for static defaults**: Default parameter expressions cannot call `@MainActor` methods. Mark the static method `nonisolated` and wrap the AppKit/UIKit calls in `MainActor.assumeIsolated { }` — safe when the method is always invoked from an `@MainActor` call site. (from: datetime_scheduler_20260320, 2026-03-21)
- **`onFired` callback over Combine for transient state**: If a state transition (e.g. `.fired`) is set and immediately reset in the same synchronous call, Combine subscribers won't see it — the value is already overwritten before the publisher fires. Use an explicit callback property (`var onFired: (() -> Void)?`) instead. (from: datetime_scheduler_20260320, 2026-03-21)

## Gotchas
- macOS 26 (Sequoia) kills unsigned app bundles with `SIGKILL (Code Signature Invalid)` even for local debug builds — always ad-hoc sign with `codesign --sign - --force --deep <app.bundle>` when no developer cert is available (from: lite_stabilization_20260319, 2026-03-19)
- Mock drift: when a struct adds fields, mocks using its initializer break silently until next build — audit mocks when changing structs with many fields (from: lite_stabilization_20260319, 2026-03-19)
- Build script arg parsing: `build_app_unified.sh` arg order is `BUILD_MODE BUILD_SYSTEM APP_VERSION` — passing `lite` as arg 2 was parsed as build system; fixed with value-based detection (from: lite_stabilization_20260319, 2026-03-19)
- **GCD unresumed DispatchSource crash**: calling `DispatchSource.makeTimerSource(queue:)` and letting the variable go out of scope without calling `.resume()` (or `.cancel()`) causes a SIGTRAP at deallocation. Every created `DispatchSourceTimer` must be either resumed (stored and resumed) or explicitly cancelled before it is discarded. (from: litescheduler_20260321, 2026-03-21)

## Testing
- Swift 6 strict concurrency: test classes that access `@MainActor`-isolated types must be annotated `@MainActor`, and test functions using `await fulfillment(of:)` must be `async` (from: lite_stabilization_20260319, 2026-03-19)
- Run Xcode tests without `sudo xcode-select`: prefix with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` and use full toolchain path `...Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test` (from: lite_stabilization_20260319, 2026-03-19)
- 3 known flaky tests in the suite: `testPatternBreakup` (random boundary condition), `testHighFrequencyCPSAccuracy` (timing precision, fails in debug mode), `testErrorRecoveryIntegration` (timing-sensitive) — not regressions (from: lite_stabilization_20260319 + cicd_optimization_20260319, 2026-03-20)

## SwiftUI @Observable
- **`@Observable` class property can be `let` on a ViewModel** — no `@Published` needed; SwiftUI tracks changes through the `@Observable` macro automatically (from: timingdiag_20260321, 2026-03-23)
- **Expose computed display properties as `internal` (not `private`) on SwiftUI views** — allows tests to assert on derived state (e.g. `badgeSeverity`) without needing a renderer or snapshot framework (from: timingdiag_20260321, 2026-03-23)
- **`TabView` adds ~40px chrome** — adjust window frame when introducing tabs to an existing fixed-size window (from: timingdiag_20260321, 2026-03-23)

## SPM Multi-Target Sharing (additions)
- **New Lite/ subdirectory: exclude by directory name in `ClickItLite` target**, not individual files — e.g. `"TimingDiagnostic"` covers all files added later without further `Package.swift` edits (from: timingdiag_20260321, 2026-03-23)

## Timing & Precision
- **Capture `Date()` as the very first line of a timing-sensitive handler** — any timer cancellation or nil-clearing before the capture adds measurable nanoseconds to the recorded delta (from: timingdiag_20260321, 2026-03-23)

## Testing
- **Integration tests for scheduler callbacks: use `LiteScheduler` directly** (not `ScheduledClickManager`) to avoid needing Accessibility permissions in CI — permissions are only checked at click-fire time, not at schedule time (from: timingdiag_20260321, 2026-03-23)

---
Last refreshed: 2026-03-23 (timingdiag_20260321)
