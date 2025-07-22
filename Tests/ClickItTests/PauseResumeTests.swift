//
//  PauseResumeTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-22.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
import Combine
@testable import ClickIt

final class PauseResumeTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - ClickItViewModel Pause/Resume State Tests
    
    @MainActor
    func testInitialPauseState() {
        let viewModel = ClickItViewModel()
        
        XCTAssertFalse(viewModel.isPaused, "ViewModel should not be paused initially")
        XCTAssertFalse(viewModel.isRunning, "ViewModel should not be running initially")
        XCTAssertTrue(viewModel.canPause == false, "Should not be able to pause when not running")
        XCTAssertTrue(viewModel.canResume == false, "Should not be able to resume when not running")
    }
    
    @MainActor
    func testPauseButtonAvailability() {
        let viewModel = ClickItViewModel()
        
        // Initially should not be able to pause or resume
        XCTAssertFalse(viewModel.canPause, "Cannot pause when not running")
        XCTAssertFalse(viewModel.canResume, "Cannot resume when not running")
        
        // Set up mock target point to enable automation
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        // After starting, should be able to pause
        viewModel.startAutomationForTesting()
        XCTAssertTrue(viewModel.canPause, "Should be able to pause when running")
        XCTAssertFalse(viewModel.canResume, "Should not be able to resume when running (not paused)")
        
        // After pausing, should be able to resume
        viewModel.pauseAutomation()
        XCTAssertFalse(viewModel.canPause, "Should not be able to pause when already paused")
        XCTAssertTrue(viewModel.canResume, "Should be able to resume when paused")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    @MainActor
    func testPauseActionWhenRunning() {
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        viewModel.startAutomationForTesting()
        XCTAssertTrue(viewModel.isRunning, "Should be running after start")
        
        viewModel.pauseAutomation()
        XCTAssertFalse(viewModel.isRunning, "Should not be running after pause")
        XCTAssertTrue(viewModel.isPaused, "Should be paused after pause action")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    @MainActor
    func testResumeActionWhenPaused() {
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        viewModel.startAutomationForTesting()
        viewModel.pauseAutomation()
        XCTAssertTrue(viewModel.isPaused, "Should be paused")
        
        viewModel.resumeAutomation()
        XCTAssertFalse(viewModel.isPaused, "Should not be paused after resume")
        XCTAssertTrue(viewModel.isRunning, "Should be running after resume")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    @MainActor
    func testStopClearsPauseState() {
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        viewModel.startAutomationForTesting()
        viewModel.pauseAutomation()
        XCTAssertTrue(viewModel.isPaused, "Should be paused")
        
        viewModel.stopAutomation()
        XCTAssertFalse(viewModel.isPaused, "Pause state should be cleared after stop")
        XCTAssertFalse(viewModel.isRunning, "Should not be running after stop")
    }
    
    // MARK: - ElapsedTimeManager Integration Tests
    
    @MainActor
    func testElapsedTimeManagerPauseResume() async {
        let timeManager = ElapsedTimeManager.shared
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        // Start automation and let time elapse
        viewModel.startAutomationForTesting()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let timeBeforePause = timeManager.elapsedTime
        XCTAssertGreaterThan(timeBeforePause, 0.1, "Time should have elapsed before pause")
        
        // Pause and verify time stops progressing
        viewModel.pauseAutomation()
        XCTAssertFalse(timeManager.isTracking, "TimeManager should not be tracking when paused")
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        let timeAfterPause = timeManager.elapsedTime
        XCTAssertEqual(timeAfterPause, timeBeforePause, accuracy: 0.05, "Time should not progress during pause")
        
        // Resume and verify time continues
        viewModel.resumeAutomation()
        XCTAssertTrue(timeManager.isTracking, "TimeManager should be tracking when resumed")
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        let timeAfterResume = timeManager.elapsedTime
        XCTAssertGreaterThan(timeAfterResume, timeAfterPause, "Time should progress after resume")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    @MainActor
    func testSessionTimePreservationDuringPause() async {
        let timeManager = ElapsedTimeManager.shared
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        viewModel.startAutomationForTesting()
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let sessionTimeBeforePause = timeManager.currentSessionTime
        XCTAssertGreaterThan(sessionTimeBeforePause, 0.2, "Session time should accumulate")
        
        // Pause and verify session time is preserved
        viewModel.pauseAutomation()
        let sessionTimeDuringPause = timeManager.currentSessionTime
        XCTAssertEqual(sessionTimeDuringPause, sessionTimeBeforePause, accuracy: 0.05, "Session time should be preserved during pause")
        
        // Wait and ensure time doesn't progress during pause
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        let sessionTimeStillPaused = timeManager.currentSessionTime
        XCTAssertEqual(sessionTimeStillPaused, sessionTimeBeforePause, accuracy: 0.05, "Session time should remain constant during pause")
        
        // Resume and verify time continues from preserved point
        viewModel.resumeAutomation()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let sessionTimeAfterResume = timeManager.currentSessionTime
        XCTAssertGreaterThan(sessionTimeAfterResume, sessionTimeBeforePause, "Session time should continue from pause point")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    // MARK: - ClickCoordinator Integration Tests
    
    @MainActor
    func testClickCoordinatorPauseIntegration() {
        let coordinator = ClickCoordinator.shared
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        // Start automation
        viewModel.startAutomationForTesting()
        XCTAssertTrue(coordinator.isActive, "Coordinator should be active when automation starts")
        
        // Pause should stop coordinator
        viewModel.pauseAutomation()
        XCTAssertFalse(coordinator.isActive, "Coordinator should be inactive when paused")
        
        // Resume should restart coordinator
        viewModel.resumeAutomation()
        XCTAssertTrue(coordinator.isActive, "Coordinator should be active when resumed")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    @MainActor
    func testStatisticsPreservationDuringPause() async {
        let coordinator = ClickCoordinator.shared
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        viewModel.startAutomationForTesting()
        
        // Let some clicks happen
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let statisticsBeforePause = coordinator.getSessionStatistics()
        let clickCountBeforePause = statisticsBeforePause.totalClicks
        
        // Pause and verify statistics are preserved
        viewModel.pauseAutomation()
        let statisticsDuringPause = coordinator.getSessionStatistics()
        XCTAssertEqual(statisticsDuringPause.totalClicks, clickCountBeforePause, "Click count should be preserved during pause")
        XCTAssertFalse(statisticsDuringPause.isActive, "Statistics should show inactive during pause")
        
        // Resume and verify statistics continue from preserved state
        viewModel.resumeAutomation()
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let statisticsAfterResume = coordinator.getSessionStatistics()
        XCTAssertGreaterThanOrEqual(statisticsAfterResume.totalClicks, clickCountBeforePause, "Click count should continue from pause point")
        XCTAssertTrue(statisticsAfterResume.isActive, "Statistics should show active after resume")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func testPauseWhenNotRunning() {
        let viewModel = ClickItViewModel()
        
        // Should not crash or change state when pausing while not running
        viewModel.pauseAutomation()
        XCTAssertFalse(viewModel.isPaused, "Should not be paused when wasn't running")
        XCTAssertFalse(viewModel.isRunning, "Should not be running")
    }
    
    @MainActor
    func testResumeWhenNotPaused() {
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        // Resume when not paused should not start automation
        viewModel.resumeAutomation()
        XCTAssertFalse(viewModel.isRunning, "Should not start running from resume when not paused")
        
        // But if running and not paused, resume should be no-op
        viewModel.startAutomationForTesting()
        XCTAssertTrue(viewModel.isRunning, "Should be running after start")
        
        viewModel.resumeAutomation()
        XCTAssertTrue(viewModel.isRunning, "Should still be running after resume")
        XCTAssertFalse(viewModel.isPaused, "Should not be paused")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    @MainActor
    func testMultiplePauseCalls() {
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        viewModel.startAutomationForTesting()
        viewModel.pauseAutomation()
        XCTAssertTrue(viewModel.isPaused, "Should be paused after first pause")
        
        // Multiple pause calls should not change state
        viewModel.pauseAutomation()
        viewModel.pauseAutomation()
        XCTAssertTrue(viewModel.isPaused, "Should remain paused after multiple pause calls")
        XCTAssertFalse(viewModel.isRunning, "Should not be running")
        
        // Clean up
        viewModel.stopAutomation()
    }
    
    @MainActor
    func testMultipleResumeCalls() {
        let viewModel = ClickItViewModel()
        viewModel.setTargetPoint(CGPoint(x: 100, y: 100))
        
        viewModel.startAutomationForTesting()
        viewModel.pauseAutomation()
        viewModel.resumeAutomation()
        XCTAssertFalse(viewModel.isPaused, "Should not be paused after resume")
        XCTAssertTrue(viewModel.isRunning, "Should be running after resume")
        
        // Multiple resume calls should not change state
        viewModel.resumeAutomation()
        viewModel.resumeAutomation()
        XCTAssertFalse(viewModel.isPaused, "Should remain not paused after multiple resume calls")
        XCTAssertTrue(viewModel.isRunning, "Should remain running")
        
        // Clean up
        viewModel.stopAutomation()
    }
}