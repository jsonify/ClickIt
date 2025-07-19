//
//  ElapsedTimeManagerTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-19.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
import Combine
@testable import ClickIt

final class ElapsedTimeManagerTests: XCTestCase {
    
    // MARK: - Basic Functionality Tests
    
    @MainActor
    func testInitialState() {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        XCTAssertFalse(timeManager.isTracking, "Should not be tracking initially")
        XCTAssertEqual(timeManager.elapsedTime, 0, "Initial elapsed time should be 0")
        XCTAssertEqual(timeManager.currentSessionTime, 0, "Initial session time should be 0")
    }
    
    @MainActor
    func testStartTracking() {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        timeManager.startTracking()
        
        XCTAssertTrue(timeManager.isTracking, "Should be tracking after start")
        XCTAssertEqual(timeManager.elapsedTime, 0, accuracy: 0.1, "Elapsed time should be near 0 initially")
        
        timeManager.stopTracking()
    }
    
    @MainActor
    func testStopTracking() {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        timeManager.startTracking()
        timeManager.stopTracking()
        
        XCTAssertFalse(timeManager.isTracking, "Should not be tracking after stop")
        XCTAssertEqual(timeManager.elapsedTime, 0, "Elapsed time should reset to 0 after stop")
        XCTAssertEqual(timeManager.currentSessionTime, 0, "Session time should reset to 0 after stop")
    }
    
    @MainActor
    func testTimeFormatting() {
        let timeManager = ElapsedTimeManager.shared
        
        XCTAssertEqual(timeManager.formatElapsedTime(0), "00:00", "Zero time should format as 00:00")
        XCTAssertEqual(timeManager.formatElapsedTime(30), "00:30", "30 seconds should format as 00:30")
        XCTAssertEqual(timeManager.formatElapsedTime(90), "01:30", "90 seconds should format as 01:30")
        XCTAssertEqual(timeManager.formatElapsedTime(3661), "01:01:01", "3661 seconds should format as 01:01:01")
        XCTAssertEqual(timeManager.formatElapsedTime(7325), "02:02:05", "7325 seconds should format as 02:02:05")
    }
    
    @MainActor
    func testFormattedElapsedTime() {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        timeManager.startTracking()
        
        // Initial format should be 00:00
        XCTAssertEqual(timeManager.formattedElapsedTime, "00:00", "Initial formatted time should be 00:00")
        
        timeManager.stopTracking()
    }
    
    @MainActor
    func testElapsedTimeProgress() async {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        timeManager.startTracking()
        
        // Wait a bit and check that time has progressed
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let elapsed = timeManager.elapsedTime
        XCTAssertGreaterThan(elapsed, 0.2, "Elapsed time should be at least 0.2 seconds")
        XCTAssertLessThan(elapsed, 0.5, "Elapsed time should be less than 0.5 seconds")
        
        timeManager.stopTracking()
    }
    
    @MainActor
    func testDoubleStartPrevention() {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        timeManager.startTracking()
        let wasTrackingAfterFirst = timeManager.isTracking
        
        // Try to start again
        timeManager.startTracking()
        
        XCTAssertTrue(wasTrackingAfterFirst, "Should be tracking after first start")
        XCTAssertTrue(timeManager.isTracking, "Should still be tracking after second start attempt")
        
        timeManager.stopTracking()
    }
    
    @MainActor
    func testMultipleStopCalls() {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        timeManager.startTracking()
        timeManager.stopTracking()
        timeManager.stopTracking() // Should not crash
        
        XCTAssertFalse(timeManager.isTracking, "Should remain stopped")
        XCTAssertEqual(timeManager.elapsedTime, 0, "Should remain at 0")
    }
    
    @MainActor
    func testCurrentSessionTimeWhenNotTracking() {
        let timeManager = ElapsedTimeManager.shared
        timeManager.stopTracking() // Ensure clean state
        
        XCTAssertEqual(timeManager.currentSessionTime, 0, "currentSessionTime should be 0 when not tracking")
    }
}