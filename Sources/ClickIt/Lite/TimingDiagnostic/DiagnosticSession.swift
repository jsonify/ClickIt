//
//  DiagnosticSession.swift
//  ClickIt Lite
//
//  Timing accuracy model for the Lite scheduler diagnostic tab.
//  Passively records each scheduled click's timing error (delta between
//  scheduled fire time and actual fire time) and aggregates session stats.
//

import Foundation
import Observation

// MARK: - TimingRecord

/// A single timing observation from one scheduled click firing.
struct TimingRecord {
    /// The time the click was scheduled to fire.
    let scheduledAt: Date
    /// The time the click actually fired (captured at the top of the execution handler).
    let actualAt: Date

    /// Difference in milliseconds: positive = late, negative = early.
    var deltaMs: Double {
        (actualAt.timeIntervalSince(scheduledAt)) * 1000.0
    }

    /// Accuracy severity based on the absolute delta.
    var severity: Severity {
        Severity(delta: deltaMs)
    }

    // MARK: Severity

    enum Severity: Equatable {
        /// |delta| ≤ 10ms — within ClickIt's sub-10ms accuracy goal.
        case green
        /// 10ms < |delta| ≤ 50ms — degraded.
        case yellow
        /// |delta| > 50ms — unacceptable.
        case red

        init(delta: Double) {
            let abs = Swift.abs(delta)
            if abs <= 10.0 {
                self = .green
            } else if abs <= 50.0 {
                self = .yellow
            } else {
                self = .red
            }
        }
    }
}

// MARK: - DiagnosticSession

/// Session-scoped accumulator of `TimingRecord` values.
/// Resets on app launch (in-memory only, no persistence).
@Observable
final class DiagnosticSession {

    // MARK: - Public State

    /// Total number of firings recorded this session.
    private(set) var totalCount: Int = 0

    /// Smallest delta (in ms) recorded this session; `nil` if no firings yet.
    private(set) var minDeltaMs: Double?

    /// Largest delta (in ms) recorded this session; `nil` if no firings yet.
    private(set) var maxDeltaMs: Double?

    /// Mean delta (in ms) across all firings; `nil` if no firings yet.
    private(set) var averageDeltaMs: Double?

    // MARK: - Private State

    private var runningSum: Double = 0.0

    // MARK: - Public API

    /// Record a new timing observation and update session statistics.
    func add(_ record: TimingRecord) {
        let abs = Swift.abs(record.deltaMs)

        totalCount += 1
        runningSum += abs

        if let current = minDeltaMs {
            minDeltaMs = Swift.min(current, abs)
        } else {
            minDeltaMs = abs
        }

        if let current = maxDeltaMs {
            maxDeltaMs = Swift.max(current, abs)
        } else {
            maxDeltaMs = abs
        }

        averageDeltaMs = runningSum / Double(totalCount)
    }
}
