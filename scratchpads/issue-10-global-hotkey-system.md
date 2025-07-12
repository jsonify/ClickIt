# Issue #10: Global Hotkey System Implementation Plan

**GitHub Issue:** https://github.com/jsonify/clickit/issues/10
**Status:** Planning Phase
**Priority:** High (Milestone 4 MVP)

## Problem Statement

Implement global hotkey system for system-wide app control regardless of focus, with ESC key as the primary control hotkey.

## Current Analysis

### Existing Infrastructure ✅
- **Carbon Framework**: Already imported in `AppConstants.swift:3`
- **ESC Key Constant**: `CarbonConfig.escKeyCode: UInt16 = 53` defined
- **Control Methods**: `ClickCoordinator.startAutomation()` and `stopAutomation()` ready
- **Event Pattern**: Mouse monitoring example in `ClickPointSelector.swift:198-199`

### Missing Components ❌
- Global hotkey registration using Carbon APIs
- ESC key event handling and dispatch
- Hotkey conflict detection/resolution
- Customization system for alternative hotkeys
- State management for hotkey combinations

## Implementation Plan

### Phase 1: Core Hotkey Infrastructure
1. **Create HotkeyManager class** (`Sources/ClickIt/Core/Hotkeys/HotkeyManager.swift`)
   - Singleton pattern following existing managers
   - Carbon framework hotkey registration
   - ESC key monitoring and event dispatch
   - Proper cleanup and deregistration

2. **Integration with ClickCoordinator**
   - Connect ESC key events to start/stop automation
   - Handle state transitions properly
   - Ensure thread safety with @MainActor

### Phase 2: Error Handling & Conflicts
3. **Hotkey Conflict Resolution**
   - Detect registration failures
   - Provide user feedback for conflicts
   - Graceful fallback options

4. **System Integration**
   - Handle app lifecycle (foreground/background)
   - Memory management and cleanup
   - macOS permission requirements

### Phase 3: User Customization
5. **Hotkey Customization System**
   - Settings storage using UserDefaults
   - UI for hotkey selection
   - Support for common hotkey combinations

6. **Testing & Validation**
   - Cross-platform testing (Intel/Apple Silicon)
   - Different app states (active/background/minimized)
   - Edge case handling

## Technical Implementation Details

### HotkeyManager Architecture
```swift
@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    @Published var isRegistered: Bool = false
    @Published var currentHotkey: HotkeyConfiguration
    
    // Carbon hotkey registration
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    func registerGlobalHotkey(_ config: HotkeyConfiguration) -> Bool
    func unregisterGlobalHotkey()
    func handleHotkeyEvent(_ event: EventRef) -> OSStatus
}
```

### Integration Points
- **ContentView**: Initialize hotkey manager on app startup
- **ClickCoordinator**: Receive hotkey events for automation control  
- **AppConstants**: Extend with hotkey configuration constants
- **PermissionManager**: Add any required permission checks

### Carbon API Usage
- `RegisterEventHotKey()`: Register global hotkey
- `UnregisterEventHotKey()`: Clean up registration
- `InstallEventHandler()`: Handle hotkey events
- `RemoveEventHandler()`: Cleanup event handling

## Acceptance Criteria Mapping

✅ **ESC key works globally**: Carbon framework global registration
✅ **Hotkey conflicts handled gracefully**: Registration failure detection + user feedback
✅ **Customization options available**: UserDefaults-based hotkey configuration  
✅ **Works regardless of focus**: Carbon global monitoring (system-wide)

## Risk Assessment

**Low Risk:**
- Carbon framework already imported and proven stable
- Simple ESC key implementation well-documented
- Existing patterns for manager classes and singleton usage

**Medium Risk:**
- Hotkey conflicts with system/other apps
- Memory management of Carbon C APIs from Swift
- macOS permission requirements for global monitoring

**Mitigation Strategies:**
- Start with ESC-only implementation for simplicity
- Comprehensive error handling and user feedback
- Follow established patterns from existing permission system

## Development Workflow

1. **Create branch**: `feature/issue-10-global-hotkey-system`
2. **Implement incrementally**: Core → Error Handling → Customization
3. **Test continuously**: Each phase tested before proceeding
4. **Integration testing**: With existing automation system
5. **User acceptance testing**: Real-world usage scenarios

## Next Steps

1. ✅ Research completed - Carbon framework and existing patterns analyzed
2. ✅ Planning completed - Implementation plan documented
3. 🔄 **NEXT**: Create HotkeyManager class with basic ESC key registration
4. ⏳ Integration with ClickCoordinator for automation control
5. ⏳ Error handling and conflict resolution
6. ⏳ UI customization options
7. ⏳ Comprehensive testing across app states

---
*Created: July 12, 2025*
*Last Updated: July 12, 2025*