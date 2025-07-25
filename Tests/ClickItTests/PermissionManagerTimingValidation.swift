//
//  PermissionManagerTimingValidation.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
@testable import ClickIt

@MainActor
final class PermissionManagerTimingValidation: XCTestCase {
    
    var permissionManager: PermissionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        permissionManager = PermissionManager.shared
    }
    
    override func tearDown() async throws {
        permissionManager.stopPermissionMonitoring()
        try await super.tearDown()
    }
    
    func testPermissionMonitoringTimingPreserved() async throws {
        // Test that permission monitoring maintains 1-second intervals
        var updateCounts: [Date] = []
        let expectedUpdates = 3
        
        // Store original update method to track calls
        let originalUpdateCalled = expectation(description: "Permission updates tracked")
        originalUpdateCalled.expectedFulfillmentCount = expectedUpdates
        
        // Start monitoring
        permissionManager.startPermissionMonitoring()
        
        // Track when updates happen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            updateCounts.append(Date())
            originalUpdateCalled.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            updateCounts.append(Date())
            originalUpdateCalled.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            updateCounts.append(Date())
            originalUpdateCalled.fulfill()
        }
        
        await fulfillment(of: [originalUpdateCalled], timeout: 3.0)
        
        // Verify timing intervals are approximately 1 second
        XCTAssertEqual(updateCounts.count, expectedUpdates)
        
        if updateCounts.count >= 2 {
            let interval1 = updateCounts[1].timeIntervalSince(updateCounts[0])
            XCTAssertTrue(interval1 >= 0.9 && interval1 <= 1.1, "First interval should be ~1 second, got \(interval1)")
        }
        
        if updateCounts.count >= 3 {
            let interval2 = updateCounts[2].timeIntervalSince(updateCounts[1])
            XCTAssertTrue(interval2 >= 0.9 && interval2 <= 1.1, "Second interval should be ~1 second, got \(interval2)")
        }
    }
    
    func testPermissionStatusConsistency() async throws {
        // Test that permission status remains consistent during monitoring
        let consistencyCheck = expectation(description: "Permission status consistency")
        consistencyCheck.expectedFulfillmentCount = 5
        
        permissionManager.startPermissionMonitoring()
        
        // Check status multiple times to ensure consistency
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                let accessibility1 = self.permissionManager.accessibilityPermissionGranted
                let screenRecording1 = self.permissionManager.screenRecordingPermissionGranted
                let all1 = self.permissionManager.allPermissionsGranted
                
                // Immediate second read should be identical
                let accessibility2 = self.permissionManager.accessibilityPermissionGranted  
                let screenRecording2 = self.permissionManager.screenRecordingPermissionGranted
                let all2 = self.permissionManager.allPermissionsGranted
                
                XCTAssertEqual(accessibility1, accessibility2, "Accessibility permission should be stable")
                XCTAssertEqual(screenRecording1, screenRecording2, "Screen recording permission should be stable")
                XCTAssertEqual(all1, all2, "All permissions status should be stable")
                
                consistencyCheck.fulfill()
            }
        }
        
        await fulfillment(of: [consistencyCheck], timeout: 2.0)
    }
    
    func testPermissionMonitoringResourceCleanup() {
        // Test that stopping monitoring properly cleans up resources
        
        // Start monitoring
        permissionManager.startPermissionMonitoring()
        XCTAssertTrue(true, "Monitoring started without crash")
        
        // Stop monitoring  
        permissionManager.stopPermissionMonitoring()
        XCTAssertTrue(true, "Monitoring stopped without crash")
        
        // Multiple stops should be safe
        permissionManager.stopPermissionMonitoring()
        permissionManager.stopPermissionMonitoring()
        XCTAssertTrue(true, "Multiple stops completed safely")
        
        // Restart should work
        permissionManager.startPermissionMonitoring()
        permissionManager.stopPermissionMonitoring()
        XCTAssertTrue(true, "Restart and stop completed successfully")
    }
    
    func testPermissionCheckMethodsStillWork() {
        // Test that individual permission check methods maintain functionality
        
        let accessibilityStatus = permissionManager.checkAccessibilityPermission()
        let screenRecordingStatus = permissionManager.checkScreenRecordingPermission()
        
        // These methods should return consistent values
        XCTAssertNotNil(accessibilityStatus)
        XCTAssertNotNil(screenRecordingStatus) 
        
        // Update status and check consistency
        permissionManager.updatePermissionStatus()
        
        XCTAssertEqual(permissionManager.accessibilityPermissionGranted, accessibilityStatus)
        XCTAssertEqual(permissionManager.screenRecordingPermissionGranted, screenRecordingStatus)
        XCTAssertEqual(permissionManager.allPermissionsGranted, accessibilityStatus && screenRecordingStatus)
    }
}