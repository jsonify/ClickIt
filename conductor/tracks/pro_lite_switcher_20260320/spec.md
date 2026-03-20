# Spec: Pro/Lite Version Switcher

## Overview
Add the ability to switch between ClickIt Pro and ClickIt Lite UI modes at runtime within a single running app. The active mode persists across launches via UserDefaults. Switching closes the current window and opens a new one sized for the selected mode.

## Functional Requirements

1. **Single Unified Entry Point**
   - The `ClickIt` (Pro) binary serves as the unified host app.
   - On launch, it reads the persisted `AppMode` from UserDefaults and presents the corresponding UI.

2. **Runtime Mode Toggle — View Menu**
   - A "View" menu contains a "Switch to Lite" / "Switch to Pro" item (label updates to reflect the opposite of the current mode).
   - Selecting the item closes the active window and opens a new window in the selected mode with the correct default size:
     - Pro: 500×900
     - Lite: content-driven (`.contentSize`)

3. **Persistence**
   - Selected mode is stored in UserDefaults under a key (e.g., `appMode`).
   - Restored on every subsequent launch.

4. **Shared Lite UI in Pro Binary**
   - The Lite UI source files (`SimplifiedMainView`, `SimpleViewModel`, `SimpleClickEngine`, `SimpleHotkeyManager`, `SimplePermissionManager`, `SimpleCursorManager`, `LoggingConstants`) are made accessible to the `ClickIt` (Pro) SPM target so they can be rendered when in Lite mode.
   - The standalone `ClickItLite` binary is unchanged and continues to work independently.

## Non-Functional Requirements
- No relaunch required to switch modes.
- Switch must complete in <500ms (just a window close+open, no heavy re-init).
- Zero impact on standalone `ClickItLite` binary behavior.

## Acceptance Criteria
- [ ] Launching the Pro app in Lite mode shows `SimplifiedMainView` in a content-sized window.
- [ ] Launching the Pro app in Pro mode shows `ContentView` in a 500×900 window.
- [ ] The View menu item label reflects the *opposite* mode ("Switch to Lite" when in Pro, "Switch to Pro" when in Lite).
- [ ] Selecting the menu item closes the current window and opens the correct window for the new mode.
- [ ] The selected mode persists after quitting and relaunching the app.
- [ ] The standalone `ClickItLite` binary builds and runs without any changes.

## Out of Scope
- Switching modes within `ClickItLite` standalone binary.
- Animated transitions between modes.
- Per-window mode (only one mode active at a time).
