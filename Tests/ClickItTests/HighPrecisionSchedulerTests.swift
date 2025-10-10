//
//  HighPrecisionSchedulerTests.swift
//  ClickIt Tests
//
//  Created by ClickIt on 2025-10-09.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
@testable import ClickIt

@MainActor
final class HighPrecisionSchedulerTests: XCTestCase {

    // MARK: - Accuracy Tests

    func testSchedulingAccuracy_1Second() async throws {
        let scheduler = HighPrecisionScheduler()
        let expectation = expectation(description: "Task executes at scheduled time")

        let scheduledTime = Date().addingTimeInterval(1.0)
        var actualExecutionTime: Date?

        _ = scheduler.schedule(for: scheduledTime) {
            actualExecutionTime = Date()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        // Verify execution time is within 50ms of scheduled time
        if let actualTime = actualExecutionTime {
            let timingError = abs(actualTime.timeIntervalSince(scheduledTime))
            XCTAssertLessThan(timingError, 0.05, "Timing error should be less than 50ms, was \(timingError * 1000)ms")
            print("✅ 1-second scheduling accuracy: \(timingError * 1000)ms drift")
        } else {
            XCTFail("Task did not execute")
        }
    }

    func testSchedulingAccuracy_5Seconds() async throws {
        let scheduler = HighPrecisionScheduler()
        let expectation = expectation(description: "Task executes at scheduled time")

        let scheduledTime = Date().addingTimeInterval(5.0)
        var actualExecutionTime: Date?

        _ = scheduler.schedule(for: scheduledTime) {
            actualExecutionTime = Date()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 6.0)

        // Verify execution time is within 100ms of scheduled time
        if let actualTime = actualExecutionTime {
            let timingError = abs(actualTime.timeIntervalSince(scheduledTime))
            XCTAssertLessThan(timingError, 0.1, "Timing error should be less than 100ms, was \(timingError * 1000)ms")
            print("✅ 5-second scheduling accuracy: \(timingError * 1000)ms drift")
        } else {
            XCTFail("Task did not execute")
        }
    }

    func testSchedulingAccuracy_30Seconds() async throws {
        let scheduler = HighPrecisionScheduler()
        let expectation = expectation(description: "Task executes at scheduled time")

        let scheduledTime = Date().addingTimeInterval(30.0)
        var actualExecutionTime: Date?

        _ = scheduler.schedule(for: scheduledTime) {
            actualExecutionTime = Date()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 31.0)

        // Verify execution time is within 200ms of scheduled time
        if let actualTime = actualExecutionTime {
            let timingError = abs(actualTime.timeIntervalSince(scheduledTime))
            XCTAssertLessThan(timingError, 0.2, "Timing error should be less than 200ms, was \(timingError * 1000)ms")
            print("✅ 30-second scheduling accuracy: \(timingError * 1000)ms drift")
        } else {
            XCTFail("Task did not execute")
        }
    }

    // MARK: - Cancellation Tests

    func testCancellation() async throws {
        let scheduler = HighPrecisionScheduler()
        let expectation = expectation(description: "Task should not execute")
        expectation.isInverted = true

        let scheduledTime = Date().addingTimeInterval(1.0)

        _ = scheduler.schedule(for: scheduledTime) {
            expectation.fulfill()
        }

        // Cancel after 0.5 seconds
        try await Task.sleep(nanoseconds: 500_000_000)
        scheduler.cancel()

        await fulfillment(of: [expectation], timeout: 2.0)
        print("✅ Cancellation test passed - task did not execute")
    }

    // MARK: - System Time Validation

    func testSystemTimeValidation() {
        let isValid = HighPrecisionScheduler.validateSystemTime()
        XCTAssertTrue(isValid, "System time should be valid")
        print("✅ System time validation passed")
    }

    // MARK: - Past Date Validation

    func testRejectsPastDates() {
        let scheduler = HighPrecisionScheduler()
        let pastDate = Date().addingTimeInterval(-1.0)

        let success = scheduler.schedule(for: pastDate) {
            // Should not execute
        }

        XCTAssertFalse(success, "Should reject past dates")
        print("✅ Past date rejection test passed")
    }

    // MARK: - Performance Comparison

    func testCompareWithTimerAccuracy() async throws {
        print("\n📊 Comparing HighPrecisionScheduler vs Timer accuracy:")

        // Test HighPrecisionScheduler
        let hpScheduler = HighPrecisionScheduler()
        let hpExpectation = expectation(description: "HighPrecisionScheduler execution")

        let hpScheduledTime = Date().addingTimeInterval(2.0)
        var hpActualTime: Date?

        _ = hpScheduler.schedule(for: hpScheduledTime) {
            hpActualTime = Date()
            hpExpectation.fulfill()
        }

        await fulfillment(of: [hpExpectation], timeout: 3.0)

        let hpError = abs(hpActualTime?.timeIntervalSince(hpScheduledTime) ?? 0)
        print("   ⚡ HighPrecisionScheduler drift: \(hpError * 1000)ms")

        // Note: We can't easily test Timer in the same way in a unit test,
        // but this demonstrates the HighPrecisionScheduler accuracy

        XCTAssertLessThan(hpError, 0.05, "HighPrecisionScheduler should be within 50ms")
    }
}
