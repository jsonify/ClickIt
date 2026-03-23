# Plan: Lite Scheduler Timing Diagnostic Screen

## Phase 1: Timing Data Model & Scheduler Instrumentation

- [x] Task: Create git branch `feat/timing-diagnostic-screen`
  - Run: `git checkout -b feat/timing-diagnostic-screen`

- [x] Task (TDD Red): Write tests for `TimingRecord` and `DiagnosticSession` models
  - `TimingRecord`: scheduledAt, actualAt, delta (computed), severity (green/yellow/red)
  - `DiagnosticSession`: array of records, min/max/avg delta, total count
  - Tests in `Tests/ClickItTests/Lite/TimingDiagnosticTests.swift`

- [x] Task: Implement `TimingRecord` and `DiagnosticSession` models
  - New file: `Sources/ClickIt/Lite/TimingDiagnostic/DiagnosticSession.swift`
  - Severity enum: `green` (≤10ms), `yellow` (10–50ms), `red` (>50ms)
  - Make `DiagnosticSession` an `@Observable` class for SwiftUI binding

- [x] Task (TDD Red): Write tests for LiteScheduler timing instrumentation
  - Verify `scheduledAt` timestamp is captured when scheduler is armed
  - Verify `actualAt` timestamp is captured inside the execution handler
  - Verify callback delivers a `TimingRecord` to the observer

- [x] Task: Instrument `LiteScheduler` to emit timing records
  - Capture `scheduledAt` when `schedule(at:)` is called
  - Capture `actualAt` at the top of the execution handler (before any other work)
  - Add `var onTimingRecord: ((TimingRecord) -> Void)?` callback property
  - Wire callback through `ScheduledClickManager`

- [x] Task: Conductor - User Manual Verification 'Timing Data Model & Scheduler Instrumentation' (Protocol in workflow.md)

## Phase 2: Diagnostic Tab UI

- [x] Task (TDD Red): Write snapshot/unit tests for `DiagnosticTabView`
  - Empty state renders correctly (no firings yet)
  - Stats section displays min/max/avg/count
  - Severity badge renders correct color tier

- [x] Task: Implement `DiagnosticTabView`
  - New file: `Sources/ClickIt/Lite/Views/DiagnosticTabView.swift`
  - Empty state: message prompting user to run a scheduled click
  - Stats section: min delta, max delta, avg delta, total firings
  - Severity badge: color-coded per session's worst/latest severity
  - Receives `DiagnosticSession` as `@Environment` or injected `@Bindable`

- [x] Task: Conductor - User Manual Verification 'Diagnostic Tab UI' (Protocol in workflow.md)

## Phase 3: Integration into Lite UI

- [x] Task (TDD Red): Write integration test confirming tab appears in Lite UI tab bar

- [x] Task: Add Diagnostic tab to existing Lite `TabView`
  - Instantiate shared `DiagnosticSession` at the app/scene level
  - Pass session into `ScheduledClickManager` for wiring to `LiteScheduler`
  - Add `DiagnosticTabView` as a new tab (e.g. icon: `waveform.path.ecg`)
  - Exclude new source files from `ClickItLite` target in `Package.swift` if needed

- [x] Task: Conductor - User Manual Verification 'Integration into Lite UI' (Protocol in workflow.md)
