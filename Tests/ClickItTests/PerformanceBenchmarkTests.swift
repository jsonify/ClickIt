//
//  PerformanceBenchmarkTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
import Foundation
@testable import ClickIt

/// Comprehensive performance benchmark tests for sub-10ms timing accuracy and resource usage
final class PerformanceBenchmarkTests: XCTestCase {
    
    // MARK: - Test Properties
    
    /// High precision timer instance for testing
    private var highPrecisionTimer: HighPrecisionTimer!
    
    /// Performance monitor for resource tracking
    private var performanceMonitor: PerformanceMonitor!
    
    /// Test configuration
    private let testIterations = 1000
    private let targetTimingAccuracy: TimeInterval = 0.010 // 10ms
    private let maxMemoryUsageMB: Double = 50.0
    private let maxCPUUsagePercent: Double = 5.0
    
    override func setUp() {
        super.setUp()
        highPrecisionTimer = HighPrecisionTimer()
        performanceMonitor = PerformanceMonitor.shared
        performanceMonitor.startMonitoring()
    }
    
    override func tearDown() {
        performanceMonitor.stopMonitoring()
        performanceMonitor = nil
        highPrecisionTimer = nil
        super.tearDown()
    }
    
    // MARK: - Timing Accuracy Tests
    
    func testSubTenMillisecondTimingAccuracy() async throws {
        // Test various timing intervals for sub-10ms accuracy
        let testIntervals: [TimeInterval] = [0.001, 0.005, 0.010, 0.050, 0.100]
        
        for interval in testIntervals {
            let results = await benchmarkTimingAccuracy(targetInterval: interval, iterations: testIterations)
            
            // Validate timing accuracy within ±2ms tolerance
            XCTAssertLessThanOrEqual(results.meanError, 0.002, 
                "Mean timing error \(results.meanError * 1000)ms exceeds 2ms tolerance for \(interval * 1000)ms interval")
            
            // Validate 95% of measurements within ±5ms
            let withinTolerance = results.measurements.filter { abs($0 - interval) <= 0.005 }.count
            let tolerancePercentage = Double(withinTolerance) / Double(results.measurements.count)
            XCTAssertGreaterThanOrEqual(tolerancePercentage, 0.95,
                "Only \(tolerancePercentage * 100)% of measurements within 5ms tolerance for \(interval * 1000)ms interval")
            
            // Validate standard deviation is low
            XCTAssertLessThanOrEqual(results.standardDeviation, 0.003,
                "Standard deviation \(results.standardDeviation * 1000)ms too high for \(interval * 1000)ms interval")
        }
    }
    
    func testHighFrequencyTimingStability() async throws {
        // Test timing stability at high frequencies (up to 100 CPS)
        let testFrequencies: [Double] = [10, 25, 50, 75, 100] // CPS
        
        for frequency in testFrequencies {
            let interval = 1.0 / frequency
            let results = await benchmarkTimingAccuracy(targetInterval: interval, iterations: 500)
            
            // Higher frequency should still maintain reasonable accuracy
            let maxAllowedError = min(0.005, interval * 0.1) // 5ms or 10% of interval, whichever is smaller
            XCTAssertLessThanOrEqual(results.meanError, maxAllowedError,
                "High frequency timing error too high at \(frequency) CPS")
            
            // Validate minimal timing drift over duration
            let timingDrift = results.measurements.last! - results.measurements.first!
            XCTAssertLessThanOrEqual(abs(timingDrift), 0.001,
                "Timing drift \(timingDrift * 1000)ms too high at \(frequency) CPS")
        }
    }
    
