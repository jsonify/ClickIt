//
//  CPSRandomizerTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
@testable import ClickIt

/// Comprehensive tests for CPSRandomizer functionality
final class CPSRandomizerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var randomizer: CPSRandomizer!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        // Default randomizer for basic tests
        randomizer = CPSRandomizer()
    }
    
    override func tearDown() {
        randomizer = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        let config = CPSRandomizer.Configuration()
        
        XCTAssertFalse(config.enabled, "Default configuration should be disabled")
        XCTAssertEqual(config.variancePercentage, 0.1, accuracy: 0.001, "Default variance should be 10%")
        XCTAssertEqual(config.distributionPattern, .normal, "Default distribution should be normal")
        XCTAssertEqual(config.humannessLevel, .medium, "Default humanness should be medium")
        XCTAssertEqual(config.minimumInterval, 0.01, accuracy: 0.001, "Default minimum interval should be 10ms")
        XCTAssertEqual(config.maximumInterval, 10.0, accuracy: 0.001, "Default maximum interval should be 10s")
    }
    
    func testConfigurationClamping() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 1.5, // Should be clamped to 1.0
            distributionPattern: .normal,
            humannessLevel: .medium,
            patternBreakupFrequency: -0.1 // Should be clamped to 0.0
        )
        
        XCTAssertEqual(config.variancePercentage, 1.0, accuracy: 0.001, "Variance should be clamped to maximum 100%")
        XCTAssertEqual(config.patternBreakupFrequency, 0.0, accuracy: 0.001, "Pattern breakup frequency should be clamped to minimum 0%")
    }
    
    // MARK: - Basic Randomization Tests
    
    func testDisabledRandomizationReturnsOriginalInterval() {
        let config = CPSRandomizer.Configuration(enabled: false)
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        let randomizedInterval = randomizer.randomizeInterval(baseInterval)
        
        XCTAssertEqual(randomizedInterval, baseInterval, accuracy: 0.001, "Disabled randomizer should return original interval")
    }
    
    func testEnabledRandomizationModifiesInterval() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.2, // 20% variance
            distributionPattern: .uniform,
            humannessLevel: .medium
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        var intervals: [TimeInterval] = []
        
        // Generate multiple intervals to test randomization
        for _ in 0..<100 {
            let randomizedInterval = randomizer.randomizeInterval(baseInterval)
            intervals.append(randomizedInterval)
        }
        
        // Check that not all intervals are the same (randomization is working)
        let uniqueIntervals = Set(intervals.map { Int($0 * 10000) }) // Convert to int for comparison
        XCTAssertGreaterThan(uniqueIntervals.count, 10, "Should generate varied intervals")
        
        // Check that intervals are within expected range
        let minExpected = baseInterval * 0.5 // Conservative range check
        let maxExpected = baseInterval * 1.5
        for interval in intervals {
            XCTAssertGreaterThanOrEqual(interval, minExpected, "Interval should be within reasonable range")
            XCTAssertLessThanOrEqual(interval, maxExpected, "Interval should be within reasonable range")
        }
    }
    
    // MARK: - Distribution Pattern Tests
    
    func testUniformDistribution() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.1,
            distributionPattern: .uniform,
            humannessLevel: .medium
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        var intervals: [TimeInterval] = []
        
        for _ in 0..<1000 {
            intervals.append(randomizer.randomizeInterval(baseInterval))
        }
        
        // For uniform distribution, variance should be roughly consistent
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        XCTAssertEqual(mean, baseInterval, accuracy: 0.1, "Mean should be close to base interval")
    }
    
    func testNormalDistribution() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.1,
            distributionPattern: .normal,
            humannessLevel: .medium
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        var intervals: [TimeInterval] = []
        
        for _ in 0..<1000 {
            intervals.append(randomizer.randomizeInterval(baseInterval))
        }
        
        // For normal distribution, mean should be close to base interval
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        XCTAssertEqual(mean, baseInterval, accuracy: 0.05, "Mean should be very close to base interval for normal distribution")
        
        // Check for bell curve characteristics (most values near mean)
        let tolerance = baseInterval * 0.05
        let nearMeanCount = intervals.filter { abs($0 - mean) <= tolerance }.count
        let nearMeanPercentage = Double(nearMeanCount) / Double(intervals.count)
        
        XCTAssertGreaterThan(nearMeanPercentage, 0.3, "Normal distribution should have many values near the mean")
    }
    
    // MARK: - Humanness Level Tests
    
    func testHumannessLevelAffectsVariance() {
        let baseInterval: TimeInterval = 1.0
        let testVariance: Double = 0.1
        
        // Test low humanness
        let lowConfig = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: testVariance,
            distributionPattern: .uniform,
            humannessLevel: .low
        )
        let lowRandomizer = CPSRandomizer(configuration: lowConfig)
        
        // Test high humanness
        let highConfig = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: testVariance,
            distributionPattern: .uniform,
            humannessLevel: .high
        )
        let highRandomizer = CPSRandomizer(configuration: highConfig)
        
        // Generate intervals for each
        var lowIntervals: [TimeInterval] = []
        var highIntervals: [TimeInterval] = []
        
        for _ in 0..<100 {
            lowIntervals.append(lowRandomizer.randomizeInterval(baseInterval))
            highIntervals.append(highRandomizer.randomizeInterval(baseInterval))
        }
        
        // Calculate variance for each
        let lowMean = lowIntervals.reduce(0, +) / Double(lowIntervals.count)
        let highMean = highIntervals.reduce(0, +) / Double(highIntervals.count)
        
        let lowVariance = lowIntervals.map { pow($0 - lowMean, 2) }.reduce(0, +) / Double(lowIntervals.count)
        let highVariance = highIntervals.map { pow($0 - highMean, 2) }.reduce(0, +) / Double(highIntervals.count)
        
        XCTAssertGreaterThan(highVariance, lowVariance, "Higher humanness level should produce greater variance")
    }
    
    // MARK: - Clamping Tests
    
    func testIntervalClamping() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 1.0, // 100% variance - could go anywhere
            distributionPattern: .uniform,
            humannessLevel: .extreme,
            minimumInterval: 0.05, // 50ms minimum
            maximumInterval: 2.0   // 2s maximum
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        
        for _ in 0..<100 {
            let interval = randomizer.randomizeInterval(baseInterval)
            XCTAssertGreaterThanOrEqual(interval, config.minimumInterval, "Interval should not go below minimum")
            XCTAssertLessThanOrEqual(interval, config.maximumInterval, "Interval should not go above maximum")
        }
    }
    
    // MARK: - Statistics Tests
    
    func testStatisticsTracking() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.1,
            distributionPattern: .normal,
            humannessLevel: .medium
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        
        // Generate some intervals
        for _ in 0..<50 {
            _ = randomizer.randomizeInterval(baseInterval)
        }
        
        let stats = randomizer.getStatistics()
        
        XCTAssertEqual(stats.samplesGenerated, 50, "Should track correct number of samples")
        XCTAssertGreaterThan(stats.meanInterval, 0, "Mean interval should be positive")
        XCTAssertGreaterThan(stats.standardDeviation, 0, "Standard deviation should be positive for randomized intervals")
        XCTAssertGreaterThan(stats.humanlikeScore, 0, "Human-like score should be positive when enabled")
    }
    
    func testStatisticsReset() {
        let config = CPSRandomizer.Configuration(enabled: true)
        randomizer = CPSRandomizer(configuration: config)
        
        // Generate some intervals
        for _ in 0..<10 {
            _ = randomizer.randomizeInterval(1.0)
        }
        
        XCTAssertEqual(randomizer.getStatistics().samplesGenerated, 10, "Should have 10 samples before reset")
        
        randomizer.resetStatistics()
        
        XCTAssertEqual(randomizer.getStatistics().samplesGenerated, 0, "Should have 0 samples after reset")
    }
    
    // MARK: - Factory Method Tests
    
    func testFactoryMethods() {
        let gamingRandomizer = CPSRandomizer.forGaming()
        let gamingStats = gamingRandomizer.getStatistics()
        XCTAssertTrue(gamingRandomizer.getConfiguration().enabled, "Gaming randomizer should be enabled")
        
        let accessibilityRandomizer = CPSRandomizer.forAccessibility()
        XCTAssertTrue(accessibilityRandomizer.getConfiguration().enabled, "Accessibility randomizer should be enabled")
        XCTAssertLessThan(accessibilityRandomizer.getConfiguration().variancePercentage, 
                         gamingRandomizer.getConfiguration().variancePercentage, 
                         "Accessibility should have lower variance than gaming")
        
        let testingRandomizer = CPSRandomizer.forTesting()
        XCTAssertTrue(testingRandomizer.getConfiguration().enabled, "Testing randomizer should be enabled")
        XCTAssertLessThan(testingRandomizer.getConfiguration().variancePercentage, 
                         gamingRandomizer.getConfiguration().variancePercentage, 
                         "Testing should have lower variance than gaming")
        
        let stealthRandomizer = CPSRandomizer.forStealth()
        XCTAssertTrue(stealthRandomizer.getConfiguration().enabled, "Stealth randomizer should be enabled")
        XCTAssertGreaterThan(stealthRandomizer.getConfiguration().variancePercentage, 
                            gamingRandomizer.getConfiguration().variancePercentage, 
                            "Stealth should have higher variance than gaming")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.2,
            distributionPattern: .normal,
            humannessLevel: .high
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        
        measure {
            for _ in 0..<1000 {
                _ = randomizer.randomizeInterval(baseInterval)
            }
        }
    }
    
    // MARK: - Anti-Detection Tests
    
    func testPatternBreakup() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.1,
            distributionPattern: .normal,
            humannessLevel: .medium,
            patternBreakupFrequency: 0.5 // High frequency for testing
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        var intervals: [TimeInterval] = []
        
        for _ in 0..<100 {
            intervals.append(randomizer.randomizeInterval(baseInterval))
        }
        
        // Check for outliers that might indicate pattern breakup
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let standardDev = sqrt(intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count))
        
        let outliers = intervals.filter { abs($0 - mean) > (standardDev * 2) }
        
        // With 50% pattern breakup frequency, we should see some outliers
        XCTAssertGreaterThan(outliers.count, 5, "Should have some outliers from pattern breakup")
    }
    
    func testPatternUniformity() {
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.2,
            distributionPattern: .normal,
            humannessLevel: .high
        )
        randomizer = CPSRandomizer(configuration: config)
        
        let baseInterval: TimeInterval = 1.0
        
        // Generate intervals
        for _ in 0..<50 {
            _ = randomizer.randomizeInterval(baseInterval)
        }
        
        let stats = randomizer.getStatistics()
        
        // Pattern uniformity should be relatively low (more random)
        XCTAssertLessThan(stats.patternUniformity, 0.5, "Pattern uniformity should be low for good anti-detection")
        
        // Human-like score should be reasonable
        XCTAssertGreaterThan(stats.humanlikeScore, 40, "Human-like score should be decent with high humanness")
    }
}

