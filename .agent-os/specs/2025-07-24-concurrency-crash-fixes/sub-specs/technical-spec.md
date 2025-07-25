# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-24-concurrency-crash-fixes/spec.md

> Created: 2025-07-24
> Version: 1.0.0

## Technical Requirements

### Root Cause Analysis

The application crashes are caused by improper MainActor concurrency patterns in timer callbacks where @MainActor-isolated classes use `Task { @MainActor in }` wrappers, creating race conditions and concurrency conflicts.

**Specific Problem Pattern:**
```swift
// PROBLEMATIC - Creates race condition
Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
    Task { @MainActor in  // ❌ Already on MainActor, creates conflict
        // MainActor-isolated code
    }
}
```

**Required Safe Pattern:**
```swift
// SAFE - Properly dispatches to MainActor
Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
    DispatchQueue.main.async {  // ✅ Safe MainActor dispatch
        // MainActor-isolated code
    }
}
```

### File-Specific Technical Requirements

#### 1. PermissionManager.swift (Lines 190-194)
- **Current Issue:** Timer callback using `Task { @MainActor in }` when class is @MainActor
- **Required Fix:** Replace with `DispatchQueue.main.async` 
- **Critical Constraint:** Must preserve exact permission monitoring timing and behavior
- **Performance Requirement:** No degradation in permission status update frequency

#### 2. TimerAutomationEngine.swift (Lines 288-292) - HighPrecisionTimer Callback
- **Current Issue:** High-precision timer callback using nested MainActor task
- **Required Fix:** Use `DispatchQueue.main.async` for MainActor work
- **Critical Constraint:** Must maintain sub-10ms timing accuracy
- **Performance Requirement:** No impact on clicking precision or timing stability

#### 3. TimerAutomationEngine.swift (Lines 389-393) - Status Update Timer
- **Current Issue:** Status update timer using problematic MainActor pattern
- **Required Fix:** Safe MainActor dispatch for UI updates
- **Critical Constraint:** Preserve real-time status updates and statistics tracking
- **Performance Requirement:** No delay in UI refresh or status synchronization

#### 4. ClickItApp.swift (Lines 18-20) - App Initialization
- **Current Issue:** App initialization using `Task { @MainActor in }` in main context
- **Required Fix:** Proper initialization sequence without nested MainActor tasks
- **Critical Constraint:** Maintain exact app startup behavior and initialization order
- **Performance Requirement:** No impact on app launch time or startup reliability

## Approach Options

**Option A: DispatchQueue.main.async Pattern (Selected)**
- Pros: Proven safe pattern, widely used, explicit about MainActor dispatch
- Cons: Slightly more verbose than Task syntax
- Rationale: Industry standard, no concurrency conflicts, maintains timing precision

**Option B: Remove Task Wrappers Entirely** 
- Pros: Minimal code changes, relies on existing MainActor isolation
- Cons: May not work for all timer callback contexts, potential threading issues
- Rationale: Not selected due to potential threading safety concerns

**Option C: Rewrite with AsyncTimer and Swift Concurrency**
- Pros: Modern Swift concurrency, potentially better performance
- Cons: Major architectural change, risk of introducing new issues
- Rationale: Not selected due to scope constraints and unnecessary complexity

## External Dependencies

**No New Dependencies Required**
- All fixes use existing Foundation and Dispatch APIs
- No additional frameworks or third-party libraries needed
- Pure Swift standard library solutions

## Implementation Strategy

### Phase 1: Critical Timer Callback Fixes
1. **PermissionManager Timer Fix** - Replace Task wrapper with DispatchQueue pattern
2. **TimerAutomationEngine HighPrecisionTimer Fix** - Safe MainActor dispatch for precision timing
3. **TimerAutomationEngine Status Timer Fix** - Proper UI update dispatching

### Phase 2: App Initialization Fix
1. **ClickItApp Initialization** - Remove nested MainActor task conflicts
2. **Startup Sequence Validation** - Ensure proper initialization order maintained

### Phase 3: Comprehensive Testing
1. **Permission Toggle Testing** - Validate no crashes during permission changes
2. **Timer Precision Validation** - Confirm sub-10ms timing accuracy preserved
3. **Functional Regression Testing** - Verify all features work identically

## Performance Considerations

### Timing Precision Requirements
- **Sub-10ms Click Timing:** Must be preserved exactly
- **Permission Monitoring:** Real-time status updates without delay  
- **UI Responsiveness:** No degradation in interface responsiveness
- **Memory Usage:** No increase in memory footprint from concurrency changes

### Concurrency Safety Requirements
- **Thread Safety:** All MainActor-isolated code properly dispatched
- **Race Condition Elimination:** No concurrent access to shared state
- **Timer Callback Safety:** All timer callbacks use safe MainActor patterns
- **Resource Cleanup:** Proper timer cleanup and resource management