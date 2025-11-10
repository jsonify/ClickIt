//
//  SimpleHotkeyManager.swift
//  ClickIt Lite
//
//  Simple hotkey manager - ESC key only for emergency stop.
//

import Foundation
import AppKit
import Carbon

/// Simple hotkey manager for ESC key emergency stop
@MainActor
final class SimpleHotkeyManager {

    // MARK: - Properties

    private var globalMonitor: Any?
    private var onEmergencyStop: (() -> Void)?

    // MARK: - Singleton

    static let shared = SimpleHotkeyManager()

    private init() {}

    // MARK: - Public Methods

    /// Start monitoring for ESC key
    func startMonitoring(onEmergencyStop: @escaping () -> Void) {
        self.onEmergencyStop = onEmergencyStop

        // Monitor ESC key globally
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for ESC key (keyCode 53)
            if event.keyCode == 53 {
                self?.handleEmergencyStop()
            }
        }
    }

    /// Stop monitoring
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        onEmergencyStop = nil
    }

    // MARK: - Private Methods

    private func handleEmergencyStop() {
        onEmergencyStop?()
    }
}
