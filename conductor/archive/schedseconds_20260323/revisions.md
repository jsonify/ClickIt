# Track Revisions: schedseconds_20260323

## Revision 1 — 2026-03-23
- **Type:** Plan
- **Trigger:** During Phase 1, Task 1 — discovered that `ScheduledClickManager.schedule(at:)` does NOT truncate seconds; the truncation lives in `SimplifiedMainView.swift:370-373` (UI layer, not scheduler layer).
- **Phase/Task when found:** Phase 1, Task 1
- **Problem:** Removing the truncation in Phase 1 without adding the seconds stepper would pass a DatePicker `Date` with a non-deterministic seconds component (whatever time the picker was last rendered), producing unpredictable behavior.
- **Change:** Phase 1 scope reduced to: write a test confirming `ScheduledClickManager` correctly preserves a seconds-precise Date (no source code change required). The truncation removal is folded into Phase 2 alongside the stepper addition, where the correct `scheduledSeconds` value is available.
- **Rationale:** Phase 1 still provides TDD confidence; Phase 2 atomically replaces truncation with stepper-combined date.
