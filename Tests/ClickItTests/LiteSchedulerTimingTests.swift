//
//  LiteSchedulerTimingTests.swift
//  ClickIt Tests
//
//  TDD Red: Tests for LiteScheduler timing instrumentation.
//  Verifies that onTimingRecord delivers an accurate TimingRecord
//  when a scheduled task fires.
//

import XCTest
@testable import ClickItLiteUI

@MainActor
final class LiteSchedulerTimingTests: XCTestCase {

    // MARK: - onTimingRecord Callback

    func testOnTimingRecord_calledWhenTaskFires() async throws {
        let scheduler = LiteScheduler()
        let expectation = expectation(description: "onTimingRecord called")

        scheduler.onTimingRecord = { _ in
            expectation.fulfill()
        }

        _ = scheduler.schedule(for: Date().addingTimeInterval(1.0), task: {})

        await fulfillment(of: [expectation], timeout: 3.0)
    }

    func testOnTimingRecord_scheduledAt_matchesTargetDate() async throws {
        let scheduler = LiteScheduler()
        let targetDate = Date().addingTimeInterval(1.0)
        var receivedRecord: TimingRecord?
        let expectation = expectation(description: "onTimingRecord received")

        scheduler.onTimingRecord = { record in
            receivedRecord = record
            expectation.fulfill()
        }

        _ = scheduler.schedule(for: targetDate, task: {})

        await fulfillment(of: [expectation], timeout: 3.0)

        let record = try XCTUnwrap(receivedRecord)
        XCTAssertEqual(record.scheduledAt.timeIntervalSinceReferenceDate,
                       targetDate.timeIntervalSinceReferenceDate,
                       accuracy: 0.001,
                       "scheduledAt should match the date passed to schedule(for:task:)")
    }

    func testOnTimingRecord_actualAt_capturedAtFiringTime() async throws {
        let scheduler = LiteScheduler()
        let targetDate = Date().addingTimeInterval(1.0)
        var receivedRecord: TimingRecord?
        let beforeFire = Date()
        let expectation = expectation(description: "onTimingRecord received")

        scheduler.onTimingRecord = { record in
            receivedRecord = record
            expectation.fulfill()
        }

        _ = scheduler.schedule(for: targetDate, task: {})

        await fulfillment(of: [expectation], timeout: 3.0)

        let afterFire = Date()
        let record = try XCTUnwrap(receivedRecord)

        XCTAssertGreaterThanOrEqual(record.actualAt, beforeFire,
            "actualAt should not be before the scheduler started")
        XCTAssertLessThanOrEqual(record.actualAt, afterFire,
            "actualAt should not be after the callback was received")
    }

    func testOnTimingRecord_deltaMs_isReasonablySmall() async throws {
        let scheduler = LiteScheduler()
        var receivedRecord: TimingRecord?
        let expectation = expectation(description: "onTimingRecord received")

        scheduler.onTimingRecord = { record in
            receivedRecord = record
            expectation.fulfill()
        }

        _ = scheduler.schedule(for: Date().addingTimeInterval(1.0), task: {})

        await fulfillment(of: [expectation], timeout: 3.0)

        let record = try XCTUnwrap(receivedRecord)
        XCTAssertLessThan(abs(record.deltaMs), 200.0,
            "delta should be within 200ms for a 1-second schedule (was \(record.deltaMs)ms)")
    }

    func testOnTimingRecord_notCalledAfterCancel() async throws {
        let scheduler = LiteScheduler()
        var callCount = 0
        let expectation = expectation(description: "waited without callback")
        expectation.isInverted = true

        scheduler.onTimingRecord = { _ in
            callCount += 1
            expectation.fulfill()
        }

        _ = scheduler.schedule(for: Date().addingTimeInterval(1.0), task: {})
        scheduler.cancel()

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(callCount, 0, "onTimingRecord should not fire after cancel")
    }
}