    func testTimingConsistencyUnderLoad() async throws {
        // Test timing consistency while system is under artificial load
        let loadTask = Task {
            // Create artificial CPU load
            for _ in 0..<10 {
                Task.detached {
                    var counter = 0
                    for _ in 0..<1_000_000 {
                        counter += Int.random(in: 1...100)
                    }
                    return counter
                }
            }
        }
        
        // Wait a moment for load to start
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let results = await benchmarkTimingAccuracy(targetInterval: 0.010, iterations: 200)
        
        loadTask.cancel()
        
        // Timing should remain reasonably accurate even under load
        XCTAssertLessThanOrEqual(results.meanError, 0.005,
            "Timing accuracy degraded too much under load")
        XCTAssertLessThanOrEqual(results.standardDeviation, 0.008,
            "Timing consistency degraded too much under load")
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageWithinLimits() async throws {
        let initialMemory = performanceMonitor.currentMemoryUsageMB
        
        // Start multiple high-frequency timers to stress memory usage
        var timers: [HighPrecisionTimer] = []
        for i in 0..<10 {
            let timer = HighPrecisionTimer()
            timers.append(timer)
            
            timer.startRepeatingTimer(interval: 0.001) {
                // Minimal callback to test memory overhead
                _ = CFAbsoluteTimeGetCurrent()
            }
        }
        
        // Let timers run for a significant duration
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        let peakMemory = performanceMonitor.peakMemoryUsageMB
        let currentMemory = performanceMonitor.currentMemoryUsageMB
        
        // Stop all timers
        for timer in timers {
            timer.stopTimer()
        }
        
        // Wait for cleanup
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        let finalMemory = performanceMonitor.currentMemoryUsageMB
        
        // Validate memory usage stays within limits
        XCTAssertLessThanOrEqual(peakMemory, maxMemoryUsageMB,
            "Peak memory usage \(peakMemory)MB exceeds limit of \(maxMemoryUsageMB)MB")
        
        // Validate memory is properly cleaned up
        let memoryIncrease = finalMemory - initialMemory
        XCTAssertLessThanOrEqual(memoryIncrease, 5.0,
            "Memory leak detected: \(memoryIncrease)MB not cleaned up")
    }
    
    func testMemoryLeakDetection() async throws {
        let iterations = 100
        var memoryMeasurements: [Double] = []
        
        for i in 0..<iterations {
            // Create and destroy timer repeatedly
            let timer = HighPrecisionTimer()
            timer.startRepeatingTimer(interval: 0.001) {
                _ = mach_absolute_time()
            }
            
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            timer.stopTimer()
            
            if i % 10 == 0 {
                // Force garbage collection and measure memory
                autoreleasepool {
                    // Empty pool to encourage cleanup
                }
                memoryMeasurements.append(performanceMonitor.currentMemoryUsageMB)
            }
        }
        
        // Check for memory growth trend
        let initialMemory = memoryMeasurements.first!
        let finalMemory = memoryMeasurements.last!
        let memoryGrowth = finalMemory - initialMemory
        
        XCTAssertLessThanOrEqual(memoryGrowth, 2.0,
            "Memory leak detected: \(memoryGrowth)MB growth over \(iterations) iterations")
        
        // Check that memory usage is relatively stable
        let maxMemory = memoryMeasurements.max()!
        let minMemory = memoryMeasurements.min()!
        let memoryRange = maxMemory - minMemory
        
        XCTAssertLessThanOrEqual(memoryRange, 10.0,
            "Memory usage too unstable: \(memoryRange)MB range")
    }
    
    // MARK: - CPU Usage Tests
    
    func testCPUUsageAtIdle() async throws {
        // Measure CPU usage when application is idle
        performanceMonitor.resetCPUMeasurements()
        
        // Let the system settle into idle state
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let idleCPUUsage = performanceMonitor.averageCPUUsagePercent
        
        XCTAssertLessThanOrEqual(idleCPUUsage, maxCPUUsagePercent,
            "Idle CPU usage \(idleCPUUsage)% exceeds limit of \(maxCPUUsagePercent)%")
    }
    
    func testCPUUsageUnderAutomation() async throws {
        // Measure CPU usage during active automation
        performanceMonitor.resetCPUMeasurements()
        
        let timer = HighPrecisionTimer()
        var clickCount = 0
        
        timer.startRepeatingTimer(interval: 0.010) { // 100 CPS
            clickCount += 1
            // Simulate minimal click processing
            _ = mach_absolute_time()
        }
        
        // Let automation run for measurement period
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        let automationCPUUsage = performanceMonitor.averageCPUUsagePercent
        timer.stopTimer()
        
        // CPU usage should remain reasonable even during automation
        XCTAssertLessThanOrEqual(automationCPUUsage, 25.0,
            "CPU usage during automation \(automationCPUUsage)% too high")
        
        // Verify automation was actually running
        XCTAssertGreaterThan(clickCount, 400,
            "Automation didn't run as expected: only \(clickCount) ticks")
    }
    
    func testCPUEfficiencyOptimization() async throws {
        // Compare CPU usage between optimized and unoptimized approaches
        performanceMonitor.resetCPUMeasurements()
        
        // Test unoptimized approach (baseline)
        let baselineTimer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in
            _ = CFAbsoluteTimeGetCurrent()
        }
        
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        baselineTimer.invalidate()
        let baselineCPUUsage = performanceMonitor.averageCPUUsagePercent
        
        // Reset measurements
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        performanceMonitor.resetCPUMeasurements()
        
        // Test optimized approach
        let optimizedTimer = HighPrecisionTimer()
        optimizedTimer.startRepeatingTimer(interval: 0.001) {
            _ = mach_absolute_time()
        }
        
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        optimizedTimer.stopTimer()
        let optimizedCPUUsage = performanceMonitor.averageCPUUsagePercent
        
        // Optimized approach should use less CPU
        XCTAssertLessThanOrEqual(optimizedCPUUsage, baselineCPUUsage * 0.8,
            "Optimized timer not more efficient: \(optimizedCPUUsage)% vs \(baselineCPUUsage)%")
    }
    
