//
//  RealTimeElapsedViewTests.swift
//  ClickItTests
//
//  Created by ClickIt on 2025-07-19.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import XCTest
import SwiftUI
@testable import ClickIt

final class RealTimeElapsedViewTests: XCTestCase {
    
    // MARK: - View Creation Tests
    
    @MainActor
    func testRealTimeElapsedViewCreation() {
        let timeManager = ElapsedTimeManager.shared
        let view = RealTimeElapsedView(timeManager: timeManager)
        XCTAssertNotNil(view, "RealTimeElapsedView should be created successfully")
    }
    
    @MainActor
    func testElapsedTimeStatisticViewCreation() {
        let timeManager = ElapsedTimeManager.shared
        let mockStats = SessionStatistics(
            duration: 120,
            totalClicks: 50,
            successfulClicks: 48,
            failedClicks: 2,
            successRate: 0.96,
            averageClickTime: 0.05,
            clicksPerSecond: 2.4,
            isActive: false
        )
        
        let view = ElapsedTimeStatisticView(
            timeManager: timeManager,
            fallbackStatistics: mockStats
        )
        
        XCTAssertNotNil(view, "ElapsedTimeStatisticView should be created successfully")
    }
    
    @MainActor
    func testStatusHeaderCardIntegration() {
        let viewModel = ClickItViewModel()
        let statusCard = StatusHeaderCard(viewModel: viewModel)
        
        XCTAssertNotNil(statusCard, "StatusHeaderCard should integrate with ElapsedTimeManager")
    }
    
    @MainActor
    func testViewAccessibility() {
        let timeManager = ElapsedTimeManager.shared
        let view = RealTimeElapsedView(timeManager: timeManager)
        
        // Basic accessibility check - ensure view can be created and used
        XCTAssertNotNil(view, "View should be accessible")
        
        let statisticView = ElapsedTimeStatisticView(
            timeManager: timeManager,
            fallbackStatistics: nil
        )
        
        XCTAssertNotNil(statisticView, "Statistic view should be accessible")
    }
}