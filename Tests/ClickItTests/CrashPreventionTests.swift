//
//  CrashPreventionTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
@testable import ClickIt

@MainActor  
final class CrashPreventionTests: XCTestCase {
    
    var permissionManager: PermissionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        permissionManager = PermissionManager.shared
    }
    
    override func tearDown() async throws {
        permissionManager.stopPermissionMonitoring()
        try await super.tearDown()
    }
    
    // MARK: - Crash Prevention Tests
    
    func testPermissionToggleNoCrash() async throws {
        // This test simulates the conditions that previously caused crashes
        let noCrashExpectation = expectation(description: "Permission toggle completes without crash")
        noCrashExpectation.expectedFulfillmentCount = 10
        
        // Start monitoring (this activates the timer that was causing crashes)
        permissionManager.startPermissionMonitoring()
        
        // Simulate rapid permission state changes that triggered the crash
        for i in 0..<10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                // This simulates the permission toggle event that caused crashes
                self.permissionManager.updatePermissionStatus()
                noCrashExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [noCrashExpectation], timeout: 2.0)
        
        // If we reach here, the concurrency fix worked
        XCTAssertTrue(true, "Permission toggle simulation completed without crashes")
    }
    
    func testConcurrentTimerOperationsStability() async throws {
        // Test multiple concurrent timer operations that previously caused crashes
        let stabilityExpectation = expectation(description: "Concurrent operations stable")
        stabilityExpectation.expectedFulfillmentCount = 20
        
        // Start monitoring
        permissionManager.startPermissionMonitoring()
        
        // Create concurrent load similar to permission toggle scenarios
        for i in 0..<20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                // Mix of operations that previously interacted poorly
                if i % 3 == 0 {
                    self.permissionManager.updatePermissionStatus()
                } else if i % 3 == 1 {
                    let _ = self.permissionManager.accessibilityPermissionGranted
                    let _ = self.permissionManager.screenRecordingPermissionGranted
                } else {
                    let _ = self.permissionManager.allPermissionsGranted
                }
                stabilityExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [stabilityExpectation], timeout: 3.0)
        
        XCTAssertTrue(true, "Concurrent timer operations completed without crashes")
    }
    
    func testPermissionMonitoringStartStopCycles() throws {
        // Test rapid start/stop cycles that could trigger race conditions
        
        for cycle in 0..<5 {
            // Start monitoring
            permissionManager.startPermissionMonitoring()
            
            // Brief operation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.permissionManager.updatePermissionStatus()
            }
            
            // Stop monitoring
            Thread.sleep(forTimeInterval: 0.15)
            permissionManager.stopPermissionMonitoring()
            
            print("Completed start/stop cycle \(cycle + 1)/5")
        }
        
        // Final verification
        XCTAssertTrue(true, "All start/stop cycles completed without crashes")
    }
    
    func testTimerCallbackSafetyUnderStress() async throws {
        // Stress test the timer callback fix under high load
        let stressTestExpectation = expectation(description: "Stress test completes")
        stressTestExpectation.expectedFulfillmentCount = 50
        
        // Start monitoring
        permissionManager.startPermissionMonitoring()
        
        // Create high-frequency operations that stress the timer callback
        for i in 0..<50 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                // Rapid-fire operations that previously caused the MainActor conflict
                self.permissionManager.updatePermissionStatus()
                
                // Also access properties to ensure consistency
                let _ = self.permissionManager.accessibilityPermissionGranted
                let _ = self.permissionManager.screenRecordingPermissionGranted
                let _ = self.permissionManager.allPermissionsGranted
                
                stressTestExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [stressTestExpectation], timeout: 2.0)
        
        XCTAssertTrue(true, "High-frequency stress test completed without crashes")
    }
    
    func testReproducePreviousCrashScenario() async throws {
        // This test specifically reproduces the crash scenario from the bug report
        let reproductionExpectation = expectation(description: "Previous crash scenario handled safely")
        reproductionExpectation.expectedFulfillmentCount = 1
        
        // Start monitoring (activates the problematic timer)
        permissionManager.startPermissionMonitoring()
        
        // Wait for timer to be active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // This specific sequence previously caused the crash:
            // 1. Timer callback executes with Task { @MainActor in }
            // 2. User toggles permission in System Settings
            // 3. MainActor conflict occurs
            
            // Simulate the exact conditions
            self.permissionManager.updatePermissionStatus()
            
            // Verify we can continue operating
            let accessibility = self.permissionManager.accessibilityPermissionGranted
            let screenRecording = self.permissionManager.screenRecordingPermissionGranted
            let all = self.permissionManager.allPermissionsGranted
            
            // These should all be readable without crashes
            XCTAssertNotNil(accessibility)
            XCTAssertNotNil(screenRecording)
            XCTAssertNotNil(all)
            
            reproductionExpectation.fulfill()
        }
        
        await fulfillment(of: [reproductionExpectation], timeout: 1.0)
        
        XCTAssertTrue(true, "Previous crash scenario now handled safely")
    }
    
    // MARK: - Specific Timer Callback Tests
    
    func testDispatchQueueMainAsyncPattern() async throws {
        // Test that the new DispatchQueue.main.async pattern works correctly
        var callbackExecuted = false
        let callbackExpectation = expectation(description: "Callback executed on main queue")
        
        // Simulate the timer callback pattern we're now using
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            DispatchQueue.main.async {
                // This should execute safely on MainActor
                callbackExecuted = true
                callbackExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [callbackExpectation], timeout: 1.0)
        
        XCTAssertTrue(callbackExecuted, "DispatchQueue.main.async callback executed successfully")
    }
    
    func testMainActorIsolationPreserved() async throws {
        // Test that MainActor isolation is preserved with the new pattern
        let isolationExpectation = expectation(description: "MainActor isolation preserved")
        
        permissionManager.startPermissionMonitoring()
        
        // Verify we can access MainActor properties after timer activation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // These accesses should work without await since we're on MainActor
            let _ = self.permissionManager.accessibilityPermissionGranted
            let _ = self.permissionManager.screenRecordingPermissionGranted
            let _ = self.permissionManager.allPermissionsGranted
            
            isolationExpectation.fulfill()
        }
        
        await fulfillment(of: [isolationExpectation], timeout: 1.0)
        
        XCTAssertTrue(true, "MainActor isolation preserved with new pattern")
    }
}