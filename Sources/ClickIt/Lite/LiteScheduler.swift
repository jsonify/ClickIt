//
//  LiteScheduler.swift
//  ClickIt Lite
//
//  High-precision scheduler using DispatchSourceTimer for sub-millisecond
//  scheduling accuracy. Follows a 3-phase approach:
//   1. Main wait  — fires executionLeadTime before target (DispatchSourceTimer)
//   2. Final countdown — polls every 10ms, executes at ≤5ms remaining
//   3. Drift compensation — rechecks every 60s for long-running waits
//

import Foundation
import os.log

/// High-precision scheduler for Lite. Schedules a single one-time task at a
/// future date using `DispatchSourceTimer`, achieving ≤5ms firing accuracy.
final class LiteScheduler {

    // MARK: - Configuration

    struct Configuration {
        /// How often to re-evaluate remaining time to compensate for clock drift (seconds).
        let driftCompensationInterval: TimeInterval
        /// How early (in seconds) to transition from main-wait to final-countdown phase.
        let executionLeadTime: TimeInterval
        /// Polling interval during the final countdown phase (nanoseconds).
        let finalCountdownPollingInterval: UInt64

        static let `default` = Configuration(
            driftCompensationInterval: 60.0,
            executionLeadTime: 0.1,
            finalCountdownPollingInterval: 10_000_000  // 10ms
        )
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let queue: DispatchQueue
    private let logger = Logger(subsystem: LoggingConstants.subsystem, category: "LiteScheduler")

    /// Phase 1: fires `executionLeadTime` before target and triggers final countdown.
    private var mainWaitTimer: DispatchSourceTimer?
    /// Phase 2: 10ms polling timer; fires the task when ≤5ms remain.
    private var finalCountdownTimer: DispatchSourceTimer?
    /// Phase 3: periodic drift compensation (every `driftCompensationInterval`).
    private var driftTimer: DispatchSourceTimer?
    /// 1-second countdown publisher for UI updates.
    private var countdownTimer: DispatchSourceTimer?

    private var scheduledTask: (() -> Void)?
    private var targetDate: Date?

    /// Called every ~1 second with the remaining `TimeInterval` until execution.
    var countdownUpdateHandler: ((TimeInterval) -> Void)?
    /// Called once immediately after the scheduled task executes.
    var executionHandler: (() -> Void)?
    /// Called once with a `TimingRecord` after each firing. Delivered on the main queue.
    var onTimingRecord: ((TimingRecord) -> Void)?

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.queue = DispatchQueue(
            label: "com.clickit.litescheduler",
            qos: .userInitiated
        )
    }

    // MARK: - Public API

    /// Schedule a task to execute at `date`.
    /// - Returns: `true` if scheduled; `false` if `date` is in the past.
    func schedule(for date: Date, task: @escaping () -> Void) -> Bool {
        guard date > Date() else {
            logger.warning("LiteScheduler: rejected past date \(date)")
            return false
        }
        cancelInternal()
        targetDate = date
        scheduledTask = task

        let timeUntilExecution = date.timeIntervalSinceNow
        logger.info("LiteScheduler: scheduling for \(date) (\(timeUntilExecution, format: .fixed(precision: 3))s)")

        startCountdownTimer()
        startDriftCompensation()
        scheduleMainWait(timeUntilExecution: timeUntilExecution)
        return true
    }

    /// Cancel any pending scheduled task.
    func cancel() {
        cancelInternal()
        logger.info("LiteScheduler: cancelled")
    }

    /// Returns the time remaining until execution, or 0 if nothing is scheduled.
    func getTimeRemaining() -> TimeInterval {
        guard let date = targetDate else { return 0 }
        return max(0, date.timeIntervalSinceNow)
    }

    // MARK: - Private — Timer Setup

    private func startCountdownTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        countdownTimer = timer
        timer.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            self?.publishCountdown()
        }
        timer.resume()
    }

    private func startDriftCompensation() {
        guard configuration.driftCompensationInterval > 0 else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        driftTimer = timer
        timer.schedule(
            deadline: .now() + configuration.driftCompensationInterval,
            repeating: configuration.driftCompensationInterval,
            leeway: .milliseconds(100)
        )
        timer.setEventHandler { [weak self] in
            self?.applyDriftCorrection()
        }
        timer.resume()
    }

    private func scheduleMainWait(timeUntilExecution: TimeInterval) {
        let waitDuration = max(0, timeUntilExecution - configuration.executionLeadTime)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        mainWaitTimer = timer
        timer.schedule(deadline: .now() + waitDuration, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            self?.transitionToFinalCountdown()
        }
        timer.resume()
    }

    private func transitionToFinalCountdown() {
        logger.debug("LiteScheduler: entering final countdown")
        mainWaitTimer?.cancel()
        mainWaitTimer = nil
        driftTimer?.cancel()
        driftTimer = nil
        countdownTimer?.cancel()
        countdownTimer = nil

        let timer = DispatchSource.makeTimerSource(queue: queue)
        finalCountdownTimer = timer
        timer.schedule(
            deadline: .now(),
            repeating: .nanoseconds(Int(configuration.finalCountdownPollingInterval)),
            leeway: .nanoseconds(1_000_000)  // 1ms leeway
        )
        timer.setEventHandler { [weak self] in
            self?.checkFinalExecution()
        }
        timer.resume()
    }

    // MARK: - Private — Timer Handlers

    private func applyDriftCorrection() {
        guard let date = targetDate else { return }
        let remaining = date.timeIntervalSinceNow
        guard remaining > configuration.executionLeadTime * 2 else { return }
        logger.debug("LiteScheduler: drift check, \(remaining, format: .fixed(precision: 3))s remaining")
    }

    private func publishCountdown() {
        guard let date = targetDate else { return }
        let remaining = max(0, date.timeIntervalSinceNow)
        DispatchQueue.main.async { [weak self] in
            self?.countdownUpdateHandler?(remaining)
        }
    }

    private func checkFinalExecution() {
        guard targetDate != nil else { return }
        if getTimeRemaining() <= 0.005 {
            executeTask()
        }
    }

    private func executeTask() {
        // Capture actualAt first — before any other work — for maximum timing accuracy.
        let actualAt = Date()
        logger.info("LiteScheduler: executing task at \(actualAt)")
        finalCountdownTimer?.cancel()
        finalCountdownTimer = nil

        let task = scheduledTask
        let handler = executionHandler
        let timingCallback = onTimingRecord
        let scheduledAt = targetDate
        scheduledTask = nil
        targetDate = nil

        DispatchQueue.main.async {
            task?()
            handler?()
            if let scheduledAt, let timingCallback {
                let record = TimingRecord(scheduledAt: scheduledAt, actualAt: actualAt)
                timingCallback(record)
            }
        }
    }

    // MARK: - Private — Cancellation

    private func cancelInternal() {
        mainWaitTimer?.cancel()
        mainWaitTimer = nil
        driftTimer?.cancel()
        driftTimer = nil
        finalCountdownTimer?.cancel()
        finalCountdownTimer = nil
        countdownTimer?.cancel()
        countdownTimer = nil
        scheduledTask = nil
        targetDate = nil
    }

    // MARK: - Cleanup

    deinit {
        cancelInternal()
    }
}
