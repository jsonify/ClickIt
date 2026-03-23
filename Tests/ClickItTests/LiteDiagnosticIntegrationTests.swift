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

    // MARK: - Session Receives Timing Records via ViewModel Wiring

    func testDiagnosticSession_receivesRecord_whenScheduledClickFires() async throws {
        // Inject a no-op click action so no permissions are needed in CI.
        let testManager = ScheduledClickManager(clickAction: {})
        let viewModel = SimpleViewModel(scheduledClickManager: testManager)
        let session = viewModel.diagnosticSession

        XCTAssertEqual(session.totalCount, 0, "Session starts empty")

        try viewModel.scheduleClick(at: Date().addingTimeInterval(0.2))

        // Poll until the session is updated or we time out.
        let deadline = Date.now.addingTimeInterval(2.0)
        while session.totalCount == 0 && Date.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }

        XCTAssertEqual(session.totalCount, 1,
            "Session should have 1 record after one firing")
        XCTAssertNotNil(session.minDeltaMs)
        XCTAssertNotNil(session.maxDeltaMs)
        XCTAssertNotNil(session.averageDeltaMs)
    }
}
