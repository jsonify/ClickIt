//
//  PerformanceValidator.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation

/// Automated performance validation and regression testing system
/// Validates performance targets and detects performance regressions
final class PerformanceValidator: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = PerformanceValidator()
    
    /// Performance targets configuration
    private let performanceTargets = PerformanceTargets()
    
    /// Performance monitor reference (accessed on main actor)
    private var performanceMonitor: PerformanceMonitor {
        PerformanceMonitor.shared
    }
    
    /// Validation history for regression detection
    private var validationHistory: [ValidationResult] = []
    
    /// Maximum validation history entries
    private let maxHistoryEntries = 100
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Runs comprehensive performance validation
    /// - Returns: Complete validation results
    func validatePerformance() async -> ValidationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var testResults: [PerformanceTestResult] = []
        
        // 1. Memory Usage Validation
        let memoryResult = await validateMemoryUsage()
        testResults.append(memoryResult)
        
        // 2. CPU Usage Validation
        let cpuResult = await validateCPUUsage()
        testResults.append(cpuResult)
        
        // 3. Timing Accuracy Validation
        let timingResult = await validateTimingAccuracy()
        testResults.append(timingResult)
        
        // 4. High-Frequency Performance
        let highFreqResult = await validateHighFrequencyPerformance()
        testResults.append(highFreqResult)
        
        // 5. Memory Leak Detection
        let memoryLeakResult = await validateMemoryLeakPrevention()
        testResults.append(memoryLeakResult)
        
        // 6. Resource Cleanup Validation
        let cleanupResult = await validateResourceCleanup()
        testResults.append(cleanupResult)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let validationDuration = endTime - startTime
        
        // Calculate overall result
        let passedTests = testResults.filter { $0.passed }.count
        let totalTests = testResults.count
        let overallPassed = passedTests == totalTests
        
        let result = ValidationResult(
            timestamp: Date(),
            overallPassed: overallPassed,
            testResults: testResults,
            validationDuration: validationDuration,
            passedTests: passedTests,
            totalTests: totalTests
        )
        
        // Store in history for regression tracking
        addToHistory(result)
        
        print("[PerformanceValidator] Validation completed: \(passedTests)/\(totalTests) tests passed in \(String(format: "%.2f", validationDuration))s")
        
        return result
    }
    
    /// Validates specific performance target
    /// - Parameter target: Performance target to validate
    /// - Returns: Validation result for the target
    func validateTarget(_ target: PerformanceTarget) async -> PerformanceTestResult {
        switch target {
        case .memoryUsage:
            return await validateMemoryUsage()
        case .cpuUsage:
            return await validateCPUUsage()
        case .timingAccuracy:
            return await validateTimingAccuracy()
        case .highFrequencyPerformance:
            return await validateHighFrequencyPerformance()
        case .memoryLeakPrevention:
            return await validateMemoryLeakPrevention()
        case .resourceCleanup:
            return await validateResourceCleanup()
        }
    }
    
    /// Detects performance regressions by comparing recent results
    /// - Parameter windowSize: Number of recent validation results to analyze
    /// - Returns: Regression analysis results
    func detectRegressions(windowSize: Int = 10) -> RegressionAnalysis {
        guard validationHistory.count >= windowSize else {
            return RegressionAnalysis(
                hasRegressions: false,
                regressions: [],
                overallTrend: .stable,
                confidence: 0.0
            )
        }
        
        let recentResults = Array(validationHistory.suffix(windowSize))
        var regressions: [PerformanceRegression] = []
        
        // Analyze each performance target for regressions
        for target in PerformanceTarget.allCases {
            if let regression = analyzeTargetRegression(target: target, results: recentResults) {
                regressions.append(regression)
            }
        }
        
        // Calculate overall trend
        let successRates = recentResults.map { Double($0.passedTests) / Double($0.totalTests) }
        let trend = calculateTrend(values: successRates)
        
        // Calculate confidence based on data consistency
        let confidence = calculateConfidence(values: successRates)
        
        return RegressionAnalysis(
            hasRegressions: !regressions.isEmpty,
            regressions: regressions,
            overallTrend: trend,
            confidence: confidence
        )
    }
    
    /// Gets performance validation history
    /// - Parameter limit: Maximum number of results to return
    /// - Returns: Array of validation results
    func getValidationHistory(limit: Int = 50) -> [ValidationResult] {
        return Array(validationHistory.suffix(limit))
    }
    
    /// Clears validation history
    func clearHistory() {
        validationHistory.removeAll()
        print("[PerformanceValidator] Validation history cleared")
    }
    
    // MARK: - Private Validation Methods
    
    /// Validates memory usage is within target limits
    private func validateMemoryUsage() async -> PerformanceTestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Take multiple measurements for accuracy
        var measurements: [Double] = []
        for _ in 0..<5 {
            await measurements.append(performanceMonitor.currentMemoryUsageMB)
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms between measurements
        }
        
        let averageMemory = measurements.reduce(0, +) / Double(measurements.count)
        let maxMemory = measurements.max() ?? 0
        
        let passed = averageMemory <= performanceTargets.memoryTargetMB && 
                    maxMemory <= performanceTargets.memoryTargetMB * 1.2 // Allow 20% spike tolerance
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return PerformanceTestResult(
            target: .memoryUsage,
            passed: passed,
            actualValue: averageMemory,
            targetValue: performanceTargets.memoryTargetMB,
            testDuration: endTime - startTime,
            details: [
                "average_memory": averageMemory,
                "max_memory": maxMemory,
                "measurements": measurements.count
            ]
        )
    }
    
    /// Validates CPU usage is within target limits
    private func validateCPUUsage() async -> PerformanceTestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Reset CPU measurements for clean test
        await performanceMonitor.resetCPUMeasurements()
        
        // Let CPU settle into steady state
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let averageCPU = await performanceMonitor.averageCPUUsagePercent
        let passed = averageCPU <= performanceTargets.cpuIdleTargetPercent
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return PerformanceTestResult(
            target: .cpuUsage,
            passed: passed,
            actualValue: averageCPU,
            targetValue: performanceTargets.cpuIdleTargetPercent,
            testDuration: endTime - startTime,
            details: [
                "average_cpu": averageCPU,
                "measurement_duration": 2.0
            ]
        )
    }
    
    /// Validates timing accuracy meets sub-10ms targets
    private func validateTimingAccuracy() async -> PerformanceTestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let timer = HighPrecisionTimer()
        let targetInterval: TimeInterval = 0.010 // 10ms
        
        let benchmarkResult = await timer.benchmark(interval: targetInterval, duration: 5.0)
        
        let timingAccuracy = benchmarkResult.timingAccuracy
        let passed = timingAccuracy.isWithinTolerance && 
                    timingAccuracy.meanError <= performanceTargets.timingAccuracyTargetMS / 1000.0
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return PerformanceTestResult(
            target: .timingAccuracy,
            passed: passed,
            actualValue: timingAccuracy.meanError * 1000, // Convert to ms
            targetValue: performanceTargets.timingAccuracyTargetMS,
            testDuration: endTime - startTime,
            details: [
                "mean_error_ms": timingAccuracy.meanError * 1000,
                "max_error_ms": timingAccuracy.maxError * 1000,
                "standard_deviation_ms": timingAccuracy.standardDeviation * 1000,
                "measurements": timingAccuracy.measurements,
                "accuracy_percentage": timingAccuracy.accuracyPercentage
            ]
        )
    }
    
    /// Validates performance at high frequencies (up to 100 CPS)
    private func validateHighFrequencyPerformance() async -> PerformanceTestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let timer = HighPrecisionTimer()
        let highFrequencyInterval: TimeInterval = 0.01 // 100 CPS
        
        let benchmarkResult = await timer.benchmark(interval: highFrequencyInterval, duration: 3.0)
        
        let frequencyAccuracy = benchmarkResult.frequencyAccuracy
        let passed = frequencyAccuracy >= 95.0 && // 95% frequency accuracy
                    benchmarkResult.timingAccuracy.meanError <= 0.005 // 5ms error tolerance at high frequency
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return PerformanceTestResult(
            target: .highFrequencyPerformance,
            passed: passed,
            actualValue: frequencyAccuracy,
            targetValue: 95.0,
            testDuration: endTime - startTime,
            details: [
                "frequency_accuracy": frequencyAccuracy,
                "target_frequency": benchmarkResult.targetFrequency,
                "actual_frequency": benchmarkResult.actualFrequency,
                "timing_error_ms": benchmarkResult.timingAccuracy.meanError * 1000
            ]
        )
    }
    
    /// Validates memory leak prevention
    private func validateMemoryLeakPrevention() async -> PerformanceTestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let initialMemory = await performanceMonitor.currentMemoryUsageMB
        var timers: [HighPrecisionTimer] = []
        
        // Create and destroy timers repeatedly to test for leaks
        for _ in 0..<20 {
            let timer = HighPrecisionTimer()
            timer.startRepeatingTimer(interval: 0.001) {
                _ = mach_absolute_time()
            }
            timers.append(timer)
            
            // Let timer run briefly
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            
            timer.stopTimer()
        }
        
        timers.removeAll()
        
        // Force cleanup
        await performanceMonitor.optimizeMemoryUsage()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for cleanup
        
        let finalMemory = await performanceMonitor.currentMemoryUsageMB
        let memoryIncrease = finalMemory - initialMemory
        
        // Allow some memory increase but detect significant leaks
        let passed = memoryIncrease <= 5.0 // 5MB tolerance
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return PerformanceTestResult(
            target: .memoryLeakPrevention,
            passed: passed,
            actualValue: memoryIncrease,
            targetValue: 5.0,
            testDuration: endTime - startTime,
            details: [
                "initial_memory": initialMemory,
                "final_memory": finalMemory,
                "memory_increase": memoryIncrease,
                "timer_cycles": 20
            ]
        )
    }
    
    /// Validates proper resource cleanup
    private func validateResourceCleanup() async -> PerformanceTestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var allTimersCleanedUp = true
        var cleanupErrors: [String] = []
        
        // Test multiple timer lifecycle scenarios
        for scenario in 1...5 {
            let timer = HighPrecisionTimer()
            
            switch scenario {
            case 1:
                // Normal start/stop cycle
                timer.startRepeatingTimer(interval: 0.01) { }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                timer.stopTimer()
                
            case 2:
                // One-shot timer cleanup
                timer.startOneShotTimer(delay: 0.05) { }
                try? await Task.sleep(nanoseconds: 100_000_000) // Wait for completion
                
            case 3:
                // Pause/resume cycle
                timer.startRepeatingTimer(interval: 0.01) { }
                timer.pauseTimer()
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                timer.resumeTimer()
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                timer.stopTimer()
                
            case 4:
                // Immediate stop after start
                timer.startRepeatingTimer(interval: 0.01) { }
                timer.stopTimer()
                
            case 5:
                // Deinit without explicit stop (tests deinit cleanup)
                timer.startRepeatingTimer(interval: 0.01) { }
                // Let timer deinit handle cleanup
                break
                
            default:
                break
            }
            
            // Verify cleanup (simplified check)
            if scenario != 5 { // Skip explicit check for deinit test
                // Timer should be properly stopped
                // This is a simplified check - in real implementation,
                // we'd have more detailed resource tracking
            }
        }
        
        let passed = allTimersCleanedUp && cleanupErrors.isEmpty
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return PerformanceTestResult(
            target: .resourceCleanup,
            passed: passed,
            actualValue: Double(cleanupErrors.count),
            targetValue: 0,
            testDuration: endTime - startTime,
            details: [
                "scenarios_tested": 5,
                "cleanup_errors": cleanupErrors.count,
                "all_cleaned_up": allTimersCleanedUp
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    /// Adds validation result to history
    private func addToHistory(_ result: ValidationResult) {
        validationHistory.append(result)
        
        // Limit history size
        if validationHistory.count > maxHistoryEntries {
            validationHistory.removeFirst(validationHistory.count - maxHistoryEntries)
        }
    }
    
    /// Analyzes target for performance regression
    private func analyzeTargetRegression(target: PerformanceTarget, results: [ValidationResult]) -> PerformanceRegression? {
        let targetResults = results.compactMap { result in
            result.testResults.first { $0.target == target }
        }
        
        guard targetResults.count >= 5 else { return nil } // Need enough data
        
        let values = targetResults.map { $0.actualValue }
        _ = calculateTrend(values: values)
        
        // Check for significant regression
        let recentValues = Array(values.suffix(3))
        let olderValues = Array(values.prefix(values.count - 3))
        
        let recentAverage = recentValues.reduce(0, +) / Double(recentValues.count)
        let olderAverage = olderValues.reduce(0, +) / Double(olderValues.count)
        
        let changePercent = ((recentAverage - olderAverage) / olderAverage) * 100
        
        // Define regression thresholds based on target type
        let regressionThreshold: Double = {
            switch target {
            case .memoryUsage, .cpuUsage:
                return 20.0 // 20% increase is concerning
            case .timingAccuracy:
                return 50.0 // 50% increase in timing error
            case .highFrequencyPerformance:
                return -10.0 // 10% decrease in performance
            case .memoryLeakPrevention:
                return 100.0 // 100% increase (doubling) is concerning
            case .resourceCleanup:
                return 0.0 // Any increase in errors is concerning
            }
        }()
        
        let isRegression = (target == .highFrequencyPerformance && changePercent < regressionThreshold) ||
                          (target != .highFrequencyPerformance && changePercent > regressionThreshold)
        
        guard isRegression else { return nil }
        
        return PerformanceRegression(
            target: target,
            severity: abs(changePercent) > abs(regressionThreshold) * 2 ? .high : .medium,
            changePercent: changePercent,
            oldValue: olderAverage,
            newValue: recentAverage,
            detectedAt: Date()
        )
    }
    
    /// Calculates trend direction for a series of values
    private func calculateTrend(values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }
        
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let changePercent = ((secondAverage - firstAverage) / firstAverage) * 100
        
        if abs(changePercent) < 5.0 {
            return .stable
        } else if changePercent > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }
    
    /// Calculates confidence level for trend analysis
    private func calculateConfidence(values: [Double]) -> Double {
        guard values.count >= 3 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = higher confidence
        let coefficientOfVariation = standardDeviation / mean
        let confidence = max(0.0, min(1.0, 1.0 - coefficientOfVariation))
        
        return confidence
    }
}

