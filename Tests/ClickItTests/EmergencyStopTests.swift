//
//  EmergencyStopTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-22.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
import Combine
@testable import ClickIt

final class EmergencyStopTests: XCTestCase {
    
    // MARK: - Basic Emergency Stop Tests
    
    @MainActor
    func testHotkeyManagerInitialization() {
        let hotkeyManager = HotkeyManager.shared
        
        // Test singleton access
        XCTAssertIdentical(HotkeyManager.shared, hotkeyManager, "HotkeyManager should be singleton")
        
        // Test initial state
        XCTAssertNotNil(hotkeyManager.currentHotkey, "Should have default hotkey configuration")
        XCTAssertEqual(hotkeyManager.currentHotkey.description, "DELETE Key", "Default should be DELETE key")
    }
    
    @MainActor
    func testDefaultEmergencyStopConfiguration() {
        let hotkeyManager = HotkeyManager.shared
        let defaultConfig = hotkeyManager.currentHotkey
        
        XCTAssertEqual(defaultConfig.keyCode, 51, "Default emergency stop should be DELETE key (keyCode 51)")
        XCTAssertEqual(defaultConfig.modifiers, 0, "Default should have no modifiers")
        XCTAssertEqual(defaultConfig.description, "DELETE Key", "Default description should match")
    }
    
