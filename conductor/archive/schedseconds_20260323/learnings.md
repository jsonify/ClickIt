# Track Learnings: schedseconds_20260323

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

### SwiftUI Date/Time Pickers
- **Truncate seconds for `DatePicker` with `.hourAndMinute`**: The picker displays only hour:minute, but `Date()` carries seconds. The previous track (`datetime_scheduler_20260320`) zeroed seconds before scheduling. This track reverses that — preserve seconds by combining the picker date with the `scheduledSeconds` stepper value before passing to `scheduleClick(at:)`.
- **`nextMinute()` helper initializes picker default**: The default scheduled date is set via a `nextMinute()` helper that truncates seconds. Keep this helper for the date picker default; the seconds stepper starts at 0 separately.

### Architecture
- `SimpleViewModel` is `@MainActor final class ObservableObject` — any new state must follow the same actor isolation pattern.
- `ClickItLiteUI` module houses Lite-specific types — tests must use `@testable import ClickItLiteUI`.
- `onFired` callback on `ScheduledClickManager` drives UI resets (more reliable than observing transient `.fired` state via Combine).

### SPM
- Every new `.swift` file added to `Sources/ClickIt/Lite/` must be added to the `ClickItLite` target's `exclude:` list in `Package.swift` — otherwise SPM reports "overlapping sources".
- `@testable import` only exposes internals of the directly-named module — use `@testable import ClickItLiteUI` for Lite tests.

### Testing
- Test classes accessing `@MainActor`-isolated types must be `@MainActor`; async tests use `await fulfillment(of:timeout:)`.
- Known flaky tests (not regressions): `testHighFrequencyCPSAccuracy`, `testErrorRecoveryIntegration` — skip if they fail in isolation.

### Gotchas
- macOS Sequoia kills unsigned app bundles — always ad-hoc sign debug builds: `codesign --sign - --force --deep <app.bundle>`.

---

<!-- Learnings from implementation will be appended below -->

## [2026-03-23] - Phase 3: Confirmation Message — Include Seconds
- **Implemented:** Changed `.time: .shortened` to `.time: .standard` in the "Scheduled for" label. Added `testScheduledForMessage_includesSecondsComponent`.
- **Files changed:** `Sources/ClickIt/Lite/SimplifiedMainView.swift`, `Tests/ClickItTests/SimpleViewModelSchedulerTests.swift`
- **Commit:** d3429d6
- **Learnings:**
  - Patterns: `Date.FormatStyle.TimeStyle.standard` includes seconds (HH:MM:SS AM/PM); `.shortened` truncates to HH:MM. Use `.standard` when seconds precision matters in display.
---

## [2026-03-23] - Phase 2: UI — Seconds Stepper + Remove View-Level Truncation
- **Implemented:** `@State scheduledSeconds: Int = 0`, Stepper (0–59) with 4 preset buttons (0s/15s/30s/45s). Replaced `c.second = 0` with `c.second = scheduledSeconds`. Reset on Cancel (explicit), fire (`.onChange(of: schedulerState)` detecting `.idle`). Edit restores seconds from `targetDate`. 2 new ViewModel integration tests.
- **Files changed:** `Sources/ClickIt/Lite/SimplifiedMainView.swift`, `Tests/ClickItTests/SimpleViewModelSchedulerTests.swift`
- **Commit:** 2f4b8b5
- **Learnings:**
  - Patterns: For firing reset — `ScheduledClickManager.fire()` transitions `.scheduled → .fired → .idle` synchronously on MainActor; SwiftUI may batch these and only deliver `.idle`. Use `.onChange(of: schedulerState) { if case .idle = newState { ... } }` to catch both cancel and fire resets.
  - Patterns: Edit button should restore `scheduledSeconds = Calendar.current.component(.second, from: targetDate)` so the user sees the exact value they had set, not 0.
  - Patterns: `ForEach([0, 15, 30, 45], id: \.self)` inside a SwiftUI view builder works fine since `Int` conforms to `Hashable`.
  - Gotchas: `.onChange(of:perform:)` single-closure form is deprecated in macOS 14 — pre-existing codebase pattern, not a blocker, no new issues introduced.
---

## [2026-03-23] - Phase 1: Scheduler — Confirm Seconds Precision
- **Implemented:** Added `testScheduleWithNonZeroSeconds_preservesSecondsInState` to `ScheduledClickManagerTests.swift`
- **Files changed:** `Tests/ClickItTests/ScheduledClickManagerTests.swift`
- **Commit:** a66ae5d
- **Learnings:**
  - Patterns: `ScheduledClickManager.schedule(at:)` passes the `Date` directly to `LiteScheduler` — no seconds truncation at the scheduler layer. The truncation was added at the view layer in `SimplifiedMainView.swift:370-373` to match the `.hourAndMinute` DatePicker display.
  - Gotchas: Removing view-level truncation without a seconds stepper would produce non-deterministic behavior (DatePicker Date carries the system time's seconds component). Always remove truncation and add stepper atomically.
---
