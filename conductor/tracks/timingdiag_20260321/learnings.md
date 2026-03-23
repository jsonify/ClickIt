# Track Learnings: timingdiag_20260321

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

- Use `PreviewProvider` struct instead of `#Preview {}` macro — fails with `swift build`
- New `Lite/` source files must be excluded from `ClickItLite` target in `Package.swift` — otherwise SPM reports "overlapping sources"
- Use `@testable import ClickItLiteUI` (not `@testable import ClickIt`) for testing Lite internals
- `@Observable` class for SwiftUI binding; UI updates on main thread, timing capture on scheduler's dispatch queue
- `nonisolated` + `MainActor.assumeIsolated` for static defaults that call `@MainActor` methods
- Use explicit callback property (`var onFired: (() -> Void)?`) over Combine for transient state — Combine won't see values set and immediately reset in the same synchronous call
- GCD unresumed DispatchSource crash: every created `DispatchSourceTimer` must be resumed or explicitly cancelled before discard
- Swift 6 strict concurrency: test classes accessing `@MainActor`-isolated types must be annotated `@MainActor`

---

<!-- Learnings from implementation will be appended below -->

## [2026-03-22] - Phase 3 Task 1: TDD Red — Integration tests
- **Implemented:** LiteDiagnosticIntegrationTests (SimpleViewModel.diagnosticSession not yet added)
- **Files changed:** Tests/ClickItTests/LiteDiagnosticIntegrationTests.swift
- **Commit:** 3eeead5
- **Learnings:**
  - Patterns: Integration tests for scheduler callbacks use LiteScheduler directly (not full ScheduledClickManager) to avoid needing accessibility permissions in CI
---

## [2026-03-22] - Phase 3 Task 2: Add Diagnostic tab to Lite UI
- **Implemented:** SimpleViewModel.diagnosticSession + onTimingRecord wiring + TabView in SimplifiedMainView
- **Files changed:** SimpleViewModel.swift, SimplifiedMainView.swift
- **Commit:** 4983d11
- **Learnings:**
  - Patterns: @Observable class property can be `let` on a ViewModel — no need for @Published; SwiftUI tracks changes through the @Observable macro
  - Patterns: Moving existing VStack into a named computed var (`mainTab`) before wrapping in TabView keeps diffs clean and body readable
  - Gotchas: TabView adds chrome (~40px) — adjust window frame when introducing tabs to an existing fixed-size window
  - Gotchas: No Package.swift change needed when new files live in an already-excluded directory (TimingDiagnostic/ was excluded at the directory level)
---

## [2026-03-22] - Phase 2 Task 1: TDD Red — DiagnosticTabView tests
- **Implemented:** Test file for DiagnosticTabView (not yet created at commit time)
- **Files changed:** Tests/ClickItTests/DiagnosticTabViewTests.swift
- **Commit:** ea48d2e
- **Learnings:**
  - Patterns: For @Observable SwiftUI views, expose computed display properties (badgeSeverity) as internal vars so tests can assert on them without rendering
  - Gotchas: Badge severity uses max delta not average — key product decision worth testing explicitly
---

## [2026-03-22] - Phase 2 Task 2: Implement DiagnosticTabView
- **Implemented:** DiagnosticTabView + SeverityBadge in Lite/TimingDiagnostic/
- **Files changed:** Sources/ClickIt/Lite/TimingDiagnostic/DiagnosticTabView.swift
- **Commit:** 2128ffa
- **Learnings:**
  - Patterns: @Observable class works with @State var in SwiftUI — no need for @Bindable when session is owned by the view
  - Patterns: File-private helper views (SeverityBadge) in the same file keep the public API surface clean
  - Gotchas: DiagnosticTabView.swift lives in TimingDiagnostic/ subdir — already excluded from ClickItLite target via directory-level exclude in Package.swift
---

## [2026-03-21] - Phase 1 Task 2: TDD Red — TimingRecord & DiagnosticSession tests
- **Implemented:** Test file for model types (does not exist yet at commit time)
- **Files changed:** Tests/ClickItTests/TimingDiagnosticTests.swift
- **Commit:** 31298a1
- **Learnings:**
  - Patterns: Tests live flat in Tests/ClickItTests/ — no Lite/ subdirectory exists
  - Gotchas: Severity uses abs(delta) so negative (early) and positive (late) share same tier thresholds
---

## [2026-03-21] - Phase 1 Task 3: Implement TimingRecord and DiagnosticSession
- **Implemented:** TimingRecord struct + DiagnosticSession @Observable in Lite/TimingDiagnostic/
- **Files changed:** Sources/ClickIt/Lite/TimingDiagnostic/DiagnosticSession.swift, Package.swift
- **Commit:** f9c2e7b
- **Learnings:**
  - Patterns: New subdirectory under Lite/ must be added to ClickItLite exclude list as the directory name (e.g. "TimingDiagnostic") not individual files
  - Gotchas: DiagnosticSession tracks abs(delta) for min/max/avg — signed delta lives on TimingRecord.deltaMs only
---

## [2026-03-21] - Phase 1 Task 4: TDD Red — LiteScheduler timing instrumentation
- **Implemented:** LiteSchedulerTimingTests covering onTimingRecord (not yet implemented)
- **Files changed:** Tests/ClickItTests/LiteSchedulerTimingTests.swift
- **Commit:** 0485683
- **Learnings:**
  - Patterns: inverted expectations (isInverted = true) cleanly test "callback not called after cancel"
---

## [2026-03-21] - Phase 1 Task 5: Instrument LiteScheduler
- **Implemented:** onTimingRecord callback + ScheduledClickManager forwarding
- **Files changed:** LiteScheduler.swift, ScheduledClickManager.swift
- **Commit:** e67511e
- **Learnings:**
  - Patterns: Capture actualAt = Date() as the very first line of executeTask() before cancelling timers — any timer cancellation or nil-clearing adds measurable nanoseconds
  - Patterns: ScheduledClickManager can forward LiteScheduler callbacks as computed properties (get/set) — avoids a re-wiring step during schedule()
  - Context: onTimingRecord is delivered on main queue, after task() and executionHandler(), so observers always see the fired state before the timing record arrives
---
