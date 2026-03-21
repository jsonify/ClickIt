# Track Learnings: datetime_scheduler_20260320

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

### Code Conventions
- Use `PreviewProvider` struct instead of `#Preview {}` macro — the macro requires Xcode's `PreviewsMacros` plugin and fails with `swift build`
- Explicitly `exclude:` non-source files (`.md`, `.txt`) from SPM targets in `Package.swift` to avoid unhandled file warnings

### Architecture
- `SimpleViewModel` is `@MainActor final class ObservableObject` — any new manager classes that publish state must be `@MainActor` too
- `package` access level (Swift 5.9) is used to share types across SPM targets within the same package — use `package` not `public` for Lite types
- SwiftUI `View` structs with `package` access must also declare `package var body`

### SwiftUI / macOS
- Use `NSApp.mainWindow` not `NSApp.keyWindow` when a floating overlay may be present

### Testing
- Test classes accessing `@MainActor`-isolated types must be annotated `@MainActor`, and async test functions must use `await fulfillment(of:)`
- 3 known flaky tests in the suite (not regressions): `testPatternBreakup`, `testHighFrequencyCPSAccuracy`, `testErrorRecoveryIntegration`
- Run tests with: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer .../XcodeDefault.xctoolchain/usr/bin/swift test --arch arm64`

### Gotchas
- macOS Sequoia kills unsigned app bundles — always ad-hoc sign debug builds: `codesign --sign - --force --deep <app.bundle>`

---

<!-- Learnings from implementation will be appended below -->

## [2026-03-21] - Phase 1 Task 1: Write tests for ScheduledClickManager
- **Implemented:** TDD red-phase tests covering all 5 spec scenarios
- **Files changed:** Tests/ClickItTests/ScheduledClickManagerTests.swift (created)
- **Commit:** 9715256
- **Learnings:**
  - Patterns: Lite-specific types live in `ClickItLiteUI` module — tests must use `@testable import ClickItLiteUI`, not `@testable import ClickIt`
  - Patterns: Test classes accessing `@MainActor` types must be `@MainActor`; async tests use `await fulfillment(of:timeout:)`
  - Gotchas: `ClickItTests` target originally only depended on `ClickIt` — needed `ClickItLiteUI` added as a dep to test Lite internals
---

## [2026-03-21] - Phase 3: UI Components + timing fix
- **Implemented:** schedulerSection with DatePicker, countdown (HH:mm:ss), Edit/Cancel, fire confirmation, seconds truncation fix
- **Files changed:** SimplifiedMainView.swift, ScheduledClickManager.swift, SimpleViewModel.swift
- **Commits:** 760c029, 939e74f, fee8ab4
- **Learnings:**
  - Gotchas: DatePicker with `.hourAndMinute` shows hour:minute only but `Date()` carries seconds — always truncate seconds to 0 before scheduling; initialize default with `nextMinute()` pattern
  - Patterns: `onFired` callback on manager is cleaner than observing transient `.fired` state via Combine (state resets synchronously before Combine emits)
  - Patterns: `switch viewModel.schedulerState { }` in SwiftUI cleanly drives idle vs scheduled vs fired UI states
  - Known limitation: 1-second Timer polling causes up to ~1s scheduling jitter — future track to replace with DispatchSourceTimer for sub-millisecond precision
---

## [2026-03-21] - Phase 2 Task 1: Write SimpleViewModel scheduler tests
- **Implemented:** TDD red-phase tests for ViewModel scheduler integration
- **Files changed:** Tests/ClickItTests/SimpleViewModelSchedulerTests.swift (created)
- **Commit:** 724c4be
- **Learnings:**
  - Gotchas: `scheduleClick` with a permission guard returns early in test env (no accessibility permission), swallowing the throw — don't guard permission before validation logic
  - Patterns: For `@MainActor` types, Combine `assign(to:)` propagates synchronously on the main actor — no `await` needed in tests to see updated state

---

## [2026-03-21] - Phase 2 Task 2: Integrate ScheduledClickManager into SimpleViewModel
- **Implemented:** Added ScheduledClickManager to SimpleViewModel with Combine bindings and public scheduler methods
- **Files changed:** Sources/ClickIt/Lite/SimpleViewModel.swift
- **Commit:** 953c2d4
- **Learnings:**
  - Patterns: `publisher.assign(to: &$publishedProperty)` in `@MainActor` init syncs two `@Published` properties without needing a stored `AnyCancellable`
  - Patterns: Permission checks belong at EXECUTION time (fire), not at SCHEDULING time (picking a date) — scheduling is a pure data operation
---
- **Implemented:** Full `ScheduledClickManager` — state machine, Timer-based countdown, injectable click action, coordinate conversion
- **Files changed:** Sources/ClickIt/Lite/ScheduledClickManager.swift (created), Package.swift (ClickItLiteUI dep + ClickItLite exclude), Tests/ClickItTests/ScheduledClickManagerTests.swift (import fix)
- **Commit:** bb35f7f
- **Learnings:**
  - Gotchas: Default parameter expressions in Swift cannot call `@MainActor` methods — use `nonisolated` + `MainActor.assumeIsolated` pattern for static defaults
  - Patterns: `nonisolated` static func with `MainActor.assumeIsolated { }` is safe when the func is always called from a `@MainActor` call site
  - Gotchas: Every new `.swift` file added to `Sources/ClickIt/Lite/` must be added to the `ClickItLite` target's `exclude:` list in `Package.swift` — otherwise SPM reports "overlapping sources"
  - Patterns: `@testable import` only exposes internals of the directly-named module, NOT transitive dependencies (e.g., `@testable import ClickIt` doesn't expose `ClickItLiteUI` internals)
---
