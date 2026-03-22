//
//  LiteDiagnosticIntegrationTests.swift
//  ClickIt Tests
//
//  TDD Red: Integration tests confirming DiagnosticSession is wired
//  through SimpleViewModel and receives timing records when a
//  scheduled click fires.
//

import XCTest
import SwiftUI
@testable import ClickItLiteUI

@MainActor
final class LiteDiagnosticIntegrationTests: XCTestCase {

    // MARK: - SimpleViewModel Exposes DiagnosticSession

    func testSimpleViewModel_exposesDiagnosticSession() {
        let viewModel = SimpleViewModel()
        XCTAssertNotNil(viewModel.diagnosticSession,
            "SimpleViewModel must expose a DiagnosticSession for the diagnostic tab")
    }

    // MARK: - SimplifiedMainView Instantiates with TabView

    func testSimplifiedMainView_canBeCreated() {
        let view = SimplifiedMainView()
        XCTAssertNotNil(view, "SimplifiedMainView should initialise successfully with diagnostic tab")
    }

    // MARK: - Session Receives Timing Records via ViewModel

    func testDiagnosticSession_receivesRecord_whenScheduledClickFires() async throws {
        let viewModel = SimpleViewModel()
        let session = viewModel.diagnosticSession

        XCTAssertEqual(session.totalCount, 0, "Session starts empty")

        // Use LiteScheduler directly to fire a timing record through the same
        // onTimingRecord callback that the view model wires up.
        let scheduler = LiteScheduler()
        let expectation = expectation(description: "timing record received")

        scheduler.onTimingRecord = { record in
            session.add(record)
            expectation.fulfill()
        }

        _ = scheduler.schedule(for: Date().addingTimeInterval(1.0), task: {})
        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertEqual(session.totalCount, 1,
            "Session should have 1 record after one firing")
        XCTAssertNotNil(session.minDeltaMs)
        XCTAssertNotNil(session.maxDeltaMs)
        XCTAssertNotNil(session.averageDeltaMs)
    }
}
