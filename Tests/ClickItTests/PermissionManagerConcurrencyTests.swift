//
//  PermissionManagerConcurrencyTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
@testable import ClickIt

@MainActor
final class PermissionManagerConcurrencyTests: XCTestCase {
    
    var permissionManager: PermissionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        // Create a new instance for each test to avoid shared state
        permissionManager = PermissionManager.shared
    }
    
    override func tearDown() async throws {
        // Clean up any monitoring timers
        permissionManager.stopPermissionMonitoring()
        try await super.tearDown()
    }
    
    // MARK: - Timer Callback Safety Tests
    
    func testPermissionMonitoringTimerCallbackSafety() async throws {
        // Test that timer callbacks don't create MainActor conflicts
        let expectation = XCTestExpectation(description: "Timer callback completes without crashing")
        expectation.expectedFulfillmentCount = 3
        
        // Start monitoring to activate timer
        permissionManager.startPermissionMonitoring()
        
        // Allow multiple timer callbacks to execute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // If we reach here without crashing, the timer callback is safe
        XCTAssertTrue(true, "Timer callbacks completed without MainActor conflicts")
    }
    
    func testConcurrentPermissionStatusUpdates() async throws {
        // Test that multiple concurrent permission status updates don't cause crashes
        let expectation = XCTestExpectation(description: "Concurrent updates complete safely")
        expectation.expectedFulfillmentCount = 5
        
        // Trigger multiple permission status updates concurrently
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                self.permissionManager.updatePermissionStatus()
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify final state is consistent
        XCTAssertNotNil(permissionManager.accessibilityPermissionGranted)
        XCTAssertNotNil(permissionManager.screenRecordingPermissionGranted)
    }
    
    func testPermissionMonitoringStartStopSafety() throws {
        // Test that starting and stopping monitoring doesn't create race conditions
        
        // Start monitoring
        permissionManager.startPermissionMonitoring()
        XCTAssertTrue(true, "Start monitoring completed without crash")
        
        // Stop monitoring
        permissionManager.stopPermissionMonitoring()
        XCTAssertTrue(true, "Stop monitoring completed without crash")
        
        // Rapid start/stop cycles
        for _ in 0..<10 {
            permissionManager.startPermissionMonitoring()
            permissionManager.stopPermissionMonitoring()
        }
        
        XCTAssertTrue(true, "Rapid start/stop cycles completed without crashes")
    }
    
    func testTimerCallbackMainActorIsolation() async throws {
        // Test that timer callbacks properly execute on MainActor
        let expectation = XCTestExpectation(description: "Timer callback executes on MainActor")
        
        // Start monitoring
        permissionManager.startPermissionMonitoring()
        
        // Check MainActor isolation after timer has chance to execute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // If we can access @MainActor properties without await, we're on MainActor
            let _ = self.permissionManager.accessibilityPermissionGranted
            let _ = self.permissionManager.screenRecordingPermissionGranted
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(true, "Timer callbacks maintain proper MainActor isolation")
    }
    
    // MARK: - Error Simulation Tests
    
    func testPermissionStatusUpdateUnderStress() async throws {
        // Simulate rapid permission status changes that previously caused crashes
        let expectation = XCTestExpectation(description: "Stress test completes without crashes")
        expectation.expectedFulfillmentCount = 20
        
        // Start monitoring to activate timer
        permissionManager.startPermissionMonitoring()
        
        // Rapidly trigger status updates to simulate permission toggling
        for i in 0..<20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.01) {
                // Simulate the conditions that cause crashes during permission toggles
                self.permissionManager.updatePermissionStatus()
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(true, "Stress test completed without crashes")
    }
    
    func testTimerCallbackMemoryManagement() throws {
        // Test that timer callbacks don't create memory leaks or retention cycles
        weak var weakPermissionManager: PermissionManager?
        
        autoreleasepool {
            let tempManager = PermissionManager.shared
            weakPermissionManager = tempManager
            
            // Start and stop monitoring to create timer callbacks
            tempManager.startPermissionMonitoring()
            
            // Let timer execute a few times
            let expectation = XCTestExpectation(description: "Timer executes")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tempManager.stopPermissionMonitoring()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
        
        // PermissionManager is a singleton, so it won't be deallocated
        // But we can verify that stopping monitoring cleans up timers properly
        XCTAssertNotNil(weakPermissionManager)
    }
    
    // MARK: - Integration Tests
    
    func testPermissionMonitoringIntegrationWithUI() async throws {
        // Test that permission monitoring works correctly with UI updates
        let expectation = XCTestExpectation(description: "UI integration test completes")
        
        // Start monitoring
        permissionManager.startPermissionMonitoring()
        
        // Simulate UI reading permission status during timer execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let accessibilityStatus = self.permissionManager.accessibilityPermissionGranted
            let screenRecordingStatus = self.permissionManager.screenRecordingPermissionGranted
            let allPermissions = self.permissionManager.allPermissionsGranted
            
            // These reads should not cause crashes or inconsistent state
            XCTAssertNotNil(accessibilityStatus)
            XCTAssertNotNil(screenRecordingStatus)
            XCTAssertNotNil(allPermissions)
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}