// MARK: - Integration Tests

extension CPSRandomizerTests {
    
    func testIntegrationWithTimingSystem() {
        // Test that randomized intervals work with timing system constraints
        let config = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.1,
            distributionPattern: .normal,
            humannessLevel: .medium,
            minimumInterval: 0.01, // 10ms minimum (matching AppConstants)
            maximumInterval: 10.0
        )
        randomizer = CPSRandomizer(configuration: config)
        
        // Test various CPS rates
        let testCPSRates: [Double] = [1, 5, 10, 20, 50]
        
        for cps in testCPSRates {
            let baseInterval = 1.0 / cps
            
            for _ in 0..<20 {
                let randomizedInterval = randomizer.randomizeInterval(baseInterval)
                
                // Ensure randomized interval meets system constraints
                XCTAssertGreaterThanOrEqual(randomizedInterval, 0.01, "Should meet minimum interval constraint for \(cps) CPS")
                XCTAssertLessThanOrEqual(randomizedInterval, 10.0, "Should meet maximum interval constraint for \(cps) CPS")
            }
        }
    }
    
    func testConfigurationUpdatesDuringOperation() {
        let initialConfig = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.1,
            distributionPattern: .uniform,
            humannessLevel: .low
        )
        randomizer = CPSRandomizer(configuration: initialConfig)
        
        // Generate some intervals with initial config
        for _ in 0..<10 {
            _ = randomizer.randomizeInterval(1.0)
        }
        
        let initialStats = randomizer.getStatistics()
        
        // Update configuration
        let newConfig = CPSRandomizer.Configuration(
            enabled: true,
            variancePercentage: 0.3,
            distributionPattern: .normal,
            humannessLevel: .high
        )
        randomizer.updateConfiguration(newConfig)
        
        // Generate more intervals with new config
        for _ in 0..<10 {
            _ = randomizer.randomizeInterval(1.0)
        }
        
        // Verify configuration was updated
        XCTAssertEqual(randomizer.getConfiguration().variancePercentage, 0.3, accuracy: 0.001, "Configuration should be updated")
        
        // Statistics should be reset
        XCTAssertEqual(randomizer.getStatistics().samplesGenerated, 10, "Statistics should be reset on configuration update")
    }
}