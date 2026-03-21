# Plan: High-Precision Scheduler for ScheduledClickManager

## Phase 1: Extract LiteScheduler

- [x] Task 1: Create feature branch `feat/high-precision-scheduler-lite`
  - [x] `git checkout -b feat/high-precision-scheduler-lite`

- [x] Task 2: Write `LiteSchedulerTests.swift` (TDD — tests first)
  - [ ] Test `schedule(for:task:)` with future date returns `true`
  - [ ] Test `schedule(for:task:)` with past date returns `false`
  - [ ] Test `cancel()` prevents task execution
  - [ ] Test `executionHandler` is called when task fires
  - [ ] Test `countdownUpdateHandler` is called with decreasing values
  - [ ] Add `LiteSchedulerTests` to test target in `Package.swift` if needed
  - [ ] Run `swift test` — tests expected to fail (TDD red)

- [x] Task 3: Implement `LiteScheduler.swift` in `Sources/ClickIt/Lite/`
  - [x] Define `Configuration` struct (matches `HighPrecisionScheduler.Configuration`)
  - [x] Implement Phase 1 – main wait `DispatchSourceTimer` (fires `executionLeadTime` early)
  - [x] Implement Phase 2 – final countdown (10ms polling, executes at ≤5ms)
  - [x] Implement Phase 3 – drift compensation (60s re-check)
  - [x] Implement `cancel()` — cancel all three timers, nil out handlers
  - [x] Implement `getTimeRemaining()`
  - [x] Run `swift test` — LiteScheduler tests must go green

- [x] Task 4: Register `LiteScheduler.swift` in `Package.swift`
  - [x] Add `LiteScheduler.swift` to the `ClickItLite` target's `exclude:` list
    (per SPM multi-target sharing pattern in `conductor/patterns.md`)
  - [x] Run `swift test` — full suite must pass

- [x] Task: Conductor - User Manual Verification 'Extract LiteScheduler' (Protocol in workflow.md)

---

## Phase 2: Refactor ScheduledClickManager

- [x] Task 1: Update `ScheduledClickManagerTests.swift` for API changes
  - [ ] Replace all references to `onFired` with `executionHandler`
  - [ ] Update countdown test to account for higher-frequency updates (sub-second)
  - [ ] Update fire-timing test — precision is now ≤5ms, tighten tolerances if appropriate
  - [ ] Run `swift test` — tests expected to fail (TDD red)

- [x] Task 2: Refactor `ScheduledClickManager` to own and drive `LiteScheduler`
  - [x] Remove `var timer: Timer?`, `startTimer()`, `stopTimer()`, `tick()`
  - [x] Add `private let scheduler: LiteScheduler`
  - [x] Wire `scheduler.countdownUpdateHandler` → update `self.countdown`
  - [x] Wire `scheduler.executionHandler` → call `clickAction()`, transition `state` to `.fired` then `.idle`
  - [x] Replace `onFired` with `executionHandler`
  - [x] Update `schedule(at:)` to call `scheduler.schedule(for:task:)`
  - [x] Update `cancel()` to call `scheduler.cancel()`
  - [x] Run `swift test` — all tests must pass

- [x] Task 3: Update callers of `onFired` across the codebase
  - [x] Search for `onFired` references in `Sources/` and update to `executionHandler`
  - [x] Run `swift test` — full suite must pass

- [x] Task: Conductor - User Manual Verification 'Refactor ScheduledClickManager' (Protocol in workflow.md)
