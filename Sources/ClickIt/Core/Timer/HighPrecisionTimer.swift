//
//  HighPrecisionTimer.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation
import Dispatch

/// High-precision timer implementation optimized for sub-10ms accuracy
/// Uses mach_absolute_time() and DispatchSourceTimer for minimal overhead
final class HighPrecisionTimer: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Timer source for precise scheduling
    private var timerSource: DispatchSourceTimer?
    
    /// Queue for timer execution (high priority)
    private let timerQueue = DispatchQueue(
        label: "com.clickit.highprecision.timer",
        qos: .userInteractive,
        attributes: .concurrent
    )
    
    /// Callback to execute on timer events
    private var callback: (() -> Void)?
    
    /// Timer interval in nanoseconds for precise calculations
    private var intervalNanoseconds: UInt64 = 0
    
    /// Timer state tracking
    private var isRunning: Bool = false
    
    /// Timing accuracy tracking
    private var lastExecutionTime: UInt64 = 0
    private var timingErrors: [TimeInterval] = []
    private var maxTimingErrorHistory = 1000
    
    /// Mach timebase for conversion
    private static let timebaseInfo: mach_timebase_info = {
        var info = mach_timebase_info()
        mach_timebase_info(&info)
        return info
    }()
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Methods
    
    /// Starts a repeating high-precision timer
    /// - Parameters:
    ///   - interval: Timer interval in seconds
    ///   - callback: Callback to execute on each timer event
    func startRepeatingTimer(interval: TimeInterval, callback: @escaping () -> Void) {
        guard !isRunning else {
            print("[HighPrecisionTimer] Timer already running")
            return
        }
        
        guard interval > 0 else {
            print("[HighPrecisionTimer] Invalid interval: \(interval)")
            return
        }
        
        self.callback = callback
        self.intervalNanoseconds = UInt64(interval * 1_000_000_000)
        
        // Create high-precision timer source
        timerSource = DispatchSource.makeTimerSource(queue: timerQueue)
        
        guard let timerSource = timerSource else {
            print("[HighPrecisionTimer] Failed to create timer source")
            return
        }
        
        // Configure timer with minimal leeway for maximum precision
        let leeway = DispatchTimeInterval.nanoseconds(Int(min(intervalNanoseconds / 100, 100_000))) // 1% of interval or 100μs max
        
        timerSource.schedule(
            deadline: .now(),
            repeating: .nanoseconds(Int(intervalNanoseconds)),
            leeway: leeway
        )
        
        // Set timer event handler with timing accuracy tracking
        timerSource.setEventHandler { [weak self] in
            self?.executeTimerCallback()
        }
        
        // Start the timer
        timerSource.resume()
        isRunning = true
        lastExecutionTime = mach_absolute_time()
        
        print("[HighPrecisionTimer] Started with interval: \(interval * 1000)ms")
    }
    
    /// Starts a one-shot high-precision timer
    /// - Parameters:
    ///   - delay: Delay before execution in seconds
    ///   - callback: Callback to execute after delay
    func startOneShotTimer(delay: TimeInterval, callback: @escaping () -> Void) {
        guard !isRunning else {
            print("[HighPrecisionTimer] Timer already running")
            return
        }
        
        guard delay > 0 else {
            print("[HighPrecisionTimer] Invalid delay: \(delay)")
            return
        }
        
        self.callback = callback
        
        // Create one-shot timer source
        timerSource = DispatchSource.makeTimerSource(queue: timerQueue)
        
        guard let timerSource = timerSource else {
            print("[HighPrecisionTimer] Failed to create timer source")
            return
        }
        
        // Configure one-shot timer
        let delayNanoseconds = UInt64(delay * 1_000_000_000)
        let leeway = DispatchTimeInterval.nanoseconds(Int(min(delayNanoseconds / 100, 100_000)))
        
        timerSource.schedule(
            deadline: .now() + .nanoseconds(Int(delayNanoseconds)),
            leeway: leeway
        )
        
        // Set timer event handler
        timerSource.setEventHandler { [weak self] in
            self?.executeTimerCallback()
            self?.stopTimer() // Auto-stop for one-shot timer
        }
        
        // Start the timer
        timerSource.resume()
        isRunning = true
        
        print("[HighPrecisionTimer] Started one-shot timer with delay: \(delay * 1000)ms")
    }
    
    /// Stops the timer
    func stopTimer() {
        guard isRunning else { return }
        
        timerSource?.cancel()
        timerSource = nil
        callback = nil
        isRunning = false
        
        print("[HighPrecisionTimer] Stopped timer")
    }
    
    /// Pauses the timer (can be resumed)
    func pauseTimer() {
        guard isRunning else { return }
        
        timerSource?.suspend()
        print("[HighPrecisionTimer] Paused timer")
    }
    
    /// Resumes a paused timer
    func resumeTimer() {
        guard isRunning, let timerSource = timerSource else { return }
        
        timerSource.resume()
        lastExecutionTime = mach_absolute_time()
        print("[HighPrecisionTimer] Resumed timer")
    }
    
    /// Gets timing accuracy statistics
    /// - Returns: Timing accuracy statistics
    func getTimingAccuracy() -> TimingAccuracyStats {
        guard !timingErrors.isEmpty else {
            return TimingAccuracyStats(
                meanError: 0,
                maxError: 0,
                standardDeviation: 0,
                measurements: 0,
                targetInterval: machTimeToSeconds(intervalNanoseconds)
            )
        }
        
        let meanError = timingErrors.reduce(0, +) / Double(timingErrors.count)
        let maxError = timingErrors.max() ?? 0
        let variance = timingErrors.map { pow($0 - meanError, 2) }.reduce(0, +) / Double(timingErrors.count)
        let standardDeviation = sqrt(variance)
        
        return TimingAccuracyStats(
            meanError: meanError,
            maxError: maxError,
            standardDeviation: standardDeviation,
            measurements: timingErrors.count,
            targetInterval: machTimeToSeconds(intervalNanoseconds)
        )
    }
    
    /// Resets timing accuracy statistics
    func resetTimingStats() {
        timingErrors.removeAll()
        lastExecutionTime = mach_absolute_time()
    }
    
    // MARK: - Private Methods
    
    /// Executes the timer callback with timing accuracy tracking
    private func executeTimerCallback() {
        let currentTime = mach_absolute_time()
        
        // Calculate timing error for accuracy tracking
        if lastExecutionTime > 0 {
            let actualInterval = machTimeToSeconds(currentTime - lastExecutionTime)
            let targetInterval = machTimeToSeconds(intervalNanoseconds)
            let timingError = abs(actualInterval - targetInterval)
            
            // Store timing error for statistics
            timingErrors.append(timingError)
            
            // Limit history size to prevent memory growth
            if timingErrors.count > maxTimingErrorHistory {
                timingErrors.removeFirst(timingErrors.count - maxTimingErrorHistory)
            }
            
            // Log significant timing errors
            if timingError > 0.005 { // 5ms threshold
                print("[HighPrecisionTimer] Timing error: \(timingError * 1000)ms (target: \(targetInterval * 1000)ms, actual: \(actualInterval * 1000)ms)")
            }
        }
        
        lastExecutionTime = currentTime
        
        // Execute the callback
        callback?()
    }
    
    /// Converts mach time to seconds using cached timebase
    /// - Parameter machTime: Mach time value
    /// - Returns: Time in seconds
    private func machTimeToSeconds(_ machTime: UInt64) -> TimeInterval {
        return Double(machTime) * Double(Self.timebaseInfo.numer) / Double(Self.timebaseInfo.denom) / 1_000_000_000
    }
}

