//
//  TimingDiagnosticTests.swift
//  ClickIt Tests
//

import XCTest
@testable import ClickItLiteUI

final class TimingDiagnosticTests: XCTestCase {

    // MARK: - TimingRecord.Severity

    func testSeverity_green_whenDeltaAtOrBelowTenMs() {
        let severities: [(Double, TimingRecord.Severity)] = [
            (0.0, .green),
            (5.0, .green),
            (10.0, .green),
        ]
        for (delta, expected) in severities {
            XCTAssertEqual(TimingRecord.Severity(delta: delta), expected,
                "delta \(delta)ms should be .green")
        }
    }

    func testSeverity_yellow_whenDeltaBetweenTenAndFiftyMs() {
        let severities: [(Double, TimingRecord.Severity)] = [
            (10.1, .yellow),
            (25.0, .yellow),
            (50.0, .yellow),
        ]
        for (delta, expected) in severities {
            XCTAssertEqual(TimingRecord.Severity(delta: delta), expected,
                "delta \(delta)ms should be .yellow")
        }
    }

    func testSeverity_red_whenDeltaAboveFiftyMs() {
        let severities: [(Double, TimingRecord.Severity)] = [
            (50.1, .red),
            (100.0, .red),
            (500.0, .red),
        ]
        for (delta, expected) in severities {
            XCTAssertEqual(TimingRecord.Severity(delta: delta), expected,
                "delta \(delta)ms should be .red")
        }
    }

    func testSeverity_usesAbsoluteDelta_forNegative() {
        // Negative delta (early) uses absolute value for severity
        XCTAssertEqual(TimingRecord.Severity(delta: -5.0), .green)
        XCTAssertEqual(TimingRecord.Severity(delta: -25.0), .yellow)
        XCTAssertEqual(TimingRecord.Severity(delta: -100.0), .red)
    }

    // MARK: - TimingRecord

    func testTimingRecord_delta_isPositiveWhenLate() {
        let scheduled = Date(timeIntervalSinceReferenceDate: 1000.0)
        let actual = Date(timeIntervalSinceReferenceDate: 1000.010) // 10ms late
        let record = TimingRecord(scheduledAt: scheduled, actualAt: actual)
        XCTAssertEqual(record.deltaMs, 10.0, accuracy: 0.001)
    }

    func testTimingRecord_delta_isNegativeWhenEarly() {
        let scheduled = Date(timeIntervalSinceReferenceDate: 1000.0)
        let actual = Date(timeIntervalSinceReferenceDate: 999.995) // 5ms early
        let record = TimingRecord(scheduledAt: scheduled, actualAt: actual)
        XCTAssertEqual(record.deltaMs, -5.0, accuracy: 0.001)
    }

    func testTimingRecord_severity_derivedFromDelta() {
        let scheduled = Date(timeIntervalSinceReferenceDate: 1000.0)
        let actual = Date(timeIntervalSinceReferenceDate: 1000.005) // 5ms late
        let record = TimingRecord(scheduledAt: scheduled, actualAt: actual)
        XCTAssertEqual(record.severity, .green)
    }

    // MARK: - DiagnosticSession

    func testDiagnosticSession_startsEmpty() {
        let session = DiagnosticSession()
        XCTAssertEqual(session.totalCount, 0)
        XCTAssertNil(session.minDeltaMs)
        XCTAssertNil(session.maxDeltaMs)
        XCTAssertNil(session.averageDeltaMs)
    }

    func testDiagnosticSession_addRecord_incrementsCount() {
        let session = DiagnosticSession()
        let record = makeRecord(latencyMs: 5.0)
        session.add(record)
        XCTAssertEqual(session.totalCount, 1)
    }

    func testDiagnosticSession_minDelta_tracksSmallestAbsoluteValue() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 20.0))
        session.add(makeRecord(latencyMs: 5.0))
        session.add(makeRecord(latencyMs: 15.0))
        XCTAssertEqual(session.minDeltaMs!, 5.0, accuracy: 0.001)
    }

    func testDiagnosticSession_maxDelta_tracksLargestAbsoluteValue() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 20.0))
        session.add(makeRecord(latencyMs: 5.0))
        session.add(makeRecord(latencyMs: 100.0))
        XCTAssertEqual(session.maxDeltaMs!, 100.0, accuracy: 0.001)
    }

    func testDiagnosticSession_averageDelta_isCorrect() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 10.0))
        session.add(makeRecord(latencyMs: 20.0))
        session.add(makeRecord(latencyMs: 30.0))
        XCTAssertEqual(session.averageDeltaMs!, 20.0, accuracy: 0.001)
    }

    func testDiagnosticSession_multipleRecords_statsUpdateCorrectly() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 8.0))
        session.add(makeRecord(latencyMs: 12.0))

        XCTAssertEqual(session.totalCount, 2)
        XCTAssertEqual(session.minDeltaMs!, 8.0, accuracy: 0.001)
        XCTAssertEqual(session.maxDeltaMs!, 12.0, accuracy: 0.001)
        XCTAssertEqual(session.averageDeltaMs!, 10.0, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeRecord(latencyMs: Double) -> TimingRecord {
        let scheduled = Date(timeIntervalSinceReferenceDate: 1000.0)
        let actual = scheduled.addingTimeInterval(latencyMs / 1000.0)
        return TimingRecord(scheduledAt: scheduled, actualAt: actual)
    }
}
