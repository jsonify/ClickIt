import Foundation
import AppKit
import SwiftUI

@MainActor
class HotkeyManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = HotkeyManager()
    
    // MARK: - Published Properties
    
    @Published var isRegistered: Bool = false
    @Published private(set) var currentHotkey: HotkeyConfiguration = .default
    @Published var lastError: String?
    
    // MARK: - Private Properties
    
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var lastHotkeyTime: TimeInterval = 0
    private let hotkeyDebounceInterval: TimeInterval = 0.5 // 500ms debounce
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    func initialize() {
        registerDefaultHotkey()
    }
    
    func cleanup() {
        unregisterGlobalHotkey()
    }
    
    func registerGlobalHotkey(_ config: HotkeyConfiguration) -> Bool {
        // Unregister existing hotkey first
        unregisterGlobalHotkey()
        
        // Only monitor DELETE key specifically (keyCode 51) to reduce false triggers
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 51 { // Only handle DELETE key
                self?.handleKeyEvent(event)
            }
        }
        
        // Install local event monitor for DELETE key (when app is active)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 51 { // Only handle DELETE key
                self?.handleKeyEvent(event)
            }
            return event // Always pass through the event
        }
        
        if globalEventMonitor != nil || localEventMonitor != nil {
            currentHotkey = config
            isRegistered = true
            lastError = nil
            print("HotkeyManager: Successfully registered DELETE key monitoring (keyCode 51 only)")
            return true
        } else {
            lastError = "Failed to register key event monitors"
            return false
        }
    }
    
    func unregisterGlobalHotkey() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        
        isRegistered = false
        print("HotkeyManager: Successfully unregistered hotkey monitoring")
    }
    
    // MARK: - Private Methods
    
    private func registerDefaultHotkey() {
        let success = registerGlobalHotkey(.default)
        if !success {
            print("HotkeyManager: Failed to register default DELETE hotkey")
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        // Debounce hotkey presses to prevent rapid fire
        if currentTime - lastHotkeyTime < hotkeyDebounceInterval {
            print("HotkeyManager: Hotkey debounced (too soon after last press)")
            return
        }
        
        print("HotkeyManager: DELETE key event received - keyCode: \(event.keyCode)")
        
        // Check if this is the DELETE key (keyCode 51) - should always be true now
        if event.keyCode == currentHotkey.keyCode {
            // Check modifiers if any are required
            let requiredModifiers = NSEvent.ModifierFlags(rawValue: UInt(currentHotkey.modifiers))
            let eventModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            
            if requiredModifiers.isEmpty || eventModifiers == requiredModifiers {
                print("HotkeyManager: DELETE hotkey MATCHED - dispatching to ClickCoordinator")
                lastHotkeyTime = currentTime
                handleDeleteKeyPressed()
            } else {
                print("HotkeyManager: DELETE key pressed but modifiers don't match (required: \(requiredModifiers.rawValue), got: \(eventModifiers.rawValue))")
            }
        }
    }
    
    private func handleDeleteKeyPressed() {
        // Safely access the coordinator and stop automation
        Task { @MainActor in
            let coordinator = ClickCoordinator.shared
            
            if coordinator.isActive {
                print("HotkeyManager: Stopping automation (DELETE pressed)")
                coordinator.stopAutomation()
            } else {
                print("HotkeyManager: DELETE pressed but no automation is running")
            }
        }
    }
}

// MARK: - Supporting Types

struct HotkeyConfiguration {
    let keyCode: UInt16
    let modifiers: UInt32
    let description: String
    
    static let `default` = HotkeyConfiguration(
        keyCode: FrameworkConstants.CarbonConfig.deleteKeyCode,
        modifiers: 0, // No modifiers for DELETE key
        description: "DELETE Key"
    )
    
    init(keyCode: UInt16, modifiers: UInt32, description: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.description = description
    }
}

// MARK: - Common Hotkey Configurations

extension HotkeyConfiguration {
    
    static let deleteKey = HotkeyConfiguration(
        keyCode: 51, // DELETE key
        modifiers: 0,
        description: "DELETE Key"
    )
    
    static let cmdDelete = HotkeyConfiguration(
        keyCode: 51, // DELETE key
        modifiers: UInt32(NSEvent.ModifierFlags.command.rawValue),
        description: "Cmd + DELETE"
    )
    
    static let optionDelete = HotkeyConfiguration(
        keyCode: 51, // DELETE key
        modifiers: UInt32(NSEvent.ModifierFlags.option.rawValue),
        description: "Option + DELETE"
    )
    
    // Legacy ESC configurations (deprecated)
    static let escapeKey = HotkeyConfiguration(
        keyCode: 53, // ESC key
        modifiers: 0,
        description: "ESC Key (deprecated)"
    )
}