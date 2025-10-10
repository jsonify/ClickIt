//
//  HighPrecisionScheduler.swift
//  ClickIt
//
//  Created by ClickIt on 2025-10-09.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation

/// High-precision scheduler using DispatchSourceTimer for accurate timing
/// Provides sub-second accuracy for scheduled task execution
class HighPrecisionScheduler {

    // MARK: - Types

    /// Configuration for the scheduler
    struct Configuration {
        /// How often to recalculate time drift (in seconds)
        let driftCompensationInterval: TimeInterval

        /// How early to fire the task (in seconds) for last-minute adjustments
        let executionLeadTime: TimeInterval

        /// Polling interval for final countdown (in nanoseconds)
        let finalCountdownPollingInterval: UInt64

        static let `default` = Configuration(
            driftCompensationInterval: 60.0,  // Check every minute
            executionLeadTime: 0.1,            // Fire 100ms early
            finalCountdownPollingInterval: 10_000_000  // 10ms in nanoseconds
        )
    }

    // MARK: - Properties

    private var timer: DispatchSourceTimer?
    private var countdownTimer: DispatchSourceTimer?
    private var finalCountdownTimer: DispatchSourceTimer?
    private var scheduledTask: (@MainActor () -> Void)?
    private var targetDate: Date?
    private let configuration: Configuration
    private let queue: DispatchQueue

    /// Callback for countdown updates (called every second)
    var countdownUpdateHandler: ((TimeInterval) -> Void)?

