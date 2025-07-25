import XCTest
@testable import ClickIt

@MainActor
final class TimerConcurrencyValidationTest: XCTestCase {
    
    func testTimerAutomationEngineBuildsWithoutConcurrencyIssues() async throws {
        // This test simply verifies that TimerAutomationEngine can be instantiated
        // and started without concurrency crashes, validating our MainActor fixes
        
        let timerEngine = TimerAutomationEngine()
        
        // Create minimal test configuration
        let cpsConfig = CPSRandomizer.Configuration(
            enabled: false,
            variancePercentage: 0.0,
            distributionPattern: .uniform,
            humannessLevel: .low,
            minimumInterval: 0.01,
            maximumInterval: 1.0,
            patternBreakupFrequency: 0.0
        )
        
        let config = AutomationConfiguration(
            location: CGPoint(x: 100, y: 100),
            clickType: .left,
            clickInterval: 0.5, // 2 CPS - slow for testing
            targetApplication: nil,
            maxClicks: 1, // Just one click
            maxDuration: nil,
            stopOnError: false,
            randomizeLocation: false,
            locationVariance: 0,
            useDynamicMouseTracking: false,
            cpsRandomizerConfig: cpsConfig
        )
        
        // Start automation - this should not crash due to concurrency issues
        timerEngine.startAutomation(with: config)
        
        // Brief wait to allow timer callback to execute safely
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Stop automation
        timerEngine.stopAutomation()
        
        // Test passes if we reach here without crashes
        XCTAssertEqual(timerEngine.automationState, .idle)
        print("✅ TimerAutomationEngine concurrency fix validated successfully")
    }
}