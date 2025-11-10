//
//  SimplePermissionManager.swift
//  ClickIt Lite
//
//  Basic permission checking for Accessibility.
//

import Foundation
import AppKit

/// Simple permission manager for basic permission checks
@MainActor
final class SimplePermissionManager: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var hasAccessibilityPermission = false

    // MARK: - Singleton

    static let shared = SimplePermissionManager()

    private init() {
        checkPermissions()
    }

    // MARK: - Public Methods

    /// Check current permission status
    func checkPermissions() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    /// Request accessibility permission (opens System Settings)
    func requestAccessibilityPermission() {
        // Request permission. This is a blocking call that shows the system prompt.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        // After the user interacts with the dialog, check the permission status again
        checkPermissions()
    }

    /// Open System Settings to Privacy & Security > Accessibility
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
