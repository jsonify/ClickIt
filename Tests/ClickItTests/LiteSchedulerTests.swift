//
//  LiteSchedulerTests.swift
//  ClickIt Tests
//

import XCTest
@testable import ClickItLiteUI

@MainActor
final class LiteSchedulerTests: XCTestCase {

    // MARK: - Schedule Validation

    func testScheduleFutureDate_returnsTrue() {
        let scheduler = LiteScheduler()
        let futureDate = Date().addingTimeInterval(5.0)

        let result = scheduler.schedule(for: futureDate, task: {})

        XCTAssertTrue(result, "schedule(for:task:) should return true for a future date")
    }

    func testSchedulePastDate_returnsFalse() {
        let scheduler = LiteScheduler()
        let pastDate = Date().addingTimeInterval(-1.0)

        let result = scheduler.schedule(for: pastDate, task: {})

        XCTAssertFalse(result, "schedule(for:task:) should return false for a past date")
    }

    func testScheduleNearPastDate_returnsFalse() {
        let scheduler = LiteScheduler()
        let nearPast = Date().addingTimeInterval(-0.01)

        let result = scheduler.schedule(for: nearPast, task: {})

        XCTAssertFalse(result, "schedule(for:task:) should return false for a date in the near past")
    }

    // MARK: - Cancellation

    func testCancel_preventExecution() async throws {
        let scheduler = LiteScheduler()
        var executed = false

        let futureDate = Date().addingTimeInterval(1.0)
        _ = scheduler.schedule(for: futureDate, task: { executed = true })

        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        scheduler.cancel()

        // Wait past the original target to confirm it didn't fire
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s

        XCTAssertFalse(executed, "Cancelled task should not execute")
    }

    func testCancelWhenIdle_doesNotCrash() {
        let scheduler = LiteScheduler()
        // Cancel with nothing scheduled — must not crash
        scheduler.cancel()
    }

    func testGetTimeRemaining_whenIdle_returnsZero() {
        let scheduler = LiteScheduler()
        XCTAssertEqual(scheduler.getTimeRemaining(), 0)
    }

    func testGetTimeRemaining_whenScheduled_isPositive() {
        let scheduler = LiteScheduler()
        let futureDate = Date().addingTimeInterval(10.0)

        _ = scheduler.schedule(for: futureDate, task: {})

        XCTAssertGreaterThan(scheduler.getTimeRemaining(), 0)
        scheduler.cancel()
    }

    // MARK: - Execution Handler

    func testExecutionHandler_calledWhenTaskFires() async throws {
        let scheduler = LiteScheduler()
        let expectation = expectation(description: "executionHandler called")

        scheduler.executionHandler = {
            expectation.fulfill()
        }

        _ = scheduler.schedule(for: Date().addingTimeInterval(1.0), task: {})

        await fulfillment(of: [expectation], timeout: 3.0)
    }

    func testScheduledTask_executedWhenFires() async throws {
        let scheduler = LiteScheduler()
        var taskExecuted = false
        let expectation = expectation(description: "task closure executed")

        _ = scheduler.schedule(for: Date().addingTimeInterval(1.0), task: {
            taskExecuted = true
            expectation.fulfill()
        })

        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertTrue(taskExecuted)
    }

    // MARK: - Countdown Update Handler

    func testCountdownUpdateHandler_calledWithDecreasingValues() async throws {
        let scheduler = LiteScheduler()
        var samples: [TimeInterval] = []
        let expectation = expectation(description: "at least 2 countdown updates received")
        expectation.expectedFulfillmentCount = 2

        scheduler.countdownUpdateHandler = { remaining in
            samples.append(remaining)
            if samples.count <= 2 {
                expectation.fulfill()
            }
        }

        let futureDate = Date().addingTimeInterval(5.0)
        _ = scheduler.schedule(for: futureDate, task: {})

        await fulfillment(of: [expectation], timeout: 3.0)
        scheduler.cancel()

        XCTAssertGreaterThanOrEqual(samples.count, 2)
        // Each sample should be less than the previous (countdown decreasing)
        if samples.count >= 2 {
            XCTAssertGreaterThan(samples[0], samples[1],
                "Countdown values should decrease over time")
        }
    }

    // MARK: - Timing Accuracy

    func testTimingAccuracy_1Second() async throws {
        let scheduler = LiteScheduler()
        let expectation = expectation(description: "fires within 50ms of target")

        let scheduledTime = Date().addingTimeInterval(1.0)
        var actualTime: Date?

        _ = scheduler.schedule(for: scheduledTime, task: {
            actualTime = Date()
            expectation.fulfill()
        })

        await fulfillment(of: [expectation], timeout: 2.0)

        if let actual = actualTime {
            let drift = abs(actual.timeIntervalSince(scheduledTime))
            XCTAssertLessThan(drift, 0.05, "Should fire within 50ms, drift was \(drift * 1000)ms")
        } else {
            XCTFail("Task did not execute")
        }
    }

    // MARK: - Reschedule

    func testReschedule_cancelsExistingAndSchedulesNew() async throws {
        let scheduler = LiteScheduler()
        var firstFired = false
        var secondFired = false
        let expectation = expectation(description: "second task fires")

        // Schedule first task far in the future
        _ = scheduler.schedule(for: Date().addingTimeInterval(60.0), task: {
            firstFired = true
        })

        // Reschedule with a near-future task (replaces the first)
        _ = scheduler.schedule(for: Date().addingTimeInterval(1.0), task: {
            secondFired = true
            expectation.fulfill()
        })

        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertFalse(firstFired, "First task should have been replaced")
        XCTAssertTrue(secondFired, "Second task should have fired")
    }
}