// MARK: - Supporting Types

/// Statistics for timing accuracy
struct TimingAccuracyStats {
    /// Mean timing error in seconds
    let meanError: TimeInterval
    
    /// Maximum timing error in seconds
    let maxError: TimeInterval
    
    /// Standard deviation of timing errors
    let standardDeviation: TimeInterval
    
    /// Number of measurements
    let measurements: Int
    
    /// Target interval in seconds
    let targetInterval: TimeInterval
    
    /// Whether timing is within acceptable tolerance (±2ms)
    var isWithinTolerance: Bool {
        return meanError <= 0.002 && maxError <= 0.010
    }
    
    /// Timing accuracy as percentage (100% = perfect)
    var accuracyPercentage: Double {
        guard targetInterval > 0 else { return 0 }
        let accuracy = 1.0 - (meanError / targetInterval)
        return max(0, min(100, accuracy * 100))
    }
}

// MARK: - Timer Factory

/// Factory for creating pre-configured high-precision timers
struct HighPrecisionTimerFactory {
    
    /// Creates a timer optimized for click automation
    /// - Parameter interval: Click interval in seconds
    /// - Returns: Configured high-precision timer
    static func createClickTimer(interval: TimeInterval) -> HighPrecisionTimer {
        let timer = HighPrecisionTimer()
        // Timer configuration is done in startRepeatingTimer
        return timer
    }
    
    /// Creates a timer optimized for UI updates
    /// - Parameter interval: Update interval in seconds (typically 0.016 for 60fps)
    /// - Returns: Configured high-precision timer
    static func createUIUpdateTimer(interval: TimeInterval = 0.016) -> HighPrecisionTimer {
        let timer = HighPrecisionTimer()
        return timer
    }
    
    /// Creates a timer optimized for performance monitoring
    /// - Parameter interval: Monitoring interval in seconds
    /// - Returns: Configured high-precision timer
    static func createMonitoringTimer(interval: TimeInterval = 0.1) -> HighPrecisionTimer {
        let timer = HighPrecisionTimer()
        return timer
    }
}

// MARK: - Performance Extensions

extension HighPrecisionTimer {
    
    /// Benchmark timer performance
    /// - Parameters:
    ///   - interval: Timer interval to test
    ///   - duration: Test duration in seconds
    /// - Returns: Performance benchmark results
    func benchmark(interval: TimeInterval, duration: TimeInterval) async -> TimerBenchmarkResult {
        return await withCheckedContinuation { continuation in
            var executionTimes: [TimeInterval] = []
            let startTime = CFAbsoluteTimeGetCurrent()
            var executionCount = 0
            
            startRepeatingTimer(interval: interval) {
                let currentTime = CFAbsoluteTimeGetCurrent()
                executionTimes.append(currentTime)
                executionCount += 1
                
                if currentTime - startTime >= duration {
                    self.stopTimer()
                    
                    let result = TimerBenchmarkResult(
                        targetInterval: interval,
                        actualDuration: currentTime - startTime,
                        executionCount: executionCount,
                        timingAccuracy: self.getTimingAccuracy()
                    )
                    
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

/// Benchmark results for timer performance
struct TimerBenchmarkResult {
    let targetInterval: TimeInterval
    let actualDuration: TimeInterval
    let executionCount: Int
    let timingAccuracy: TimingAccuracyStats
    
    /// Actual frequency achieved
    var actualFrequency: Double {
        return Double(executionCount) / actualDuration
    }
    
    /// Target frequency
    var targetFrequency: Double {
        return 1.0 / targetInterval
    }
    
    /// Frequency accuracy percentage
    var frequencyAccuracy: Double {
        guard targetFrequency > 0 else { return 0 }
        return (actualFrequency / targetFrequency) * 100
    }
}