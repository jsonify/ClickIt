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

    // MARK: - Private Properties

    private var appActivationObserver: NSObjectProtocol?

    // MARK: - Singleton

    static let shared = SimplePermissionManager()

    private init() {
        checkPermissions()
        setupAppActivationMonitoring()
    }

    deinit {
        if let observer = appActivationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Private Methods

    /// Monitor when app becomes active to re-check permissions
    private func setupAppActivationMonitoring() {
        appActivationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Re-check permissions when app becomes active (e.g., returning from System Settings)
            Task { @MainActor in
                self?.checkPermissions()
            }
        }
    }

    // MARK: - Public Methods

    /// Check current permission status
    func checkPermissions() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    /// Request accessibility permission (opens System Settings)
    func requestAccessibilityPermission() {
        // Request permission. This opens System Settings to the Accessibility pane.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Note: Don't check permissions immediately - they won't be granted yet.
        // The app activation monitor will automatically re-check when the user
        // returns from System Settings.
    }

    /// Open System Settings to Privacy & Security > Accessibility
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
