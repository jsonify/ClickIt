# Spec: High-Precision Scheduler for ScheduledClickManager

## Overview

Replace the 1-second `Timer` in `ScheduledClickManager` with a `DispatchSourceTimer`-based
scheduler extracted into a reusable `LiteScheduler` class in `Lite/`. The new scheduler
follows the 3-phase approach of `HighPrecisionScheduler` (Pro): drift compensation + main
wait + 10ms final countdown. `ScheduledClickManager` is refactored to own a `LiteScheduler`
instance, and its public API aligns more closely with `HighPrecisionScheduler`'s
callback-based style.

## Functional Requirements

1. **Extract `LiteScheduler`** — New `final class LiteScheduler` in `Sources/ClickIt/Lite/`:
   - `schedule(for:task:) -> Bool` — schedules a task for a future date; returns `false`
     if date is in the past
   - `cancel()` — cancels all internal timers and clears the pending task
   - `countdownUpdateHandler: ((TimeInterval) -> Void)?` — called every ~1s with
     seconds remaining
   - `executionHandler: (() -> Void)?` — called when the task executes
   - `getTimeRemaining() -> TimeInterval`
   - `Configuration` struct (mirrors `HighPrecisionScheduler.Configuration`):
     `driftCompensationInterval`, `executionLeadTime`, `finalCountdownPollingInterval`

2. **3-phase scheduling inside `LiteScheduler`:**
   - **Phase 1 – Main wait:** `DispatchSourceTimer` fires `executionLeadTime` (100ms)
     before target time (1ms leeway)
   - **Phase 2 – Final countdown:** polls every `finalCountdownPollingInterval` (10ms)
     with 1ms leeway; executes when ≤5ms remaining
   - **Phase 3 – Drift compensation:** secondary `DispatchSourceTimer` rechecks every
     `driftCompensationInterval` (60s); skips if within `executionLeadTime * 2`

3. **Refactor `ScheduledClickManager`:**
   - Owns a `LiteScheduler` instance; no `Timer` references remain
   - `startTimer()` / `stopTimer()` / `tick()` removed; replaced by `LiteScheduler` calls
   - `@Published var countdown` wired from `LiteScheduler.countdownUpdateHandler`
   - `@Published var state` transitions wired from `LiteScheduler.executionHandler`
   - `onFired` renamed to `executionHandler` (aligns with `LiteScheduler` API)
   - `schedule(at:)` and `cancel()` public signatures unchanged (callers unaffected)

4. **Feature branch** — all work on `feat/high-precision-scheduler-lite`

## Non-Functional Requirements

- Fire within ≤5ms of the target time (down from up to ~1s with the old `Timer`)
- Zero new external dependencies
- `LiteScheduler` independently unit-testable
- `swift test` must pass throughout

## Acceptance Criteria

- [ ] `LiteScheduler.swift` exists in `Sources/ClickIt/Lite/` with 3-phase
      `DispatchSourceTimer` implementation
- [ ] `ScheduledClickManager` contains no `Timer` references; uses `LiteScheduler`
- [ ] `ScheduledClickManager.onFired` replaced by `executionHandler`
- [ ] `ScheduledClickManagerTests` updated and passing; new `LiteSchedulerTests` added
- [ ] `swift test` passes on feature branch
- [ ] All commits on `feat/high-precision-scheduler-lite` branch

## Out of Scope

- Changes to `HighPrecisionScheduler` or any Pro-only code
- Multi-click or recurring scheduled clicks
- UI changes beyond wiring the renamed `executionHandler` callback
- Precision improvements to CGEvent posting itself
