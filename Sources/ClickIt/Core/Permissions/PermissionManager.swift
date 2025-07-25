import Foundation
import ApplicationServices
import AVFoundation
import SwiftUI

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var accessibilityPermissionGranted: Bool = false
    @Published var screenRecordingPermissionGranted: Bool = false
    @Published var allPermissionsGranted: Bool = false
    
    private init() {
        updatePermissionStatus()
    }
    
    // MARK: - Permission Status Checking
    
    nonisolated func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrustedWithOptions(nil)
    }
    
    nonisolated func checkScreenRecordingPermission() -> Bool {
        guard #available(macOS 10.15, *) else { return true }
        
        // Create a small window list request to test screen recording permission
        let windowList = CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)
        return windowList != nil
    }
    
    func updatePermissionStatus() {
        let accessibility = checkAccessibilityPermission()
        let screenRecording = checkScreenRecordingPermission()
        
        // We're already on MainActor, no need for DispatchQueue.main.async
        accessibilityPermissionGranted = accessibility
        screenRecordingPermissionGranted = screenRecording
        allPermissionsGranted = accessibility && screenRecording
    }
    
    func updatePermissionStatus() async {
        await MainActor.run {
            updatePermissionStatus()
        }
    }
    
    // MARK: - Permission Reset Functionality
    
    func resetAccessibilityPermission() async -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            print("Error: Could not get bundle identifier")
            return false
        }
        
        print("Resetting accessibility permission for bundle: \(bundleId)")
        
        return await withCheckedContinuation { continuation in
            Task {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
                process.arguments = ["reset", "Accessibility", bundleId]
                
                // Set up timeout handling
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    if !process.isRunning {
                        return
                    }
                    print("tccutil process timed out, terminating...")
                    process.terminate()
                }
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    timeoutTask.cancel()
                    
                    let exitCode = process.terminationStatus
                    print("tccutil reset completed with exit code: \(exitCode)")
                    
                    if exitCode == 0 {
                        // Wait for system to process the reset
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        
                        // Request permission again to trigger dialog
                        let granted = await self.requestAccessibilityPermission()
                        continuation.resume(returning: granted)
                    } else {
                        print("tccutil reset failed with exit code: \(exitCode)")
                        continuation.resume(returning: false)
                    }
                } catch {
                    timeoutTask.cancel()
                    print("Failed to reset accessibility permission: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func refreshWithReset() async -> Bool {
        // First try to reset accessibility permission if not granted
        var resetSuccess = true
        if !accessibilityPermissionGranted {
            resetSuccess = await resetAccessibilityPermission()
        }
        
        // Always update all permission status regardless of reset result
        await self.updatePermissionStatus()
        
        return resetSuccess
    }
    
    // MARK: - Permission Requesting
    
    func requestAccessibilityPermission() async -> Bool {
        // For the request, we need to trigger the system dialog
        // We'll use a simple approach that works with concurrency
        let granted = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                // This triggers the system permission dialog
                let accessibilityDialogKey = "AXTrustedCheckOptionPrompt"
                let options = [accessibilityDialogKey: true] as CFDictionary
                let result = AXIsProcessTrustedWithOptions(options)
                continuation.resume(returning: result)
            }
        }
        
        self.accessibilityPermissionGranted = granted
        self.updateAllPermissionsStatus()
        
        return granted
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        guard #available(macOS 10.15, *) else { 
            self.screenRecordingPermissionGranted = true
            self.updateAllPermissionsStatus()
            return true 
        }
        
        // Request screen recording permission
        let granted = CGRequestScreenCaptureAccess()
        
        self.screenRecordingPermissionGranted = granted
        self.updateAllPermissionsStatus()
        
        return granted
    }
    
    func requestAllPermissions() async -> Bool {
        let accessibilityGranted = await requestAccessibilityPermission()
        let screenRecordingGranted = await requestScreenRecordingPermission()
        
        return accessibilityGranted && screenRecordingGranted
    }
    
    // MARK: - Utilities
    
    private func updateAllPermissionsStatus() {
        allPermissionsGranted = accessibilityPermissionGranted && screenRecordingPermissionGranted
    }
    
    func openSystemSettings(for permission: PermissionType) {
        let urlString: String
        
        switch permission {
        case .accessibility:
            urlString = AppConstants.accessibilitySettingsURL
        case .screenRecording:
            urlString = AppConstants.screenRecordingSettingsURL
        }
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL string for \(permission.rawValue) settings")
            return
        }
        
        NSWorkspace.shared.open(url)
    }
    
    private var monitoringTimer: Timer?
    
    func startPermissionMonitoring() {
        // Avoid multiple timers
        stopPermissionMonitoring()
        
        // Since we're already on @MainActor, create timer on main RunLoop directly
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // We're already on MainActor via timer on main RunLoop, so call directly
            self?.updatePermissionStatus()
        }
    }
    
    func stopPermissionMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func getPermissionDescription(for permission: PermissionType) -> String {
        switch permission {
        case .accessibility:
            return "ClickIt needs Accessibility permission to simulate mouse clicks and register global hotkeys (ESC key). This allows the app to send click events to other applications."
        case .screenRecording:
            return "ClickIt needs Screen Recording permission to detect windows and display visual feedback overlays. This allows the app to identify target windows and show click indicators."
        }
    }
    
    func getPermissionInstructions(for permission: PermissionType) -> String {
        switch permission {
        case .accessibility:
            return "1. Open System Settings\n2. Go to Privacy & Security\n3. Select Accessibility\n4. Enable ClickIt in the list"
        case .screenRecording:
            return "1. Open System Settings\n2. Go to Privacy & Security\n3. Select Screen Recording\n4. Enable ClickIt in the list"
        }
    }
}

// MARK: - Permission Types

enum PermissionType: String, CaseIterable {
    case accessibility = "Accessibility"
    case screenRecording = "Screen Recording"
    
    var systemIcon: String {
        switch self {
        case .accessibility:
            return "accessibility"
        case .screenRecording:
            return "rectangle.on.rectangle"
        }
    }
    
    var description: String {
        switch self {
        case .accessibility:
            return "Required for mouse simulation and global hotkeys"
        case .screenRecording:
            return "Required for window detection and visual overlays"
        }
    }
}
