//
//  SimpleHotkeyManager.swift
//  ClickIt Lite
//
//  Simple hotkey manager - ESC and SPACEBAR keys for emergency stop.
//

import Foundation
import AppKit
import Carbon

/// Simple hotkey manager for ESC and SPACEBAR emergency stop
@MainActor
final class SimpleHotkeyManager {

    // MARK: - Properties

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var onEmergencyStop: (() -> Void)?

    // MARK: - Singleton

    static let shared = SimpleHotkeyManager()

    private init() {}

    // MARK: - Public Methods

    /// Start monitoring for ESC and SPACEBAR keys
    func startMonitoring(onEmergencyStop: @escaping () -> Void) {
        self.onEmergencyStop = onEmergencyStop

        // Monitor globally (when app is inactive)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isEmergencyStopKey(event) == true {
                // Dispatch to MainActor since global monitor runs on background thread
                Task { @MainActor in
                    self?.handleEmergencyStop()
                }
            }
        }

        // Monitor locally (when app is active)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isEmergencyStopKey(event) == true {
                // Already on MainActor
                self?.handleEmergencyStop()
                // Return nil to prevent the event from being dispatched further
                return nil
            }
            return event
        }
    }

    /// Stop monitoring
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        onEmergencyStop = nil
    }

    // MARK: - Private Methods

    /// Check if the event is an emergency stop key (ESC or SPACEBAR)
    private func isEmergencyStopKey(_ event: NSEvent) -> Bool {
        return event.keyCode == kVK_Escape || event.keyCode == kVK_Space
    }

    private func handleEmergencyStop() {
        onEmergencyStop?()
    }
}
