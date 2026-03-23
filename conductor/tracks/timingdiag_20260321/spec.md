# Spec: Lite Scheduler Timing Diagnostic Screen

## Overview

An in-app diagnostic tab within the ClickIt Lite UI that passively observes the
LiteScheduler and records timing accuracy data each time a real scheduled click
fires. Gives users and developers a live view of how precisely the scheduler is
performing against its target fire times.

## Functional Requirements

### Data Captured Per Firing
- **Scheduled fire time** — the timestamp the click was intended to fire
- **Actual fire time** — the timestamp the click actually fired (captured inside
  the execution handler)
- **Delta** — difference between actual and scheduled (in milliseconds), signed
  (positive = late, negative = early)

### Statistics (session-scoped, reset on app launch)
- Minimum delta
- Maximum delta
- Average delta
- Total firings observed

### Visual Accuracy Indicator
Color-coded severity badge per firing and for the session summary:
- 🟢 Green — delta ≤ 10ms (within ClickIt's sub-10ms accuracy goal)
- 🟡 Yellow — delta 10–50ms (degraded)
- 🔴 Red — delta > 50ms (unacceptable)

### UI Placement
- Presented as a dedicated **tab** within the existing Lite main UI
- Tab is always visible; data populates passively as scheduled clicks fire
- Empty state shown when no firings have been observed yet

### Data Collection
- Passive only — no test-mode clicks fired
- Hooks into `LiteScheduler` (or `ScheduledClickManager`) to record timestamps
  at the moment the execution handler is called
- Scheduled time is captured at the point the scheduler is armed

## Non-Functional Requirements
- Zero impact on scheduling accuracy (observation must not add latency)
- UI updates on the main thread; timing capture on the scheduler's dispatch queue
- No persistence — data is in-memory, session-scoped only

## Acceptance Criteria
- [ ] Diagnostic tab is visible in the Lite UI
- [ ] Each scheduled click firing records scheduled time, actual time, and delta
- [ ] Session stats (min/max/avg, total count) update after each firing
- [ ] Color-coded severity badge reflects the correct tier for each delta value
- [ ] Empty state is shown before any firings occur
- [ ] Timing capture adds no measurable latency to the scheduler

## Out of Scope
- Historical log of individual firings (no per-entry list)
- User-configurable thresholds
- On-demand test mode / synthetic clicks
- Persistence across app launches
