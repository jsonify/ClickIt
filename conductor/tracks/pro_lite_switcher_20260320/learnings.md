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
