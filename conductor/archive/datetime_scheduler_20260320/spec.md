# Spec: Date & Time Scheduler for Single Click (Lite)

## Overview
Add a date and time scheduler to ClickIt Lite that allows users to schedule a single
one-time click action at a specific future date and time. The click fires at the
current cursor position when the scheduled time arrives. The app must remain open
for the scheduled click to execute.

## Functional Requirements

### Scheduling
- User can select a future date and time to schedule a single click
- Date/time picker uses native macOS date and time controls
- Scheduled time must be in the future (past times are rejected with an error)
- Only one scheduled click can be active at a time

### Execution
- When the scheduled time arrives, a single click fires at the current cursor position
- The app must be open and running for the click to fire
- After the click fires, the scheduler resets to idle state

### UI — Scheduler Controls
- Date/time picker visible in the Lite main view for setting the scheduled time
- A "Schedule Click" button to confirm and activate the schedule
- While a click is scheduled:
  - Countdown timer shows time remaining (updates every second)
  - Scheduled date/time is displayed
  - "Edit" button allows changing the scheduled time
  - "Cancel" button removes the scheduled click

### Feedback
- Visual confirmation when a schedule is set
- Notification or visual indicator when the scheduled click fires

## Non-Functional Requirements
- Countdown timer updates at 1-second intervals with no perceptible lag
- Scheduling UI integrates cleanly with the existing SimplifiedMainView layout
- No new external dependencies

## Acceptance Criteria
- [ ] User can pick a future date and time and schedule a single click
- [ ] Countdown timer displays and updates correctly while a click is pending
- [ ] User can edit or cancel a pending scheduled click
- [ ] Click fires at current cursor position when scheduled time arrives
- [ ] Past date/time selection is rejected with clear error messaging
- [ ] Scheduler resets to idle after the click fires
- [ ] All new logic covered by unit tests (≥80% Core layer coverage)

## Out of Scope
- Recurring/repeating scheduled clicks
- Background execution (app must remain open)
- Clicking at a saved/pinned coordinate (always fires at current cursor position)
- Push notifications or system alerts
