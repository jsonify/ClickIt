//
//  ScheduledClickManagerTests.swift
//  ClickIt Tests
//

import XCTest
@testable import ClickItLiteUI

@MainActor
final class ScheduledClickManagerTests: XCTestCase {

    // MARK: - Scheduling State Tests

    func testScheduleFutureDate_returnsScheduledState() throws {
        let manager = ScheduledClickManager(clickAction: {})
        let futureDate = Date().addingTimeInterval(60)

        try manager.schedule(at: futureDate)

        if case .scheduled(let date) = manager.state {
            XCTAssertEqual(date, futureDate)
        } else {
            XCTFail("Expected .scheduled state, got \(manager.state)")
        }
    }

    func testSchedulePastDate_throwsDateInPast() {
        let manager = ScheduledClickManager(clickAction: {})
        let pastDate = Date().addingTimeInterval(-60)

        XCTAssertThrowsError(try manager.schedule(at: pastDate)) { error in
            XCTAssertEqual(error as? ScheduledClickManager.ScheduleError, .dateInPast)
        }
    }

    func testScheduleCurrentDate_throwsDateInPast() {
        let manager = ScheduledClickManager(clickAction: {})
        let now = Date().addingTimeInterval(-0.01)

        XCTAssertThrowsError(try manager.schedule(at: now)) { error in
            XCTAssertEqual(error as? ScheduledClickManager.ScheduleError, .dateInPast)
        }
    }

    // MARK: - Cancel Tests

    func testCancel_resetsToIdle() throws {
        let manager = ScheduledClickManager(clickAction: {})
        let futureDate = Date().addingTimeInterval(60)
        try manager.schedule(at: futureDate)

        manager.cancel()

        XCTAssertEqual(manager.state, .idle)
        XCTAssertEqual(manager.countdown, 0)
    }

    func testCancelWhenIdle_remainsIdle() {
        let manager = ScheduledClickManager(clickAction: {})

        manager.cancel()

        XCTAssertEqual(manager.state, .idle)
    }

    // MARK: - Countdown Tests

    func testCountdown_initialValueReflectsTimeUntilFire() async throws {
        let manager = ScheduledClickManager(clickAction: {})
        let delay: TimeInterval = 3.0
        let futureDate = Date().addingTimeInterval(delay)

        try manager.schedule(at: futureDate)

        // Wait for at least one countdown update from the scheduler (~1s)
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s

        // After 1.2s, countdown should be approximately 1.8s (between 1.0 and 2.5)
        XCTAssertGreaterThan(manager.countdown, 1.0,
            "Countdown should be > 1.0s after 1.2s elapsed, was \(manager.countdown)")
        XCTAssertLessThan(manager.countdown, 2.5,
            "Countdown should be < 2.5s after 1.2s elapsed, was \(manager.countdown)")

        manager.cancel()
    }

    // MARK: - Callback API Tests (post-refactor: executionHandler replaces onFired)

    func testExecutionHandler_calledWhenClickFires() async throws {
        var callbackFired = false
        let manager = ScheduledClickManager(clickAction: {})
        let expectation = expectation(description: "executionHandler called")

        // executionHandler is the renamed onFired — set before scheduling
        manager.executionHandler = {
            callbackFired = true
            expectation.fulfill()
        }

        try manager.schedule(at: Date().addingTimeInterval(1.0))
        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertTrue(callbackFired)
    }

    // MARK: - Fire and Reset Tests

    func testFiresAndResetsToIdle() async throws {
        var clickFired = false
        let manager = ScheduledClickManager(clickAction: { clickFired = true })

        // LiteScheduler fires within ≤5ms of target; 1.5s + generous poll window
        let futureDate = Date().addingTimeInterval(1.5)
        try manager.schedule(at: futureDate)

        let expectation = expectation(description: "Scheduler fires and resets to idle")

        Task { @MainActor in
            for _ in 0..<30 { // poll up to 3 seconds (30 × 100ms)
                if manager.state == .idle && clickFired {
                    expectation.fulfill()
                    return
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }

        await fulfillment(of: [expectation], timeout: 4.0)

        XCTAssertTrue(clickFired, "Click action should have been called")
        XCTAssertEqual(manager.state, .idle, "State should reset to .idle after firing")
        XCTAssertEqual(manager.countdown, 0, "Countdown should be 0 after firing")
    }
}
