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
        // Request permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Check again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkPermissions()
        }
    }

    /// Open System Settings to Privacy & Security > Accessibility
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
