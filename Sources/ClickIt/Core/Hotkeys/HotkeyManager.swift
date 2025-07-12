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
    private var lastEscKeyTime: TimeInterval = 0
    private let escKeyDebounceInterval: TimeInterval = 0.5 // 500ms debounce
    
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
        
        // Only monitor ESC key specifically (keyCode 53) to reduce false triggers
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Only handle ESC key
                self?.handleKeyEvent(event)
            }
        }
        
        // Install local event monitor for ESC key (when app is active)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Only handle ESC key
                self?.handleKeyEvent(event)
            }
            return event // Always pass through the event
        }
        
        if globalEventMonitor != nil || localEventMonitor != nil {
            currentHotkey = config
            isRegistered = true
            lastError = nil
            print("HotkeyManager: Successfully registered ESC key monitoring (keyCode 53 only)")
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
            print("HotkeyManager: Failed to register default ESC hotkey")
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        // Debounce ESC key presses to prevent rapid fire
        if currentTime - lastEscKeyTime < escKeyDebounceInterval {
            print("HotkeyManager: ESC key debounced (too soon after last press)")
            return
        }
        
        print("HotkeyManager: ESC key event received - keyCode: \(event.keyCode)")
        
        // Check if this is the ESC key (keyCode 53) - should always be true now
        if event.keyCode == currentHotkey.keyCode {
            // Check modifiers if any are required
            let requiredModifiers = NSEvent.ModifierFlags(rawValue: UInt(currentHotkey.modifiers))
            let eventModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            
            if requiredModifiers.isEmpty || eventModifiers == requiredModifiers {
                print("HotkeyManager: ESC hotkey MATCHED - dispatching to ClickCoordinator")
                lastEscKeyTime = currentTime
                handleEscKeyPressed()
            } else {
                print("HotkeyManager: ESC key pressed but modifiers don't match (required: \(requiredModifiers.rawValue), got: \(eventModifiers.rawValue))")
            }
        }
    }
    
    private func handleEscKeyPressed() {
        let coordinator = ClickCoordinator.shared
        
        if coordinator.isActive {
            print("HotkeyManager: Stopping automation (ESC pressed)")
            coordinator.stopAutomation()
        } else {
            print("HotkeyManager: ESC pressed but no automation is running")
        }
    }
}

// MARK: - Supporting Types

struct HotkeyConfiguration {
    let keyCode: UInt16
    let modifiers: UInt32
    let description: String
    
    static let `default` = HotkeyConfiguration(
        keyCode: FrameworkConstants.CarbonConfig.escKeyCode,
        modifiers: 0, // No modifiers for ESC key
        description: "ESC Key"
    )
    
    init(keyCode: UInt16, modifiers: UInt32, description: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.description = description
    }
}

// MARK: - Common Hotkey Configurations

extension HotkeyConfiguration {
    
    static let escapeKey = HotkeyConfiguration(
        keyCode: 53, // ESC key
        modifiers: 0,
        description: "ESC Key"
    )
    
    static let cmdEscape = HotkeyConfiguration(
        keyCode: 53, // ESC key
        modifiers: UInt32(NSEvent.ModifierFlags.command.rawValue),
        description: "Cmd + ESC"
    )
    
    static let optionEscape = HotkeyConfiguration(
        keyCode: 53, // ESC key
        modifiers: UInt32(NSEvent.ModifierFlags.option.rawValue),
        description: "Option + ESC"
    )
}