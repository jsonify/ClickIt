# Plan: Date & Time Scheduler for Single Click (Lite)

## Phase 1: Core Scheduler Logic

- [x] Task 1: Write tests for `ScheduledClickManager` <!-- commit: 9715256 -->
  - [x] Test scheduling a future date returns `.scheduled` state
  - [x] Test scheduling a past date returns a validation error
  - [x] Test cancelling a scheduled click resets to `.idle` state
  - [x] Test countdown value updates correctly each second
  - [x] Test that scheduler resets to `.idle` after firing

- [x] Task 2: Implement `ScheduledClickManager` <!-- commit: bb35f7f -->
  - [x] Create `Sources/ClickIt/Lite/ScheduledClickManager.swift`
  - [x] Define state enum: `.idle`, `.scheduled(Date)`, `.fired`
  - [x] Implement `schedule(at:)` with past-date validation
  - [x] Implement `cancel()` to reset to idle
  - [x] Implement 1-second countdown timer using `Timer`
  - [x] Implement click execution at current cursor position on trigger using `SimpleClickEngine`
  - [x] Auto-reset to `.idle` after click fires
  - [x] Run `swift test` — all tests must pass

- [x] Task 3: Conductor - User Manual Verification 'Phase 1: Core Scheduler Logic' (Protocol in workflow.md)

## Phase 2: ViewModel Integration

- [x] Task 1: Write tests for scheduler integration in `SimpleViewModel` <!-- commit: 724c4be -->
  - [x] Test `scheduleClick(at:)` delegates to `ScheduledClickManager`
  - [x] Test `cancelSchedule()` resets scheduler state
  - [x] Test `scheduledDate` and `countdown` published properties reflect manager state
  - [x] Test that scheduling is disabled while auto-clicking is running

- [x] Task 2: Integrate `ScheduledClickManager` into `SimpleViewModel` <!-- commit: 953c2d4 -->
  - [x] Add `ScheduledClickManager` instance to `SimpleViewModel`
  - [x] Expose `@Published var schedulerState` mirroring manager state
  - [x] Expose `@Published var countdown: TimeInterval`
  - [x] Add `scheduleClick(at: Date)` method with permission guard
  - [x] Add `cancelSchedule()` method
  - [x] Add `editSchedule(to: Date)` method
  - [x] Disable scheduling when auto-clicking is active (`isRunning`)
  - [x] Run `swift test` — all tests must pass

- [x] Task 3: Conductor - User Manual Verification 'Phase 2: ViewModel Integration' (Protocol in workflow.md)

## Phase 3: UI Components

- [x] Task 1: Build scheduler UI section in `SimplifiedMainView` <!-- commit: 760c029 -->
  - [x] Add `schedulerSection` computed view property
  - [x] Add `DatePicker` for selecting scheduled date and time (future dates only)
  - [x] Add "Schedule Click" button (disabled when `isRunning`)
  - [x] Show past-date error message when validation fails

- [x] Task 2: Build countdown and active schedule UI <!-- commit: 939e74f -->
  - [x] Show countdown timer (formatted as `HH:mm:ss`) when a click is scheduled
  - [x] Show scheduled date/time label below countdown
  - [x] Show "Edit" button to update scheduled time
  - [x] Show "Cancel" button to remove the scheduled click
  - [x] Show visual confirmation (brief status message) when click fires
  - [x] Integrate `schedulerSection` into main `VStack` layout in `SimplifiedMainView`

- [x] Task 3: Conductor - User Manual Verification 'Phase 3: UI Components' (Protocol in workflow.md)
