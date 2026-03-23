# Plan: Add Seconds to Scheduled Click Time Picker
<!-- Last Revised: 2026-03-23 (Revision 1 — see revisions.md) -->

## Phase 1: Scheduler — Confirm Seconds Precision (Test-Only)

<!-- Revision 1: ScheduledClickManager.schedule(at:) already handles full Dates —
     no source change needed. Truncation lives in view layer (SimplifiedMainView.swift:370-373)
     and will be removed in Phase 2 alongside the stepper addition. -->

- [x] Task: Read `ScheduledClickManager.swift` and confirm seconds are NOT truncated in the scheduler layer
- [x] Task: Write unit test verifying a scheduled `Date` with non-zero seconds is preserved in `.scheduled` state
- [x] Task: Run `swift test` — all tests pass
- [x] Task: Commit `test(scheduler): verify seconds-precise Date is preserved through schedule(at:)` (a66ae5d)
- [x] Task: Attach git note summarizing the change
- [x] Task: Conductor - User Manual Verification 'Phase 1: Scheduler — Confirm Seconds Precision' (Protocol in workflow.md)

## Phase 2: UI — Seconds Stepper + Remove View-Level Truncation

- [x] Task: Read `SimplifiedMainView.swift` scheduler section
- [x] Task: Add `@State private var scheduledSeconds: Int = 0` to the view
- [x] Task: Add a `Stepper` (range 0–59, step 1) always visible below the `DatePicker`, displaying the current value with preset reference labels (0s, 15s, 30s, 45s)
- [x] Task: Replace the truncation block (lines 370-373) with a date that combines `scheduledDate` (hour/minute from DatePicker) and `scheduledSeconds` (from stepper)
- [x] Task: Reset `scheduledSeconds` to 0 when scheduler fires or is cancelled (mirror existing `scheduledDate` reset logic)
- [x] Task: Write UI-level tests (or snapshot/integration tests) covering stepper visibility, value range, and seconds inclusion in scheduled date
- [x] Task: Run `swift test` — all tests pass
- [x] Task: Commit `feat(lite/ui): add seconds stepper to scheduler section` (2f4b8b5)
- [x] Task: Attach git note
- [x] Task: Conductor - User Manual Verification 'Phase 2: UI — Seconds Stepper' (Protocol in workflow.md)

## Phase 3: Confirmation Message — Include Seconds

- [x] Task: Locate where the "Scheduled for..." status message is formatted in `SimpleViewModel.swift` or `SimplifiedMainView.swift`
- [x] Task: Update the formatter to include seconds (HH:MM:SS AM/PM format)
- [x] Task: Write/update tests verifying the message format includes seconds
- [x] Task: Run `swift test` — all tests pass
- [x] Task: Commit `feat(lite/ui): show seconds in scheduler confirmation message` (d3429d6)
- [x] Task: Attach git note
- [x] Task: Conductor - User Manual Verification 'Phase 3: Confirmation Message — Include Seconds' (Protocol in workflow.md)
