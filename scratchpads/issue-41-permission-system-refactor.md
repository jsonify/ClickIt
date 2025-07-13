# Issue #41: Adopt macos-auto-clicker Permission Strategy

**Issue Link**: https://github.com/jsonify/clickit/issues/41

## Problem Analysis

### Current Issues in ClickIt Permission System

1. **Concurrency Crashes**: App crashes when Accessibility permission is toggled ON
   - Root cause: Race conditions in `PermissionStatusChecker.swift:30-34`
   - Problem: Timer callbacks mixing `Task { @MainActor }` with existing `@MainActor` isolation

2. **Complex Architecture**: Two separate classes with overlapping responsibilities
   - `PermissionManager`: Main permission logic with singleton pattern
   - `PermissionStatusChecker`: Additional monitoring layer with health checks
   - Both use `@MainActor` but have synchronization issues

3. **Redundant Dispatch Calls**: Conflicts between `@MainActor` and `DispatchQueue.main.async`
   - Fixed in `PermissionManager.swift:36-40` but pattern exists elsewhere

4. **Manual Monitoring Start**: Requires explicit `startPermissionMonitoring()` call
   - Missing from app initialization in some cases

### Research Findings from Similar Projects

**othyn/macos-auto-clicker Strategy:**
- Relies on manual permission configuration
- Provides clear user instructions for permission reset
- Acknowledges macOS "stuck permission" issues
- Simple approach: user education over complex automation

**jevonmao/PermissionsSwiftUI Patterns:**
- Permission gate UI that blocks access until granted
- Automatic status checking with `notDetermined` filtering
- Modal/Alert patterns for permission requests
- SwiftUI view modifiers for conditional access

## Recommended Implementation Strategy

### Phase 1: Simplify Architecture (High Priority)

1. **Consolidate Permission Classes**
   - Keep `PermissionManager` as primary singleton
   - Remove `PermissionStatusChecker` or merge functionality
   - Eliminate redundant monitoring systems

2. **Fix Concurrency Issues**
   - Remove all `DispatchQueue.main.async` calls in `@MainActor` classes
   - Use proper Timer patterns that don't conflict with actor isolation
   - Simplify to direct property updates in `@MainActor` context

3. **Implement Permission Gate Pattern**
   ```swift
   struct ClickItApp: App {
       @StateObject private var permissionManager = PermissionManager.shared
       
       var body: some Scene {
           WindowGroup {
               if permissionManager.allPermissionsGranted {
                   ContentView()
               } else {
                   PermissionsGateView()
               }
           }
       }
   }
   ```

### Phase 2: Create PermissionsGateView (Medium Priority)

Design full-screen permission view that:
- Blocks access to main functionality
- Shows clear permission status with checkmarks/X marks
- Provides "Open System Settings" buttons
- Explains why each permission is needed
- Auto-refreshes when returning from Settings

**UI Components:**
```swift
struct PermissionsGateView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            // App icon and title
            // Permission status list with icons
            // Clear explanations
            // Action buttons (Open Settings, Refresh)
        }
    }
}
```

### Phase 3: Improve Permission Detection (Low Priority)

1. **Simplified Monitoring**
   - Single timer in `PermissionManager`
   - Remove complex health checking system
   - Focus on reliability over features

2. **Better Status Detection**
   - More reliable screen recording permission check
   - Proper error handling for edge cases

## Implementation Plan

### Step 1: Architectural Cleanup
- [ ] Remove `PermissionStatusChecker.swift` or merge into `PermissionManager`
- [ ] Fix Timer pattern in `PermissionManager.startPermissionMonitoring()`
- [ ] Remove redundant dispatch calls
- [ ] Test permission toggling for crashes

### Step 2: Permission Gate Implementation
- [ ] Create `PermissionsGateView.swift` in `UI/Views/`
- [ ] Update `ClickItApp.swift` to use permission gate pattern
- [ ] Design clear permission status indicators
- [ ] Add "Open System Settings" functionality

### Step 3: Integration & Testing
- [ ] Update `ContentView.onAppear` to ensure monitoring starts
- [ ] Test permission flow end-to-end
- [ ] Verify no crashes when toggling permissions
- [ ] Test with permission reset using `tccutil`

### Step 4: Documentation
- [ ] Update CLAUDE.md with new permission workflow
- [ ] Document permission reset commands for development
- [ ] Add troubleshooting section for stuck permissions

## Code Quality Targets

**Stability**: No crashes when permissions are toggled
**Simplicity**: Single `PermissionManager` class with clear responsibilities  
**UX**: Clear permission gate that blocks access until requirements met
**Reliability**: Automatic permission detection without manual monitoring start

## Acceptance Criteria

- [x] App does not crash when Accessibility permission is toggled
- [x] Permission detection works automatically without manual monitoring start
- [x] Users see clear permission gate before accessing main functionality
- [x] Permission gate provides direct access to System Settings
- [x] All existing functionality continues to work after refactor

## Next Steps

1. Create simplified `PermissionManager` without concurrency issues
2. Implement `PermissionsGateView` following SwiftUI best practices
3. Test permission flow with complete app restart/permission reset
4. Validate stability with repeated permission toggling