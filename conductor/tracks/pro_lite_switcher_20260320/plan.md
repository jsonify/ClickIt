# Plan: Pro/Lite Version Switcher

> **Branch:** All work must be done on a feature branch (e.g., `feat/pro-lite-switcher`).
> Create the branch before starting Phase 1.

## Phase 0: Feature Branch Setup

- [ ] Task 1: Create feature branch
  - [ ] `git checkout -b feat/pro-lite-switcher`
  - [ ] Confirm clean working tree on new branch

- [ ] Task: Conductor - User Manual Verification 'Phase 0: Feature Branch Setup' (Protocol in workflow.md)

## Phase 1: SPM Target Restructuring

- [ ] Task 1: Make Lite UI source files accessible to the `ClickIt` Pro target
  - [ ] Update `Package.swift` — restructure so Lite source files are included in the `ClickIt` target's source path (e.g., move shared Lite files out of `Lite/` exclusion or create a shared `LiteUI/` path)
  - [ ] Guard `@main` in `ClickItLiteApp.swift` with a compile flag (e.g., `#if CLICKIT_LITE_STANDALONE`) so it only applies when building the standalone `ClickItLite` target
  - [ ] Verify `swift build -c debug --product ClickIt` succeeds
  - [ ] Verify `swift build -c debug --product ClickItLite` succeeds
  - [ ] Run `swift test` — all tests pass

- [ ] Task: Conductor - User Manual Verification 'Phase 1: SPM Target Restructuring' (Protocol in workflow.md)

## Phase 2: AppMode Model & Persistence

- [ ] Task 1: Define `AppMode` enum and persistence layer
  - [ ] Create `Sources/ClickIt/Core/Models/AppMode.swift` with `enum AppMode: String, CaseIterable { case pro, lite }`
  - [ ] Add `AppModeManager` with `UserDefaults` read/write for key `"appMode"`, default value `.lite`
  - [ ] Write unit tests for persistence (save → read round-trip, default value)
  - [ ] Run `swift test` — all tests pass

- [ ] Task: Conductor - User Manual Verification 'Phase 2: AppMode Model & Persistence' (Protocol in workflow.md)

## Phase 3: Unified App Entry Point

- [ ] Task 1: Update `ClickItApp` to conditionally render Pro or Lite UI based on `AppMode`
  - [ ] Read `AppMode` from `AppModeManager` on launch; expose as `@AppStorage` or `@State`
  - [ ] In `WindowGroup`, conditionally show `ContentView` (pro) or `SimplifiedMainView` (lite)
  - [ ] Apply correct window sizing: Pro = `.defaultSize(width: 500, height: 900)`, Lite = `.windowResizability(.contentSize)` only
  - [ ] Write tests confirming correct root view is presented for each mode
  - [ ] Run `swift test` — all tests pass

- [ ] Task: Conductor - User Manual Verification 'Phase 3: Unified App Entry Point' (Protocol in workflow.md)

## Phase 4: View Menu Toggle

- [ ] Task 1: Add "Switch to Lite / Switch to Pro" item to the View menu
  - [ ] Add `CommandMenu("View")` in `ClickItApp.body` `.commands { }` block
  - [ ] Label: "Switch to Lite" when current mode is `.pro`; "Switch to Pro" when `.lite`
  - [ ] On selection: persist new mode via `AppModeManager`, close current window (`NSApp.keyWindow?.close()`), open correct new window
  - [ ] Write UI/unit test confirming menu item label reflects current mode
  - [ ] Run `swift test` — all tests pass

- [ ] Task: Conductor - User Manual Verification 'Phase 4: View Menu Toggle' (Protocol in workflow.md)

## Phase 5: Integration & Regression

- [ ] Task 1: End-to-end verification and cleanup
  - [ ] Manual smoke test: Pro → switch to Lite → quit → relaunch → confirm Lite restored
  - [ ] Manual smoke test: Lite → switch to Pro → confirm 500×900 window appears
  - [ ] Run full `swift test` suite — no regressions
  - [ ] Verify standalone `ClickItLite` binary builds and runs independently
  - [ ] Open PR from `feat/pro-lite-switcher` → `main`

- [ ] Task: Conductor - User Manual Verification 'Phase 5: Integration & Regression' (Protocol in workflow.md)
