# Track Learnings: pro_lite_switcher_20260320

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

- Use `PreviewProvider` struct instead of `#Preview {}` macro — fails with `swift build`
- Explicitly `exclude:` non-source files (`.md`, `.txt`) from SPM targets in `Package.swift`
- macOS 26 (Sequoia): always ad-hoc sign with `codesign --sign - --force --deep <app.bundle>` for local debug builds
- Both `ClickItApp` and `ClickItLiteApp` currently have `@main` — the `@main` conflict must be resolved before the `ClickIt` target can include Lite source files
- `ClickIt` Pro target uses `.defaultSize(width: 500, height: 900)`; Lite uses `.windowResizability(.contentSize)`

---

<!-- Learnings from implementation will be appended below -->

## [2026-03-20] - Phase 3 Task 1: Unified App Entry Point
- **Implemented:** Updated `ClickItApp` to read `@AppStorage("appMode")` and render `SimplifiedMainView` or `ContentView` conditionally. Mode-split `initializeApp()`.
- **Files changed:** `Sources/ClickIt/ClickItApp.swift`
- **Commit:** 3daa39f
- **Learnings:**
  - Patterns: `@AppStorage` is preferred over a custom manager computed property inside `App` — it's reactive and triggers scene re-evaluation when the value changes.
  - Patterns: `SimplifiedMainView`'s `.frame(width: 400, height: 600)` + `.windowResizability(.contentSize)` on the scene means no explicit `.defaultSize` change needed for Lite mode — the content drives the window size.
---

## [2026-03-20] - Phase 4 Task 1: View Menu Toggle
- **Implemented:** `CommandMenu("View")` hosting a private `SwitchModeCommand` SwiftUI view. Main `WindowGroup` given `id: "main-window"`.
- **Files changed:** `Sources/ClickIt/ClickItApp.swift`
- **Commit:** 7c91998
- **Learnings:**
  - Patterns: To use `@Environment` values (like `openWindow`) inside `CommandMenu`, wrap the content in a private `View` struct — closures in `CommandMenu` don't have access to SwiftUI environment injection.
  - Patterns: `openWindow(id:)` requires the target `WindowGroup` to have an explicit `id` parameter set.
  - Patterns: The mode-switch sequence is: persist new mode → `NSApp.keyWindow?.close()` → `openWindow(id: "main-window")`. `@AppStorage` update is synchronous via UserDefaults so the new window opens with the correct mode already set.
---

## [2026-03-20] - Phase 1 Task 1: SPM Target Restructuring
- **Implemented:** Created `ClickItLiteUI` shared SPM library target from `Sources/ClickIt/Lite/` (excludes `ClickItLiteApp.swift`). Both executables depend on it. Used Swift 5.9 `package` access level to share types.
- **Files changed:** `Package.swift`, `ClickItLiteApp.swift`, `SimplifiedMainView.swift`, `SimpleCursorManager.swift`
- **Commit:** 8c73ea8
- **Learnings:**
  - Patterns: When splitting a directory into a library + entry-point targets in SPM, use `exclude:` lists to partition source files between the two targets sharing the same path — SPM resolves the file sets correctly as long as they are disjoint.
  - Patterns: Swift 5.9 `package` access level works across modules within the same SPM package (all targets compile with `-package-name clickit`). This avoids the overhead of `public` while still sharing types between modules.
  - Gotchas: SwiftUI `View` conformance requires `body` to match the type's access level — if the struct is `package`, `var body` must also be `package`.
  - Gotchas: `swift test` requires Xcode license agreement (`sudo xcodebuild -license accept`) on this machine — CommandLineTools does not include XCTest.
  - Gotchas: `ClickItLite` entry point file `ClickItLiteApp.swift` needs `import ClickItLiteUI` after moving shared types to the library module.
---

## [2026-03-20] - Phase 5 Bug Fix: Window Switch Double-Open
- **Implemented:** Replaced close/reopen approach with in-place content swap + window resize
- **Files changed:** `Sources/ClickIt/ClickItApp.swift`
- **Commit:** 46e50fa
- **Learnings:**
  - Gotchas: `openWindow(id:)` on a `WindowGroup` ALWAYS opens a NEW window — it does not focus or reuse an existing one. Combining it with `dismiss()` creates a race condition where the old window may not close before the new one opens, resulting in 2 windows.
  - Patterns: For single-window mode switching in SwiftUI macOS apps, the correct pattern is in-place content swap (via `@AppStorage` + `switch` in the view) + programmatic window resize (`NSApp.mainWindow?.setContentSize()`) in `onChange`. No `openWindow` or `dismiss` needed.
  - Gotchas: `NSApp.keyWindow` is unreliable when a floating overlay window (like `VisualFeedbackOverlay`) is present — it returns the overlay, not the main app window. Use `NSApp.mainWindow` instead.
---