    // MARK: - Integration Performance Tests
    
    func testEndToEndPerformance() async throws {
        // Test complete automation cycle performance
        let coordinator = ClickCoordinator.shared
        
        let testLocation = CGPoint(x: 100, y: 100)
        let config = AutomationConfiguration(
            location: testLocation,
            clickInterval: 0.010, // 100 CPS
            maxClicks: 100
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialMemory = performanceMonitor.currentMemoryUsageMB
        performanceMonitor.resetCPUMeasurements()
        
        // Start automation
        coordinator.startAutomation(with: config)
        
        // Wait for completion
        while coordinator.isActive {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        let finalMemory = performanceMonitor.currentMemoryUsageMB
        let averageCPU = performanceMonitor.averageCPUUsagePercent
        
        // Validate end-to-end performance
        let expectedDuration = 100 * 0.010 // 100 clicks at 10ms intervals
        let timingAccuracy = abs(duration - expectedDuration) / expectedDuration
        
        XCTAssertLessThanOrEqual(timingAccuracy, 0.1,
            "End-to-end timing accuracy \(timingAccuracy * 100)% off target")
        
        let memoryIncrease = finalMemory - initialMemory
        XCTAssertLessThanOrEqual(memoryIncrease, 10.0,
            "End-to-end memory usage increased by \(memoryIncrease)MB")
        
        XCTAssertLessThanOrEqual(averageCPU, 30.0,
            "End-to-end CPU usage \(averageCPU)% too high")
    }
    
    // MARK: - Helper Methods
    
    /// Benchmarks timing accuracy for a specific interval
    private func benchmarkTimingAccuracy(targetInterval: TimeInterval, iterations: Int) async -> TimingBenchmarkResult {
        var measurements: [TimeInterval] = []
        var errors: [TimeInterval] = []
        
        let timer = HighPrecisionTimer()
        var lastTimestamp = CFAbsoluteTimeGetCurrent()
        var measurementCount = 0
        
        return await withCheckedContinuation { continuation in
            timer.startRepeatingTimer(interval: targetInterval) {
                let currentTime = CFAbsoluteTimeGetCurrent()
                let actualInterval = currentTime - lastTimestamp
                lastTimestamp = currentTime
                
                if measurementCount > 0 { // Skip first measurement (startup noise)
                    measurements.append(actualInterval)
                    errors.append(abs(actualInterval - targetInterval))
                }
                
                measurementCount += 1
                
                if measurementCount >= iterations + 1 {
                    timer.stopTimer()
                    
                    let meanError = errors.reduce(0, +) / Double(errors.count)
                    let meanMeasurement = measurements.reduce(0, +) / Double(measurements.count)
                    let variance = measurements.map { pow($0 - meanMeasurement, 2) }.reduce(0, +) / Double(measurements.count)
                    let standardDeviation = sqrt(variance)
                    
                    let result = TimingBenchmarkResult(
                        targetInterval: targetInterval,
                        measurements: measurements,
                        meanError: meanError,
                        standardDeviation: standardDeviation,
                        minMeasurement: measurements.min() ?? 0,
                        maxMeasurement: measurements.max() ?? 0
                    )
                    
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

// MARK: - Supporting Types

/// Result of timing benchmark tests
struct TimingBenchmarkResult {
    let targetInterval: TimeInterval
    let measurements: [TimeInterval]
    let meanError: TimeInterval
    let standardDeviation: TimeInterval
    let minMeasurement: TimeInterval
    let maxMeasurement: TimeInterval
}