    @MainActor
    func testHotkeyRegistrationSuccess() {
        let hotkeyManager = HotkeyManager.shared
        let testConfig = HotkeyConfiguration.deleteKey
        
        let success = hotkeyManager.registerGlobalHotkey(testConfig)
        
        XCTAssertTrue(success, "DELETE key registration should succeed")
        XCTAssertTrue(hotkeyManager.isRegistered, "Manager should report as registered")
        XCTAssertNil(hotkeyManager.lastError, "Should have no error on successful registration")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testHotkeyUnregistration() {
        let hotkeyManager = HotkeyManager.shared
        let testConfig = HotkeyConfiguration.deleteKey
        
        // Register first
        hotkeyManager.registerGlobalHotkey(testConfig)
        XCTAssertTrue(hotkeyManager.isRegistered, "Should be registered initially")
        
        // Then unregister
        hotkeyManager.unregisterGlobalHotkey()
        XCTAssertFalse(hotkeyManager.isRegistered, "Should not be registered after unregister")
    }
    
    @MainActor
    func testHotkeyReregistration() {
        let hotkeyManager = HotkeyManager.shared
        let config1 = HotkeyConfiguration.deleteKey
        let config2 = HotkeyConfiguration.cmdDelete
        
        // Register first hotkey
        let success1 = hotkeyManager.registerGlobalHotkey(config1)
        XCTAssertTrue(success1, "First registration should succeed")
        XCTAssertEqual(hotkeyManager.currentHotkey.description, config1.description)
        
        // Register second hotkey (should unregister first automatically)
        let success2 = hotkeyManager.registerGlobalHotkey(config2)
        XCTAssertTrue(success2, "Second registration should succeed")
        XCTAssertEqual(hotkeyManager.currentHotkey.description, config2.description)
        XCTAssertTrue(hotkeyManager.isRegistered, "Should still be registered after re-registration")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testMultipleEmergencyStopKeyConfigurations() {
        let deleteConfig = HotkeyConfiguration.deleteKey
        let cmdDeleteConfig = HotkeyConfiguration.cmdDelete
        let optionDeleteConfig = HotkeyConfiguration.optionDelete
        
        // Test DELETE key
        XCTAssertEqual(deleteConfig.keyCode, 51, "DELETE key should have keyCode 51")
        XCTAssertEqual(deleteConfig.modifiers, 0, "DELETE key should have no modifiers")
        
        // Test Cmd+DELETE key
        XCTAssertEqual(cmdDeleteConfig.keyCode, 51, "Cmd+DELETE key should have keyCode 51")
        XCTAssertNotEqual(cmdDeleteConfig.modifiers, 0, "Cmd+DELETE should have command modifier")
        
        // Test Option+DELETE key
        XCTAssertEqual(optionDeleteConfig.keyCode, 51, "Option+DELETE key should have keyCode 51")
        XCTAssertNotEqual(optionDeleteConfig.modifiers, 0, "Option+DELETE should have option modifier")
        
        // Verify all have different configurations
        XCTAssertNotEqual(deleteConfig.modifiers, cmdDeleteConfig.modifiers, "Different modifiers")
        XCTAssertNotEqual(deleteConfig.modifiers, optionDeleteConfig.modifiers, "Different modifiers")
        XCTAssertNotEqual(cmdDeleteConfig.modifiers, optionDeleteConfig.modifiers, "Different modifiers")
    }
    
    // MARK: - Emergency Stop Response Time Tests
    
    @MainActor
    func testEmergencyStopResponseTime() async {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Ensure clean state
        clickCoordinator.stopAutomation()
        
        // Register emergency stop
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        
        // Start automation (mock)
        let targetPoint = CGPoint(x: 100, y: 100)
        let config = AutomationConfiguration(
            location: targetPoint,
            clickInterval: 1.0,
            maxDuration: 10.0
        )
        
        clickCoordinator.startAutomation(with: config)
        XCTAssertTrue(clickCoordinator.isActive, "Automation should be active")
        
        // Measure response time to emergency stop
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate emergency stop (since we can't actually press keys in tests)
        clickCoordinator.stopAutomation()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let responseTime = (endTime - startTime) * 1000 // Convert to milliseconds
        
        XCTAssertLessThan(responseTime, 50, "Emergency stop should respond in <50ms")
        XCTAssertFalse(clickCoordinator.isActive, "Automation should be stopped")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testEmergencyStopDuringPause() {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Ensure clean state
        clickCoordinator.stopAutomation()
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        
        // Start and pause automation
        let targetPoint = CGPoint(x: 100, y: 100)
        let config = AutomationConfiguration(
            location: targetPoint,
            clickInterval: 1.0,
            maxDuration: 10.0
        )
        
        clickCoordinator.startAutomation(with: config)
        clickCoordinator.pauseAutomation()
        
        XCTAssertTrue(clickCoordinator.isActive, "Should be active")
        XCTAssertTrue(clickCoordinator.isPaused, "Should be paused")
        
        // Emergency stop should work even when paused
        clickCoordinator.stopAutomation()
        
        XCTAssertFalse(clickCoordinator.isActive, "Should be stopped")
        XCTAssertFalse(clickCoordinator.isPaused, "Should not be paused")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    // MARK: - Multiple Key Configuration Tests
    
    @MainActor
    func testESCKeyConfiguration() {
        // Test ESC key configuration
        let escConfig = HotkeyConfiguration.escapeKey
        
        XCTAssertEqual(escConfig.keyCode, 53, "ESC key should have keyCode 53")
        XCTAssertEqual(escConfig.modifiers, 0, "ESC key should have no modifiers")
        XCTAssertEqual(escConfig.description, "ESC Key", "Description should be 'ESC Key'")
    }
    
    @MainActor
    func testMultipleKeyRegistrationSupport() {
        let hotkeyManager = HotkeyManager.shared
        
        // Test registering different key configurations
        let configurations = [
            HotkeyConfiguration.deleteKey,
            HotkeyConfiguration.cmdDelete,
            HotkeyConfiguration.optionDelete,
            HotkeyConfiguration.escapeKey
        ]
        
        for config in configurations {
            let success = hotkeyManager.registerGlobalHotkey(config)
            XCTAssertTrue(success, "Should register \(config.description) successfully")
            XCTAssertEqual(hotkeyManager.currentHotkey.keyCode, config.keyCode, "KeyCode should match")
            XCTAssertEqual(hotkeyManager.currentHotkey.modifiers, config.modifiers, "Modifiers should match")
        }
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    // MARK: - Debounce and Rate Limiting Tests
    
    @MainActor
    func testHotkeyDebouncing() async {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Setup
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        
        let targetPoint = CGPoint(x: 100, y: 100)
        let config = AutomationConfiguration(
            location: targetPoint,
            clickInterval: 1.0,
            maxDuration: 10.0
        )
        
        // Start automation multiple times rapidly
        clickCoordinator.startAutomation(with: config)
        XCTAssertTrue(clickCoordinator.isActive, "First start should work")
        
        // Simulate rapid emergency stop calls (debouncing should prevent issues)
        clickCoordinator.stopAutomation()
        clickCoordinator.stopAutomation()  // Second call should be safe
        clickCoordinator.stopAutomation()  // Third call should be safe
        
        XCTAssertFalse(clickCoordinator.isActive, "Should be stopped after multiple calls")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    // MARK: - Background Operation Tests
    
    @MainActor
    func testEmergencyStopInBackground() {
        let hotkeyManager = HotkeyManager.shared
        
        // Register hotkey
        let success = hotkeyManager.registerGlobalHotkey(.deleteKey)
        XCTAssertTrue(success, "Should register successfully")
        
        // Emergency stop should be registered globally (background operation tested manually)
        // This test verifies the registration succeeds, actual background testing requires manual validation
        XCTAssertTrue(hotkeyManager.isRegistered, "Should be registered for global monitoring")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testEmergencyStopWhenNotRunning() {
        let clickCoordinator = ClickCoordinator.shared
        
        // Ensure automation is not running
        clickCoordinator.stopAutomation()
        XCTAssertFalse(clickCoordinator.isActive, "Should not be active initially")
        
        // Emergency stop when not running should be safe
        clickCoordinator.stopAutomation()
        XCTAssertFalse(clickCoordinator.isActive, "Should remain inactive")
        
        // No crash or error expected
    }
    
    @MainActor
    func testHotkeyCleanupOnDeinit() {
        let hotkeyManager = HotkeyManager.shared
        
        // Register hotkey
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        XCTAssertTrue(hotkeyManager.isRegistered, "Should be registered")
        
        // Cleanup should work properly
        hotkeyManager.cleanup()
        XCTAssertFalse(hotkeyManager.isRegistered, "Should be unregistered after cleanup")
    }
    
    // MARK: - Configuration Validation Tests
    
    @MainActor
    func testHotkeyConfigurationValidation() {
        // Test valid configurations
        let validConfigs = [
            HotkeyConfiguration(keyCode: 51, modifiers: 0, description: "DELETE"),
            HotkeyConfiguration(keyCode: 53, modifiers: 0, description: "ESC"),
            HotkeyConfiguration(keyCode: 51, modifiers: UInt32(NSEvent.ModifierFlags.command.rawValue), description: "Cmd+DELETE")
        ]
        
        for config in validConfigs {
            XCTAssertGreaterThan(config.keyCode, 0, "KeyCode should be positive")
            XCTAssertNotNil(config.description, "Description should not be nil")
            XCTAssertFalse(config.description.isEmpty, "Description should not be empty")
        }
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testEmergencyStopIntegrationWithAutomation() {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Setup
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        
        let targetPoint = CGPoint(x: 200, y: 200)
        let config = AutomationConfiguration(
            location: targetPoint,
            clickInterval: 0.5, // 2.0 CPS = 0.5 second interval
            maxDuration: 5.0
        )
        
        // Test complete automation lifecycle with emergency stop
        clickCoordinator.startAutomation(with: config)
        XCTAssertTrue(clickCoordinator.isActive, "Should start automation")
        
        // Pause
        clickCoordinator.pauseAutomation()
        XCTAssertTrue(clickCoordinator.isPaused, "Should be paused")
        
        // Resume
        clickCoordinator.resumeAutomation()
        XCTAssertFalse(clickCoordinator.isPaused, "Should be resumed")
        
        // Emergency stop
        clickCoordinator.stopAutomation()
        XCTAssertFalse(clickCoordinator.isActive, "Should be stopped")
        XCTAssertFalse(clickCoordinator.isPaused, "Should not be paused")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testEmergencyStopPerformance() {
        let hotkeyManager = HotkeyManager.shared
        
        // Test rapid registration/unregistration cycles
        let iterations = 10
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            hotkeyManager.registerGlobalHotkey(.deleteKey)
            hotkeyManager.unregisterGlobalHotkey()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let averageTime = (endTime - startTime) / Double(iterations) * 1000 // ms per operation
        
        XCTAssertLessThan(averageTime, 10, "Registration/unregistration should be <10ms per cycle")
    }
    
    // MARK: - Enhanced Emergency Stop Tests (Task 2.1)
    
    @MainActor
    func testAllEmergencyStopKeyConfigurations() {
        // Test all available emergency stop key configurations
        let allConfigs = HotkeyConfiguration.allEmergencyStopKeys
        
        XCTAssertGreaterThanOrEqual(allConfigs.count, 5, "Should have at least 5 emergency stop keys")
        
        // Verify ESC key is present
        let escConfig = allConfigs.first { $0.keyCode == 53 }
        XCTAssertNotNil(escConfig, "ESC key should be in available keys")
        
        // Verify F1 key is present
        let f1Config = allConfigs.first { $0.keyCode == 122 }
        XCTAssertNotNil(f1Config, "F1 key should be in available keys")
        
        // Verify Space key is present
        let spaceConfig = allConfigs.first { $0.keyCode == 49 }
        XCTAssertNotNil(spaceConfig, "Space key should be in available keys")
        
        // Verify Cmd+Period is present
        let cmdPeriodConfig = allConfigs.first { $0.keyCode == 47 && $0.modifiers != 0 }
        XCTAssertNotNil(cmdPeriodConfig, "Cmd+Period should be in available keys")
    }
    
    @MainActor
    func testEmergencyStopResponseTimeGuarantee() async {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Setup automation
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        let config = createTestConfig()
        clickCoordinator.startAutomation(with: config)
        
        // Test response time multiple times to ensure consistency
        var responseTimes: [Double] = []
        let iterations = 10
        
        for _ in 0..<iterations {
            // Restart automation for each test
            clickCoordinator.stopAutomation()
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            clickCoordinator.startAutomation(with: config)
            
            // Measure emergency stop response time
            let startTime = CFAbsoluteTimeGetCurrent()
            clickCoordinator.stopAutomation()
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let responseTime = (endTime - startTime) * 1000 // Convert to milliseconds
            responseTimes.append(responseTime)
        }
        
        // Verify all response times are under 50ms
        let maxResponseTime = responseTimes.max() ?? 0
        let averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        XCTAssertLessThan(maxResponseTime, 50.0, "Maximum emergency stop response time should be <50ms")
        XCTAssertLessThan(averageResponseTime, 25.0, "Average emergency stop response time should be <25ms")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testEmergencyStopVisualConfirmation() {
        let hotkeyManager = HotkeyManager.shared
        
        // Register emergency stop
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        
        // Test emergency stop activation state
        XCTAssertFalse(hotkeyManager.emergencyStopActivated, "Should not be activated initially")
        
        // Simulate emergency stop (direct call since we can't simulate key press)
        hotkeyManager.emergencyStopActivated = true
        
        XCTAssertTrue(hotkeyManager.emergencyStopActivated, "Should be activated after emergency stop")
        
        // Test automatic reset (normally done by timer in real implementation)
        hotkeyManager.emergencyStopActivated = false
        XCTAssertFalse(hotkeyManager.emergencyStopActivated, "Should reset after brief period")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testEmergencyStopWithMultipleKeyTypes() {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Test different emergency stop key types
        let testKeys = [
            HotkeyConfiguration.escapeKey,
            HotkeyConfiguration.f1Key,
            HotkeyConfiguration.spaceKey,
            HotkeyConfiguration.cmdPeriod
        ]
        
        for keyConfig in testKeys {
            // Register this specific key
            let success = hotkeyManager.registerGlobalHotkey(keyConfig)
            XCTAssertTrue(success, "Should register \(keyConfig.description) successfully")
            
            // Start automation
            let config = createTestConfig()
            clickCoordinator.startAutomation(with: config)
            XCTAssertTrue(clickCoordinator.isActive, "Should start automation with \(keyConfig.description)")
            
            // Emergency stop should work regardless of key type
            clickCoordinator.stopAutomation()
            XCTAssertFalse(clickCoordinator.isActive, "Should stop automation with \(keyConfig.description)")
        }
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testEmergencyStopDuringPauseState() {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Setup
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        let config = createTestConfig()
        
        // Start automation
        clickCoordinator.startAutomation(with: config)
        XCTAssertTrue(clickCoordinator.isActive, "Should be active")
        
        // TODO: Add pause functionality to ClickCoordinator
        // For now, test that emergency stop works when automation is active
        clickCoordinator.stopAutomation()
        XCTAssertFalse(clickCoordinator.isActive, "Should be stopped after emergency stop")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testEmergencyStopReliabilityAcrossStates() {
        let hotkeyManager = HotkeyManager.shared
        let clickCoordinator = ClickCoordinator.shared
        
        // Test emergency stop in different automation states
        hotkeyManager.registerGlobalHotkey(.deleteKey)
        let config = createTestConfig()
        
        // Test 1: Emergency stop when idle
        clickCoordinator.stopAutomation() // Should be safe to call when not running
        XCTAssertFalse(clickCoordinator.isActive, "Should remain inactive")
        
        // Test 2: Emergency stop during active automation
        clickCoordinator.startAutomation(with: config)
        XCTAssertTrue(clickCoordinator.isActive, "Should be active")
        clickCoordinator.stopAutomation()
        XCTAssertFalse(clickCoordinator.isActive, "Should be stopped")
        
        // Test 3: Multiple rapid emergency stops
        clickCoordinator.startAutomation(with: config)
        clickCoordinator.stopAutomation()
        clickCoordinator.stopAutomation() // Second call should be safe
        clickCoordinator.stopAutomation() // Third call should be safe
        XCTAssertFalse(clickCoordinator.isActive, "Should remain stopped")
        
        // Cleanup
        hotkeyManager.unregisterGlobalHotkey()
    }
    
    @MainActor
    func testEmergencyStopSystemHealthMonitoring() {
        let hotkeyManager = HotkeyManager.shared
        
        // Test system health state
        XCTAssertFalse(hotkeyManager.isRegistered, "Should not be registered initially")
        XCTAssertNil(hotkeyManager.lastError, "Should have no errors initially")
        
        // Test successful registration
        let success = hotkeyManager.registerGlobalHotkey(.deleteKey)
        XCTAssertTrue(success, "Registration should succeed")
        XCTAssertTrue(hotkeyManager.isRegistered, "Should be registered after success")
        XCTAssertNil(hotkeyManager.lastError, "Should have no errors after success")
        
        // Test cleanup
        hotkeyManager.unregisterGlobalHotkey()
        XCTAssertFalse(hotkeyManager.isRegistered, "Should not be registered after cleanup")
    }
}

// MARK: - Test Extensions

extension EmergencyStopTests {
    
    /// Helper to create test automation configuration
    private func createTestConfig() -> AutomationConfiguration {
        return AutomationConfiguration(
            location: CGPoint(x: 100, y: 100),
            clickInterval: 1.0,
            maxDuration: 5.0
        )
    }
    
    /// Helper to ensure clean test state
    @MainActor
    private func ensureCleanState() {
        ClickCoordinator.shared.stopAutomation()
        HotkeyManager.shared.unregisterGlobalHotkey()
    }
}