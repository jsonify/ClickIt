# Spec: Add Seconds to Scheduled Click Time Picker

## Overview

Currently, users can only schedule a click to the nearest minute using the
hour/minute date picker. This track adds a seconds stepper so users can
schedule clicks at a specific second within a minute (e.g., 10 or 15 seconds
after the hour/minute).

## Functional Requirements

1. A `Stepper` control for seconds (range: 0–59, step: 1) is always visible
   in the scheduler section, positioned alongside or directly below the
   existing `DatePicker`.

2. The stepper displays the current seconds value and common preset labels
   as reference points: **0s**, **15s**, **30s**, **45s**.

3. The seconds value is combined with the `DatePicker`-selected date/time
   when `scheduleClick(at:)` is called — replacing the current behavior of
   truncating seconds to 0.

4. The scheduled confirmation message includes seconds:
   e.g., "Scheduled for 3:45:15 PM" instead of "3:45 PM".

5. The seconds stepper resets to 0 when the scheduler fires or is cancelled,
   consistent with how the date picker resets.

## Non-Functional Requirements

- UI must remain compact and not exceed the current scheduler section width.
- Seconds label styling must match existing time picker label conventions.

## Acceptance Criteria

- [ ] Seconds stepper (0–59, step 1) is always visible in the scheduler section.
- [ ] Common preset values (0, 15, 30, 45) are visually indicated in or near
      the stepper.
- [ ] Scheduled time includes the selected seconds value (not truncated to 0).
- [ ] Confirmation/status message shows HH:MM:SS format.
- [ ] Stepper resets to 0 on scheduler fire or cancel.
- [ ] Existing scheduled-click tests pass; new unit tests cover seconds inclusion.

## Out of Scope

- Sub-second (millisecond) precision scheduling.
- Changes to the ClickIt Pro variant.
- Modifying the countdown timer display format.
