# Plan: Pro/Lite Version Switcher

> **Branch:** All work must be done on a feature branch (e.g., `feat/pro-lite-switcher`).
> Create the branch before starting Phase 1.

## Phase 0: Feature Branch Setup

- [x] Task 1: Create feature branch
  - [x] `git checkout -b feat/pro-lite-switcher`
  - [x] Confirm clean working tree on new branch

- [x] Task: Conductor - User Manual Verification 'Phase 0: Feature Branch Setup' (Protocol in workflow.md)

## Phase 1: SPM Target Restructuring

- [x] Task 1: Make Lite UI source files accessible to the `ClickIt` Pro target
  - [x] Update `Package.swift` — added `ClickItLiteUI` shared library target; both executables depend on it
  - [x] Used Swift 5.9 `package` access level (no @main conflict, no file moves needed)
  - [x] Verify `swift build -c debug --product ClickIt` succeeds
  - [x] Verify `swift build -c debug --product ClickItLite` succeeds
  - [x] `swift test` blocked by Xcode license — requires `sudo xcodebuild -license accept` manually; builds verified clean

- [x] Task: Conductor - User Manual Verification 'Phase 1: SPM Target Restructuring' (Protocol in workflow.md)

## Phase 2: AppMode Model & Persistence

- [x] Task 1: Define `AppMode` enum and persistence layer
  - [x] Create `Sources/ClickIt/Core/Models/AppMode.swift` with `enum AppMode: String, CaseIterable { case pro, lite }`
  - [x] Add `AppModeManager` with `UserDefaults` read/write for key `"appMode"`, default value `.lite`
  - [x] 5 unit tests: default, round-trip, allCases, invalid fallback — all pass
  - [x] `swift test --filter AppModeManagerTests` passes

- [x] Task: Conductor - User Manual Verification 'Phase 2: AppMode Model & Persistence' (Protocol in workflow.md)

## Phase 3: Unified App Entry Point

- [x] Task 1: Update `ClickItApp` to conditionally render Pro or Lite UI based on `AppMode`
  - [x] `@AppStorage("appMode")` reads persisted mode; `currentMode` computed var for clean access
  - [x] `WindowGroup` switches on `currentMode` → `SimplifiedMainView` (lite) or `ContentView` (pro)
  - [x] Lite window: content-driven via `.windowResizability(.contentSize)` + `SimplifiedMainView`'s `.frame(400, 600)`
  - [x] Pro window: `.defaultSize(width: 500, height: 900)` unchanged
  - [x] Mode-split init: Lite activates custom cursor; Pro initializes HotkeyManager + PermissionManager
  - [x] Both products build; swift test passes (exit 0)

- [x] Task: Conductor - User Manual Verification 'Phase 3: Unified App Entry Point' (Protocol in workflow.md)

## Phase 4: View Menu Toggle

- [x] Task 1: Add "Switch to Lite / Switch to Pro" item to the View menu
  - [x] `CommandMenu("View")` hosts `SwitchModeCommand` (private SwiftUI View) — correct pattern for @Environment access in commands
  - [x] Main `WindowGroup` given `id: "main-window"` to enable `openWindow(id:)`
  - [x] Label: "Switch to Lite" when `.pro`; "Switch to Pro" when `.lite`
  - [x] On tap: `AppModeManager.current = newMode` → `NSApp.keyWindow?.close()` → `openWindow(id: "main-window")`
  - [x] `swift test` passes (exit 0)

- [x] Task: Conductor - User Manual Verification 'Phase 4: View Menu Toggle' (Protocol in workflow.md)

## Phase 5: Integration & Regression

- [ ] Task 1: End-to-end verification and cleanup
  - [ ] Manual smoke test: Pro → switch to Lite → quit → relaunch → confirm Lite restored
  - [ ] Manual smoke test: Lite → switch to Pro → confirm 500×900 window appears
  - [ ] Run full `swift test` suite — no regressions
  - [ ] Verify standalone `ClickItLite` binary builds and runs independently
  - [ ] Open PR from `feat/pro-lite-switcher` → `main`

- [ ] Task: Conductor - User Manual Verification 'Phase 5: Integration & Regression' (Protocol in workflow.md)
