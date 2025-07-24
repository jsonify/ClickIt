//
//  TimerAutomationEngineTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
import CoreGraphics
@testable import ClickIt

@MainActor
final class TimerAutomationEngineTests: XCTestCase {
    
    // MARK: - Properties
    
    var timerEngine: TimerAutomationEngine!
    var mockClickCoordinator: MockClickCoordinator!
    var mockErrorRecoveryManager: MockErrorRecoveryManager!
    var mockPerformanceMonitor: MockPerformanceMonitor!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock objects
        mockClickCoordinator = MockClickCoordinator()
        mockErrorRecoveryManager = MockErrorRecoveryManager()
        mockPerformanceMonitor = MockPerformanceMonitor()
        
        // Create timer engine with mocked dependencies
        timerEngine = TimerAutomationEngine(
            clickCoordinator: mockClickCoordinator,
            errorRecoveryManager: mockErrorRecoveryManager,
            performanceMonitor: mockPerformanceMonitor
        )
    }
    
    override func tearDown() async throws {
        timerEngine?.stopAutomation()
        timerEngine = nil
        mockClickCoordinator = nil
        mockErrorRecoveryManager = nil
        mockPerformanceMonitor = nil
        
        try await super.tearDown()
    }
    
    // MARK: - State Management Tests
    
    func testAutomationEngineInitialization() {
        // Test initial state
        XCTAssertEqual(timerEngine.automationState, .idle)
        XCTAssertNil(timerEngine.currentSession)
        XCTAssertNotNil(timerEngine.getCurrentStatus())
        XCTAssertEqual(timerEngine.getCurrentStatus().state, .idle)
    }
    
    func testStartAutomationTransition() {
        // Given
        let configuration = createTestConfiguration()
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Then
        XCTAssertEqual(timerEngine.automationState, .running)
        XCTAssertNotNil(timerEngine.currentSession)
        XCTAssertEqual(timerEngine.currentSession?.configuration.clickInterval, configuration.clickInterval)
        XCTAssertTrue(mockPerformanceMonitor.startMonitoringCalled)
    }
    
    func testStartAutomationFromNonIdleStateFails() {
        // Given
        let configuration = createTestConfiguration()
        timerEngine.startAutomation(with: configuration)
        XCTAssertEqual(timerEngine.automationState, .running)
        
        // When - try to start again
        let secondConfiguration = createTestConfiguration(interval: 2.0)
        timerEngine.startAutomation(with: secondConfiguration)
        
        // Then - should still be running with original configuration
        XCTAssertEqual(timerEngine.automationState, .running)
        XCTAssertEqual(timerEngine.currentSession?.configuration.clickInterval, configuration.clickInterval)
    }
    
    func testPauseAutomationPreservesState() {
        // Given
        let configuration = createTestConfiguration()
        timerEngine.startAutomation(with: configuration)
        
        // Wait for some execution
        let expectation = expectation(description: "Wait for automation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // When
        timerEngine.pauseAutomation()
        
        // Then
        XCTAssertEqual(timerEngine.automationState, .paused)
        XCTAssertNotNil(timerEngine.currentSession)
        XCTAssertTrue(timerEngine.currentSession?.isActive ?? false)
        
        // Verify session was paused
        let session = timerEngine.currentSession!
        XCTAssertGreaterThan(session.pauseHistory.count, 0)
    }
    
    func testResumeAutomationContinuesCorrectly() {
        // Given
        let configuration = createTestConfiguration()
        timerEngine.startAutomation(with: configuration)
        timerEngine.pauseAutomation()
        XCTAssertEqual(timerEngine.automationState, .paused)
        
        // When
        timerEngine.resumeAutomation()
        
        // Then
        XCTAssertEqual(timerEngine.automationState, .running)
        XCTAssertNotNil(timerEngine.currentSession)
        
        // Verify pause interval was completed
        let session = timerEngine.currentSession!
        XCTAssertGreaterThan(session.pauseHistory.count, 0)
        XCTAssertNotNil(session.pauseHistory.last?.endTime)
    }
    
    func testStopAutomationCleansUpResources() {
        // Given
        let configuration = createTestConfiguration()
        timerEngine.startAutomation(with: configuration)
        XCTAssertEqual(timerEngine.automationState, .running)
        
        // When
        timerEngine.stopAutomation()
        
        // Then
        XCTAssertEqual(timerEngine.automationState, .idle)
        XCTAssertNotNil(timerEngine.currentSession) // Session preserved for statistics
        XCTAssertFalse(timerEngine.currentSession?.isActive ?? true) // But marked as inactive
    }
    
    func testEmergencyStopImmediateTermination() {
        // Given
        let configuration = createTestConfiguration()
        timerEngine.startAutomation(with: configuration)
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        timerEngine.emergencyStopAutomation()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        let responseTime = (endTime - startTime) * 1000 // Convert to milliseconds
        XCTAssertLessThan(responseTime, 50, "Emergency stop must complete within 50ms")
        XCTAssertEqual(timerEngine.automationState, .idle)
        XCTAssertTrue(mockClickCoordinator.emergencyStopCalled)
    }
    
    func testInvalidStateTransitions() {
        // Test pause from idle
        timerEngine.pauseAutomation()
        XCTAssertEqual(timerEngine.automationState, .idle)
        
        // Test resume from idle
        timerEngine.resumeAutomation()
        XCTAssertEqual(timerEngine.automationState, .idle)
        
        // Test resume from running
        let configuration = createTestConfiguration()
        timerEngine.startAutomation(with: configuration)
        timerEngine.resumeAutomation()
        XCTAssertEqual(timerEngine.automationState, .running)
    }
    
    // MARK: - Timing Accuracy Tests
    
    func testTimingPrecisionWithinTolerance() async {
        // Given
        let configuration = createTestConfiguration(interval: 0.1) // 100ms
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for several timer cycles
        let expectation = expectation(description: "Wait for timer cycles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        let timingAccuracy = timerEngine.getTimingAccuracy()
        XCTAssertNotNil(timingAccuracy)
        
        if let accuracy = timingAccuracy {
            XCTAssertLessThanOrEqual(accuracy.meanError, 0.002, "Mean timing error should be within 2ms")
            XCTAssertLessThanOrEqual(accuracy.maxError, 0.010, "Max timing error should be within 10ms")
            XCTAssertTrue(accuracy.isWithinTolerance, "Timing should be within acceptable tolerance")
        }
        
        timerEngine.stopAutomation()
    }
    
    func testHighFrequencyCPSAccuracy() async {
        // Given - High frequency test (20 CPS = 50ms interval)
        let configuration = createTestConfiguration(interval: 0.05)
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for execution
        let expectation = expectation(description: "Wait for high frequency execution")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        let timingAccuracy = timerEngine.getTimingAccuracy()
        XCTAssertNotNil(timingAccuracy)
        
        if let accuracy = timingAccuracy {
            XCTAssertGreaterThan(accuracy.measurements, 3, "Should have multiple measurements")
            XCTAssertLessThan(accuracy.standardDeviation, 0.005, "Standard deviation should be low")
        }
        
        timerEngine.stopAutomation()
    }
    
    func testLowFrequencyCPSStability() async {
        // Given - Low frequency test (1 CPS = 1000ms interval)
        let configuration = createTestConfiguration(interval: 1.0)
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for a few cycles
        let expectation = expectation(description: "Wait for low frequency execution")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        let session = timerEngine.currentSession
        XCTAssertNotNil(session)
        XCTAssertGreaterThanOrEqual(session?.totalClicks ?? 0, 2, "Should have executed at least 2 clicks")
        
        timerEngine.stopAutomation()
    }
    
    func testTimingConsistencyOverTime() async {
        // Given
        let configuration = createTestConfiguration(interval: 0.1)
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Collect timing data over multiple periods
        var timingMeasurements: [TimingAccuracyStats] = []
        
        for i in 0..<3 {
            let expectation = expectation(description: "Wait for measurement \(i)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let accuracy = self.timerEngine.getTimingAccuracy() {
                    timingMeasurements.append(accuracy)
                }
                expectation.fulfill()
            }
            await fulfillment(of: [expectation])
        }
        
        // Then
        XCTAssertEqual(timingMeasurements.count, 3)
        
        let meanErrors = timingMeasurements.map { $0.meanError }
        let maxMeanError = meanErrors.max() ?? 0
        let minMeanError = meanErrors.min() ?? 0
        let errorVariation = maxMeanError - minMeanError
        
        XCTAssertLessThan(errorVariation, 0.001, "Timing consistency should not vary more than 1ms over time")
        
        timerEngine.stopAutomation()
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorRecoveryIntegration() async {
        // Given
        let configuration = createTestConfiguration()
        mockClickCoordinator.shouldFailClicks = true
        mockErrorRecoveryManager.shouldRetry = true
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for error and recovery
        let expectation = expectation(description: "Wait for error recovery")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        XCTAssertTrue(mockErrorRecoveryManager.attemptRecoveryCalled)
        // Engine should continue running despite click failures when recovery is enabled
        XCTAssertEqual(timerEngine.automationState, .running)
        
        timerEngine.stopAutomation()
    }
    
    func testStopOnErrorConfiguration() async {
        // Given
        let configuration = createTestConfiguration(stopOnError: true)
        mockClickCoordinator.shouldFailClicks = true
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for error to occur
        let expectation = expectation(description: "Wait for error stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        XCTAssertEqual(timerEngine.automationState, .idle)
        
        let session = timerEngine.currentSession
        XCTAssertGreaterThan(session?.failedClicks ?? 0, 0)
    }
    
    func testSystemResourceExhaustionHandling() async {
        // Given
        let configuration = createTestConfiguration()
        mockPerformanceMonitor.simulateResourceExhaustion = true
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for resource monitoring
        let expectation = expectation(description: "Wait for resource monitoring")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        let status = timerEngine.getCurrentStatus()
        XCTAssertNotNil(status.performanceMetrics)
        // Engine should continue but may show performance warnings
        
        timerEngine.stopAutomation()
    }
    
    // MARK: - Session Statistics Tests
    
    func testSessionStatisticsAccuracy() async {
        // Given
        let configuration = createTestConfiguration(interval: 0.1)
        mockClickCoordinator.successRate = 0.8 // 80% success rate
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for multiple clicks
        let expectation = expectation(description: "Wait for statistics")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        let statistics = timerEngine.getSessionStatistics()
        XCTAssertNotNil(statistics)
        
        if let stats = statistics {
            XCTAssertGreaterThan(stats.totalClicks, 0)
            XCTAssertGreaterThanOrEqual(stats.successRate, 0.7) // Allow some variance
            XCTAssertLessThanOrEqual(stats.successRate, 0.9)
            XCTAssertGreaterThan(stats.clicksPerSecond, 0)
        }
        
        timerEngine.stopAutomation()
    }
    
    func testSessionStatisticsPreservationAcrossPauseResume() async {
        // Given
        let configuration = createTestConfiguration(interval: 0.1)
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for some clicks
        let expectation1 = expectation(description: "Wait before pause")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1])
        
        let statsBeforePause = timerEngine.getSessionStatistics()
        let clicksBeforePause = statsBeforePause?.totalClicks ?? 0
        
        // Pause and resume
        timerEngine.pauseAutomation()
        timerEngine.resumeAutomation()
        
        // Wait for more clicks
        let expectation2 = expectation(description: "Wait after resume")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation2.fulfill()
        }
        await fulfillment(of: [expectation2])
        
        // Then
        let statsAfterResume = timerEngine.getSessionStatistics()
        XCTAssertNotNil(statsAfterResume)
        
        if let stats = statsAfterResume {
            XCTAssertGreaterThan(stats.totalClicks, clicksBeforePause)
            XCTAssertGreaterThan(stats.duration, 0)
        }
        
        timerEngine.stopAutomation()
    }
    
    // MARK: - Duration and Click Limits Tests
    
    func testClickLimitAutomaticStopping() async {
        // Given
        let configuration = createTestConfiguration(interval: 0.05, maxClicks: 3)
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for click limit to be reached
        let expectation = expectation(description: "Wait for click limit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        XCTAssertEqual(timerEngine.automationState, .idle)
        
        let session = timerEngine.currentSession
        XCTAssertLessThanOrEqual(session?.totalClicks ?? 0, 3)
    }
    
    func testDurationLimitAutomaticStopping() async {
        // Given
        let configuration = createTestConfiguration(interval: 0.05, maxDuration: 0.2) // 200ms
        
        // When
        timerEngine.startAutomation(with: configuration)
        
        // Wait for duration limit to be reached
        let expectation = expectation(description: "Wait for duration limit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
        
        // Then
        XCTAssertEqual(timerEngine.automationState, .idle)
        
        let session = timerEngine.currentSession
        XCTAssertLessThanOrEqual(session?.duration ?? 0, 0.3) // Allow some tolerance
    }
    
    // MARK: - Helper Methods
    
    private func createTestConfiguration(
        interval: TimeInterval = 0.1,
        maxClicks: Int? = nil,
        maxDuration: TimeInterval? = nil,
        stopOnError: Bool = false
    ) -> AutomationConfiguration {
        return AutomationConfiguration(
            location: CGPoint(x: 100, y: 100),
            clickType: .left,
            clickInterval: interval,
            targetApplication: nil,
            maxClicks: maxClicks,
            maxDuration: maxDuration,
            stopOnError: stopOnError,
            randomizeLocation: false,
            locationVariance: 0,
            useDynamicMouseTracking: false,
            cpsRandomizerConfig: CPSRandomizer.Configuration()
        )
    }
}

// MARK: - Mock Objects

/// Mock ClickCoordinator for testing
@MainActor
class MockClickCoordinator: ClickCoordinatorProtocol {
    var shouldFailClicks = false
    var successRate: Double = 1.0
    var emergencyStopCalled = false
    
    private var clickCount = 0
    
    func performSingleClick(configuration: ClickConfiguration) async -> ClickResult {
        clickCount += 1
        
        let shouldSucceed = shouldFailClicks ? (Double.random(in: 0...1) < successRate) : true
        
        return ClickResult(
            success: shouldSucceed,
            actualLocation: configuration.location,
            timestamp: CFAbsoluteTimeGetCurrent(),
            error: shouldSucceed ? nil : .eventPostingFailed
        )
    }
    
    func emergencyStopAutomation() {
        emergencyStopCalled = true
    }
}

/// Mock ErrorRecoveryManager for testing
class MockErrorRecoveryManager: ErrorRecoveryManagerProtocol {
    var shouldRetry = false
    var attemptRecoveryCalled = false
    
    func attemptRecovery(for context: ErrorContext) async -> RecoveryAction {
        attemptRecoveryCalled = true
        
        return RecoveryAction(
            strategy: .automaticRetry,
            shouldRetry: shouldRetry,
            retryDelay: 0.01
        )
    }
}

/// Mock PerformanceMonitor for testing
@MainActor
class MockPerformanceMonitor: PerformanceMonitorProtocol {
    var startMonitoringCalled = false
    var simulateResourceExhaustion = false
    var isMonitoring = false
    
    func startMonitoring() {
        startMonitoringCalled = true
        isMonitoring = true
    }
    
    func getPerformanceReport() -> PerformanceReport {
        if simulateResourceExhaustion {
            return PerformanceReport(
                memoryUsageMB: 45.0,
                cpuUsage: 0.8,
                isOptimal: false,
                timestamp: Date()
            )
        } else {
            return PerformanceReport(
                memoryUsageMB: 20.0,
                cpuUsage: 0.02,
                isOptimal: true,
                timestamp: Date()
            )
        }
    }
}