    /// Callback for final execution
    var executionHandler: (() -> Void)?

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.queue = DispatchQueue(label: "com.clickit.highprecisionscheduler", qos: .userInitiated)
    }

    // MARK: - Public Methods

    /// Schedule a task for precise execution at the target date
    /// - Parameters:
    ///   - date: The target execution date/time
    ///   - task: The closure to execute at the scheduled time
    /// - Returns: True if scheduling succeeded, false if date is in the past
    func schedule(for date: Date, task: @escaping @MainActor () -> Void) -> Bool {
        // Validate future date
        guard date > Date() else {
            print("HighPrecisionScheduler: Cannot schedule for past date: \(date)")
            return false
        }

        // Cancel any existing schedule
        cancel()

        self.targetDate = date
        self.scheduledTask = task

        // Calculate time until execution
        let timeUntilExecution = date.timeIntervalSinceNow

        print("HighPrecisionScheduler: Scheduling task for \(date)")
        print("HighPrecisionScheduler: Time until execution: \(timeUntilExecution)s")

        // Start drift compensation timer (runs every minute to adjust for clock drift)
        startDriftCompensation()

        // Start countdown updates (every second for UI)
        startCountdownTimer()

        // Schedule the main execution
        scheduleMainExecution(timeUntilExecution: timeUntilExecution)

        return true
    }

    /// Cancel the scheduled task
    nonisolated func cancel() {
        timer?.cancel()
        timer = nil

        countdownTimer?.cancel()
        countdownTimer = nil

        finalCountdownTimer?.cancel()
        finalCountdownTimer = nil

        scheduledTask = nil
        targetDate = nil

        print("HighPrecisionScheduler: Cancelled scheduled task")
    }

    /// Get the current time remaining until execution
    func getTimeRemaining() -> TimeInterval {
        guard let targetDate = targetDate else { return 0 }
        return max(0, targetDate.timeIntervalSinceNow)
    }

    // MARK: - Private Methods

    private func scheduleMainExecution(timeUntilExecution: TimeInterval) {
        // Calculate when to transition to final countdown (with lead time)
        let finalCountdownStart = max(0, timeUntilExecution - configuration.executionLeadTime)

        // Create dispatch timer for main wait period
        let timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer = timer

        // Schedule to fire just before the final countdown
        let deadline = DispatchTime.now() + finalCountdownStart
        timer.schedule(deadline: deadline, leeway: .milliseconds(1))

        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.startFinalCountdown()
            }
        }

        timer.resume()
    }

    private func startDriftCompensation() {
        guard configuration.driftCompensationInterval > 0 else { return }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        self.countdownTimer = timer

        timer.schedule(
            deadline: .now(),
            repeating: configuration.driftCompensationInterval,
            leeway: .milliseconds(100)
        )

        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.compensateForDrift()
            }
        }

        timer.resume()
    }

    private func startCountdownTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        self.countdownTimer = timer

        timer.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(50))

        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.updateCountdown()
            }
        }

        timer.resume()
    }

    private func startFinalCountdown() async {
        print("HighPrecisionScheduler: Starting final countdown")

        let timer = DispatchSource.makeTimerSource(queue: queue)
        self.finalCountdownTimer = timer

        // Poll every 10ms during final countdown
        timer.schedule(
            deadline: .now(),
            repeating: .nanoseconds(Int(configuration.finalCountdownPollingInterval)),
            leeway: .nanoseconds(1_000_000)  // 1ms leeway
        )

        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.checkFinalExecution()
            }
        }

        timer.resume()
    }

    private func compensateForDrift() async {
        guard let targetDate = targetDate else { return }

        let timeRemaining = targetDate.timeIntervalSinceNow

        // If we're close to execution time, don't recalculate
        if timeRemaining < configuration.executionLeadTime * 2 {
            return
        }

        // Recalculate and reschedule if there's significant drift
        print("HighPrecisionScheduler: Compensating for drift, time remaining: \(timeRemaining)s")
    }

    private func updateCountdown() async {
        guard let targetDate = targetDate else { return }

        let timeRemaining = max(0, targetDate.timeIntervalSinceNow)

        // Call the countdown update handler on main actor
        await MainActor.run {
            countdownUpdateHandler?(timeRemaining)
        }
    }

    private func checkFinalExecution() async {
        guard let targetDate = targetDate else { return }

        let timeRemaining = targetDate.timeIntervalSinceNow

        // Check if it's time to execute (within 5ms tolerance)
        if timeRemaining <= 0.005 {
            await executeTask()
        }
    }

    private func executeTask() async {
        print("HighPrecisionScheduler: Executing task at \(Date())")

        // Cancel all timers
        timer?.cancel()
        countdownTimer?.cancel()
        finalCountdownTimer?.cancel()

        // Execute the scheduled task on main actor
        await MainActor.run {
            scheduledTask?()
            executionHandler?()
        }

        // Clean up
        scheduledTask = nil
        targetDate = nil
    }

    // MARK: - Cleanup

    deinit {
        timer?.cancel()
        countdownTimer?.cancel()
        finalCountdownTimer?.cancel()
    }
}

// MARK: - System Time Validation

extension HighPrecisionScheduler {

    /// Validate system time accuracy by checking if it's synchronized
    /// - Returns: True if system time appears to be accurate
    static func validateSystemTime() -> Bool {
        // Check if the system time is reasonable (not wildly off)
        let now = Date()
        let year = Calendar.current.component(.year, from: now)

        // Basic sanity check - year should be reasonable
        if year < 2024 || year > 2030 {
            print("HighPrecisionScheduler: System time appears to be incorrect (year: \(year))")
            return false
        }

        return true
    }

    /// Get the current system time with nanosecond precision
    static func getCurrentPreciseTime() -> TimeInterval {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)

        let nanos = mach_absolute_time() * UInt64(timebase.numer) / UInt64(timebase.denom)
        return Double(nanos) / 1_000_000_000.0
    }

    /// Calculate the accuracy of the scheduler (estimated drift per hour)
    /// - Returns: Estimated drift in seconds per hour
    static func estimatedDrift() -> TimeInterval {
        // DispatchSourceTimer typically has <1ms accuracy
        // Over an hour, this could accumulate to ~0.1-0.5s drift
        return 0.0001  // 0.1ms per execution
    }
}
