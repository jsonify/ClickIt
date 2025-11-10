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

    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var onRightMouseClick: (() -> Void)?
    private var lastClickTime: TimeInterval = 0
    private let clickDebounceInterval: TimeInterval = 0.1

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
    nonisolated func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    /// Start monitoring for right mouse clicks (Live Mouse Mode)
    func startMouseMonitoring(onRightClick: @escaping () -> Void) {
        self.onRightMouseClick = onRightClick

        // Monitor globally (when app is inactive)
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            // Dispatch to MainActor since global monitor runs on background thread
            Task { @MainActor in
                self?.handleRightMouseClick()
            }
        }

        // Monitor locally (when app is active)
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            // Already on MainActor
            self?.handleRightMouseClick()
            return event // Pass through the event
        }
    }

    /// Stop mouse monitoring
    nonisolated func stopMouseMonitoring() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Private Methods

    /// Check if the event is an emergency stop key (ESC or SPACEBAR)
    private func isEmergencyStopKey(_ event: NSEvent) -> Bool {
        return event.keyCode == kVK_Escape || event.keyCode == kVK_Space
    }

    private func handleEmergencyStop() {
        onEmergencyStop?()
    }

    /// Handle right mouse click with debouncing
    private func handleRightMouseClick() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        if currentTime - lastClickTime < clickDebounceInterval {
            return
        }
        lastClickTime = currentTime
        onRightMouseClick?()
    }
}