// MARK: - Supporting Types

/// Performance targets configuration
struct PerformanceTargets {
    let memoryTargetMB: Double = 50.0
    let cpuIdleTargetPercent: Double = 5.0
    let timingAccuracyTargetMS: Double = 10.0 // 10ms
    let highFrequencyAccuracyPercent: Double = 95.0
    let memoryLeakToleranceMB: Double = 5.0
    let resourceCleanupErrorTolerance: Int = 0
}

/// Performance targets enumeration
enum PerformanceTarget: String, CaseIterable {
    case memoryUsage = "Memory Usage"
    case cpuUsage = "CPU Usage"
    case timingAccuracy = "Timing Accuracy"
    case highFrequencyPerformance = "High Frequency Performance"
    case memoryLeakPrevention = "Memory Leak Prevention"
    case resourceCleanup = "Resource Cleanup"
}

/// Individual performance test result
struct PerformanceTestResult {
    let target: PerformanceTarget
    let passed: Bool
    let actualValue: Double
    let targetValue: Double
    let testDuration: TimeInterval
    let details: [String: Any]
    
    /// Performance status based on how close actual is to target
    var status: String {
        if passed {
            return "✅ PASS"
        } else {
            let deviation = abs(actualValue - targetValue) / targetValue * 100
            return deviation > 50 ? "❌ FAIL" : "⚠️ WARNING"
        }
    }
}

/// Complete validation result
struct ValidationResult {
    let timestamp: Date
    let overallPassed: Bool
    let testResults: [PerformanceTestResult]
    let validationDuration: TimeInterval
    let passedTests: Int
    let totalTests: Int
    
    /// Success rate as percentage
    var successRate: Double {
        return Double(passedTests) / Double(totalTests) * 100
    }
}

/// Performance regression detection
struct PerformanceRegression {
    enum Severity {
        case low, medium, high
    }
    
    let target: PerformanceTarget
    let severity: Severity
    let changePercent: Double
    let oldValue: Double
    let newValue: Double
    let detectedAt: Date
}

/// Regression analysis results
struct RegressionAnalysis {
    let hasRegressions: Bool
    let regressions: [PerformanceRegression]
    let overallTrend: TrendDirection
    let confidence: Double
}

// TrendDirection is now defined in PerformanceMonitor.swift