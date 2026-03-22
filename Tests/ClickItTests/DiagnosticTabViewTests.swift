//
//  DiagnosticTabViewTests.swift
//  ClickIt Tests
//
//  TDD Red: Tests for DiagnosticTabView.
//  Verifies view can be instantiated in empty and populated states,
//  and that the session model drives the expected display values.
//

import XCTest
import SwiftUI
@testable import ClickItLiteUI

@MainActor
final class DiagnosticTabViewTests: XCTestCase {

    // MARK: - View Instantiation

    func testDiagnosticTabView_canBeCreated_withEmptySession() {
        let session = DiagnosticSession()
        let view = DiagnosticTabView(session: session)
        XCTAssertNotNil(view, "DiagnosticTabView should initialise with an empty session")
    }

    func testDiagnosticTabView_canBeCreated_withPopulatedSession() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 8.0))
        session.add(makeRecord(latencyMs: 25.0))
        let view = DiagnosticTabView(session: session)
        XCTAssertNotNil(view, "DiagnosticTabView should initialise with a populated session")
    }

    // MARK: - Empty State

    func testEmptySession_hasNoStats() {
        let session = DiagnosticSession()
        XCTAssertEqual(session.totalCount, 0)
        XCTAssertNil(session.minDeltaMs)
        XCTAssertNil(session.maxDeltaMs)
        XCTAssertNil(session.averageDeltaMs)
    }

    // MARK: - Stats Display Values

    func testStats_afterOneFiring_allStatsPresent() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 7.0))

        XCTAssertEqual(session.totalCount, 1)
        XCTAssertNotNil(session.minDeltaMs)
        XCTAssertNotNil(session.maxDeltaMs)
        XCTAssertNotNil(session.averageDeltaMs)
    }

    func testStats_multipleFireings_correctValues() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 4.0))
        session.add(makeRecord(latencyMs: 8.0))
        session.add(makeRecord(latencyMs: 12.0))

        XCTAssertEqual(session.totalCount, 3)
        XCTAssertEqual(session.minDeltaMs!, 4.0, accuracy: 0.001)
        XCTAssertEqual(session.maxDeltaMs!, 12.0, accuracy: 0.001)
        XCTAssertEqual(session.averageDeltaMs!, 8.0, accuracy: 0.001)
    }

    // MARK: - Severity Badge Color Tier

    func testSeverityColor_green_forGoodTiming() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 5.0))
        let view = DiagnosticTabView(session: session)
        XCTAssertEqual(view.badgeSeverity, .green)
    }

    func testSeverityColor_yellow_forDegradedTiming() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 25.0))
        let view = DiagnosticTabView(session: session)
        XCTAssertEqual(view.badgeSeverity, .yellow)
    }

    func testSeverityColor_red_forUnacceptableTiming() {
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 100.0))
        let view = DiagnosticTabView(session: session)
        XCTAssertEqual(view.badgeSeverity, .red)
    }

    func testSeverityColor_nil_forEmptySession() {
        let session = DiagnosticSession()
        let view = DiagnosticTabView(session: session)
        XCTAssertNil(view.badgeSeverity)
    }

    func testSeverityColor_reflectsMaxDelta_notAverage() {
        // One very late firing should push severity to red
        // even if the average is within green range.
        let session = DiagnosticSession()
        session.add(makeRecord(latencyMs: 2.0))
        session.add(makeRecord(latencyMs: 2.0))
        session.add(makeRecord(latencyMs: 100.0))
        let view = DiagnosticTabView(session: session)
        XCTAssertEqual(view.badgeSeverity, .red,
            "Badge should reflect worst (max) delta, not average")
    }

    // MARK: - Helpers

    private func makeRecord(latencyMs: Double) -> TimingRecord {
        let scheduled = Date(timeIntervalSinceReferenceDate: 1000.0)
        let actual = scheduled.addingTimeInterval(latencyMs / 1000.0)
        return TimingRecord(scheduledAt: scheduled, actualAt: actual)
    }
}
