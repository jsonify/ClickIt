//
//  SchedulingManager.swift
//  ClickIt
//
//  Created by ClickIt on 2025-10-09.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation
import Combine

/// Manages scheduled execution of automation tasks with high-precision timing
@MainActor
class SchedulingManager: ObservableObject {

    // MARK: - Published Properties

    /// Whether there is currently a scheduled task waiting
    @Published var hasScheduledTask: Bool = false

    /// The scheduled date/time for the next task
    @Published var scheduledDateTime: Date?

    /// Time remaining until scheduled execution (in seconds)
    @Published var timeRemaining: TimeInterval = 0

    /// Human-readable countdown string
    @Published var countdownString: String = ""

    /// Whether the scheduling manager is active
    @Published var isActive: Bool = false

    // MARK: - Private Properties

    private var highPrecisionScheduler: HighPrecisionScheduler?
    private var scheduledTask: (() -> Void)?

    // MARK: - Singleton

    static let shared = SchedulingManager()

    private init() {
        // Validate system time on initialization
        if !HighPrecisionScheduler.validateSystemTime() {
            print("⚠️ SchedulingManager: System time may be inaccurate!")
        }
    }

    // MARK: - Public Methods

    /// Schedule a task to execute at a specific date and time using high-precision timing
    /// - Parameters:
    ///   - date: The date and time to execute the task
    ///   - task: The closure to execute when the scheduled time arrives
    /// - Returns: True if scheduling was successful, false if the date is in the past
    func scheduleTask(for date: Date, task: @escaping () -> Void) -> Bool {
        // Validate that the date is in the future
        guard date > Date() else {
            print("SchedulingManager: Cannot schedule task for past date: \(date)")
            return false
        }

        // Cancel any existing scheduled task
        cancelScheduledTask()

        // Store the task and schedule it
        scheduledTask = task
        scheduledDateTime = date
        hasScheduledTask = true
        isActive = true

        print("SchedulingManager: Scheduling task for \(date) using high-precision timer")
        print("SchedulingManager: Current system time: \(Date())")

        // Create high-precision scheduler
        let scheduler = HighPrecisionScheduler()
        self.highPrecisionScheduler = scheduler

        // Set up countdown update handler
        scheduler.countdownUpdateHandler = { [weak self] timeRemaining in
            Task { @MainActor in
                self?.updateCountdown(timeRemaining: timeRemaining)
            }
        }

        // Set up execution handler
        scheduler.executionHandler = { [weak self] in
            Task { @MainActor in
                self?.executeScheduledTask()
            }
        }

        // Schedule the task
        let success = scheduler.schedule(for: date) { [weak self] in
            self?.executeScheduledTask()
        }

        if !success {
            print("SchedulingManager: Failed to schedule task with high-precision scheduler")
            hasScheduledTask = false
            isActive = false
        }

        return success
    }

    /// Cancel the currently scheduled task
    func cancelScheduledTask() {
        print("SchedulingManager: Cancelling scheduled task")

        highPrecisionScheduler?.cancel()
        highPrecisionScheduler = nil

        scheduledTask = nil
        scheduledDateTime = nil
        hasScheduledTask = false
        isActive = false
        timeRemaining = 0
        countdownString = ""
    }

    /// Get the time remaining until the scheduled task executes
    func getTimeRemaining() -> TimeInterval {
        guard let scheduledDateTime = scheduledDateTime else { return 0 }
        return max(0, scheduledDateTime.timeIntervalSinceNow)
    }

    /// Check if a given date/time is valid for scheduling (in the future)
    func isValidScheduleTime(_ date: Date) -> Bool {
        return date > Date()
    }

    // MARK: - Private Methods

    private func executeScheduledTask() {
        let actualExecutionTime = Date()
        let scheduledTime = scheduledDateTime ?? actualExecutionTime

        print("SchedulingManager: ⏰ EXECUTION EVENT")
        print("  Scheduled for: \(scheduledTime)")
        print("  Actually executed: \(actualExecutionTime)")
        print("  Timing error: \(actualExecutionTime.timeIntervalSince(scheduledTime))s")

        // Execute the scheduled task
        scheduledTask?()

        // Clean up after execution
        scheduledTask = nil
        scheduledDateTime = nil
        hasScheduledTask = false
        isActive = false
        timeRemaining = 0
        countdownString = ""

        // Clean up scheduler
        highPrecisionScheduler?.cancel()
        highPrecisionScheduler = nil
    }

    private func updateCountdown(timeRemaining remaining: TimeInterval) {
        guard scheduledDateTime != nil else {
            timeRemaining = 0
            countdownString = ""
            return
        }

        if remaining <= 0 {
            // Time has passed, should execute soon
            timeRemaining = 0
            countdownString = "Executing..."
        } else {
            timeRemaining = remaining
            countdownString = formatTimeInterval(remaining)
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)

        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if days > 0 {
            return String(format: "%dd %dh %dm %ds", days, hours, minutes, seconds)
        } else if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    // MARK: - Cleanup

    deinit {
        // Cancel high-precision scheduler
        highPrecisionScheduler?.cancel()
    }
}

// MARK: - Helper Extensions

extension SchedulingManager {

    /// Get a human-readable description of the scheduled time in GMT
    var scheduledTimeDescription: String {
        guard let scheduledDateTime = scheduledDateTime else {
            return "No task scheduled"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "GMT")

        return "Scheduled for \(formatter.string(from: scheduledDateTime)) GMT"
    }

    /// Get a human-readable description of the scheduled time in PST/PDT
    var scheduledTimePSTDescription: String {
        guard let scheduledDateTime = scheduledDateTime else {
            return "No task scheduled"
        }

        return "Scheduled for \(TimeZoneHelper.formatPSTTime(scheduledDateTime))"
    }

    /// Get a dual timezone description of the scheduled time
    var scheduledTimeDualDescription: String {
        guard let scheduledDateTime = scheduledDateTime else {
            return "No task scheduled"
        }

        return TimeZoneHelper.formatDualTime(scheduledDateTime)
    }

    /// Get a short description of the countdown
    var shortCountdownDescription: String {
        guard hasScheduledTask else {
            return ""
        }

        if timeRemaining <= 0 {
            return "Starting..."
        } else {
            return "Starts in \(countdownString)"
        }
    }

    /// Get a more detailed countdown with timezone info
    var detailedCountdownDescription: String {
        guard hasScheduledTask else {
            return ""
        }

        if timeRemaining <= 0 {
            return "Starting now..."
        } else if let scheduledDateTime = scheduledDateTime {
            let timeZoneAbbrev = TimeZoneHelper.currentPacificAbbreviation()
            let pstTime = TimeZoneHelper.formatCompactTime(scheduledDateTime, in: TimeZoneHelper.pacificTimeZone)
            return "Starts in \(countdownString) at \(pstTime) \(timeZoneAbbrev)"
        } else {
            return "Starts in \(countdownString)"
        }
    }

    /// Get current timezone context for display
    var timezoneContext: String {
        return TimeZoneHelper.currentTimezoneDescription()
    }
}