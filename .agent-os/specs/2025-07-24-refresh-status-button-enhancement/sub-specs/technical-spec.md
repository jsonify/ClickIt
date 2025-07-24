# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-24-refresh-status-button-enhancement/spec.md

> Created: 2025-07-24
> Version: 1.0.0

## Technical Requirements

- **macOS System Integration**: Use `tccutil` command-line tool to reset TCC (Transparency, Consent, and Control) database entries
- **Process Execution**: Implement secure Process execution with proper error handling and timeout management
- **Asynchronous Operation**: Handle permission reset and re-request flow using Swift's async/await pattern
- **UI State Management**: Implement loading states and user feedback during the reset operation
- **Permission Dialog Triggering**: Automatically trigger the macOS accessibility permission dialog after reset
- **Error Recovery**: Maintain existing refresh functionality as fallback when reset operations fail
- **Bundle ID Security**: Ensure only current app's bundle ID is affected by reset operations

## Approach Options

**Option A: System Integration Approach** (Selected)
- Use native `tccutil reset Accessibility [bundleId]` command
- Automatically trigger permission request after reset
- Provide immediate user feedback with loading states
- Graceful fallback to existing refresh behavior on failure

Pros:
- Uses official Apple system utilities for maximum reliability
- Automatic cleanup of stale permission entries
- Single-click user experience
- Maintains security by only affecting current app

Cons:
- Requires Process execution which may have security implications
- Dependent on tccutil availability and behavior consistency

**Option B: User-Guided Approach**
- Provide step-by-step instructions for manual permission cleanup
- Open System Settings to the appropriate panel
- Monitor for permission changes

Pros:
- No system process execution required
- User maintains full control over permissions
- No dependency on system utilities

Cons:
- Multi-step user workflow
- Error-prone manual process
- Poor developer experience for frequent testing

**Rationale:** Option A provides the best user experience by automating the entire permission reset workflow while using official Apple utilities for maximum reliability and security.

## Implementation Details

### Core PermissionManager Enhancement

```swift
// Add to PermissionManager.swift
func resetAccessibilityPermission() async -> Bool {
    guard let bundleId = Bundle.main.bundleIdentifier else {
        print("Error: Could not get bundle identifier")
        return false
    }
    
    return await withCheckedContinuation { continuation in
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
            process.arguments = ["reset", "Accessibility", bundleId]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                // Wait for system to process the reset
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Request permission again to trigger dialog
                let granted = await self.requestAccessibilityPermission()
                continuation.resume(returning: granted)
            } catch {
                print("Failed to reset accessibility permission: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
}

func refreshWithReset() async -> Bool {
    // Reset accessibility permission and re-request
    let accessibilityReset = await resetAccessibilityPermission()
    
    // Update all permission status regardless of reset result
    await self.updatePermissionStatus()
    
    return accessibilityReset
}
```

### Enhanced UI State Management

```swift
// Add to PermissionsGateView.swift
@State private var isRefreshingPermissions = false
@State private var refreshErrorMessage: String?

private func refreshPermissionStatus() {
    isRefreshingPermissions = true
    refreshErrorMessage = nil
    
    Task {
        let success = await permissionManager.refreshWithReset()
        
        await MainActor.run {
            isRefreshingPermissions = false
            if !success {
                refreshErrorMessage = "Could not reset permissions. Try manually removing ClickIt from Accessibility settings."
                
                // Auto-clear error after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    refreshErrorMessage = nil
                }
            }
        }
    }
}
```

### Enhanced Button UI

```swift
Button(action: { refreshPermissionStatus() }) {
    HStack(spacing: 8) {
        if isRefreshingPermissions {
            ProgressView()
                .scaleEffect(0.8)
        } else {
            Image(systemName: "arrow.clockwise")
        }
        Text(isRefreshingPermissions ? "Resetting..." : "Refresh Status")
    }
}
.buttonStyle(.bordered)
.controlSize(.regular)
.disabled(isRefreshingPermissions)
```

## Security Considerations

### Safety Measures
- **Bundle ID Validation**: Only reset permission for current app's bundle ID to prevent affecting other applications
- **Process Sandboxing**: Use only approved system utilities (`/usr/bin/tccutil`) for maximum security
- **User Consent**: Only execute reset on explicit user button press, never automatically
- **Graceful Fallback**: Never break existing functionality - fall back to standard refresh on any failure

### Privacy Compliance
- **Minimal Access**: Only modify TCC entry for current application
- **Transparent Action**: Button clearly indicates it will reset permissions
- **User Control**: User always has final say in the permission dialog that appears

## Error Handling Strategy

### Potential Issues & Solutions
1. **tccutil command fails**: Log error and fall back to regular status refresh
2. **Permission dialog doesn't appear**: Show error message with manual instructions
3. **User denies permission in dialog**: Update status normally and show appropriate guidance
4. **Process execution timeout**: Implement 10-second timeout with fallback to standard refresh

### Error Recovery Flow
```
1. User clicks "Refresh Status"
2. Attempt tccutil reset
3. If reset fails → Log error, show message, fall back to updatePermissionStatus()
4. If reset succeeds but permission denied → Update status normally
5. If reset succeeds and permission granted → Update status and continue
```

## Files to Modify

### Core Implementation
- `Sources/ClickIt/Core/Permissions/PermissionManager.swift`
  - Add `resetAccessibilityPermission()` method
  - Add `refreshWithReset()` method
  - Enhance error handling for process execution

### UI Updates
- `Sources/ClickIt/UI/Views/PermissionsGateView.swift`
  - Add loading and error state variables
  - Update `refreshPermissionStatus()` function  
  - Enhance button UI with loading indicator and error display

## External Dependencies

No new external dependencies required. Implementation uses only native Swift and Foundation APIs:
- **Process**: For executing tccutil command
- **Bundle**: For obtaining current app's bundle identifier
- **Task/async-await**: For asynchronous operation handling