# Track Learnings: litescheduler_20260321

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

- **SPM exclude list**: New `Lite/` source files must be added to `ClickItLite` target's
  `exclude:` list in `Package.swift` — otherwise SPM reports "overlapping sources" at build time.
  (from: patterns.md)

- **Testing `ClickItLiteUI` internals**: Use `@testable import ClickItLiteUI` (not
  `@testable import ClickIt`) and add `ClickItLiteUI` to `ClickItTests` dependencies in
  `Package.swift`. (from: patterns.md)

- **Swift 6 strict concurrency**: Test classes that access `@MainActor`-isolated types
  must be annotated `@MainActor`; test functions using `await fulfillment(of:)` must be
  `async`. (from: patterns.md)

- **`nonisolated` + `MainActor.assumeIsolated`**: Default parameter expressions cannot
  call `@MainActor` methods — mark static method `nonisolated` and wrap calls in
  `MainActor.assumeIsolated { }`. (from: patterns.md)

- **`onFired` callback over Combine for transient state**: If a state transition is set
  and immediately reset in the same synchronous call, use an explicit callback property
  rather than a Combine publisher. (from: patterns.md)

- **3 known flaky tests**: `testPatternBreakup`, `testHighFrequencyCPSAccuracy`,
  `testErrorRecoveryIntegration` — not regressions, pre-existing. (from: patterns.md)

---

## [2026-03-21] - Phase 2 Task 2+3: Refactor ScheduledClickManager + update callers
- **Implemented:** Replaced Timer with LiteScheduler; renamed onFired→executionHandler; updated SimpleViewModel
- **Files changed:** Sources/ClickIt/Lite/ScheduledClickManager.swift, Sources/ClickIt/Lite/SimpleViewModel.swift
- **Commit:** f2f8ff6
- **Learnings:**
  - Patterns: Set `countdown = date.timeIntervalSinceNow` synchronously in `schedule(at:)` before wiring the async `countdownUpdateHandler` — this keeps the initial value correct for tests that check it immediately after scheduling.
  - Gotchas: `SimpleViewModel` was the only `onFired` caller outside of tests; a codebase grep before starting saves surprises mid-task.
  - Context: `LiteScheduler.executionHandler` fires via `DispatchQueue.main.async`; `ScheduledClickManager.fire()` must be `@MainActor`-safe (it is, since it only mutates `@Published` properties and calls the callback).
---

<!-- Learnings from implementation will be appended below -->

## [2026-03-21] - Phase 1 Task 3: Implement LiteScheduler.swift
- **Implemented:** 4-timer LiteScheduler with main-wait, final-countdown (10ms), drift-comp (60s), countdown (1s)
- **Files changed:** Sources/ClickIt/Lite/LiteScheduler.swift, Package.swift
- **Commit:** e455cc5
- **Learnings:**
  - Gotchas: Creating a `DispatchSourceTimer` (via `DispatchSource.makeTimerSource`) and then NOT calling `.resume()` before the variable goes out of scope causes a SIGTRAP crash (GCD assertion). Always ensure every created DispatchSource is either resumed or cancelled+nil'd before deallocation.
  - Patterns: Use one ivar per logical timer role (mainWait, finalCountdown, drift, countdown) — avoids reuse bugs and makes `cancelInternal()` straightforward.
  - Context: `ClickItLite` target excludes all Lite source files except the `@main` entry; every new `.swift` file in `Sources/ClickIt/Lite/` must be added to the `exclude:` list.
---
