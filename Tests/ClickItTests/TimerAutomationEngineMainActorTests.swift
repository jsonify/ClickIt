import XCTest
@testable import ClickIt

@MainActor
final class TimerAutomationEngineMainActorTests: XCTestCase {
    
    var timerEngine: TimerAutomationEngine!
    var clickCoordinator: ClickCoordinator!
    var performanceMonitor: PerformanceMonitor!
    var permissionManager: PermissionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        permissionManager = PermissionManager.shared
        performanceMonitor = PerformanceMonitor.shared
        clickCoordinator = ClickCoordinator.shared
        timerEngine = TimerAutomationEngine(
            clickCoordinator: clickCoordinator,
            performanceMonitor: performanceMonitor
        )
    }
    
    override func tearDown() async throws {
        timerEngine.stopAutomation()
        timerEngine = nil
        clickCoordinator = nil
        performanceMonitor = nil
        permissionManager = nil
        try await super.tearDown()
    }
    
    // MARK: - MainActor Safety Tests
    
    func testHighPrecisionTimerCallbackMainActorSafety() async throws {
        // Test that high-precision timer callbacks execute safely on MainActor
        
        // Create automation configuration for testing
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
            clickInterval: 0.1, // 10 CPS
            targetApplication: nil,
            maxClicks: 5, // Limit clicks for testing
            maxDuration: nil,
            stopOnError: false,
            randomizeLocation: false,
            locationVariance: 0,
            useDynamicMouseTracking: false,
            cpsRandomizerConfig: cpsConfig
        )
        
        // Start automation to trigger high-precision timer
        timerEngine.startAutomation(with: config)
        
        // Wait briefly to allow timer callbacks (should be safe on MainActor)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify timer is running (should be safe to access on MainActor)
        XCTAssertEqual(timerEngine.automationState, .running)
        
        // Stop automation
        timerEngine.stopAutomation()
        
        // Verify cleanup
        XCTAssertEqual(timerEngine.automationState, .idle)
    }
    
    func testConcurrentPermissionMonitoringWithHighPrecisionTimer() async throws {
        // Test that permission monitoring doesn't interfere with high-precision timer
        
        // Start permission monitoring
        permissionManager.startPermissionMonitoring()
        
        // Create test configuration
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
            clickInterval: 0.05, // 20 CPS
            targetApplication: nil,
            maxClicks: 3, // Limit for testing
            maxDuration: nil,
            stopOnError: false,
            randomizeLocation: false,
            locationVariance: 0,
            useDynamicMouseTracking: false,
            cpsRandomizerConfig: cpsConfig
        )
        
        // Start concurrent operations
        timerEngine.startAutomation(with: config)
        
        // Allow concurrent operations to run
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Verify timer is operating
        XCTAssertEqual(timerEngine.automationState, .running)
        
        // Stop operations
        timerEngine.stopAutomation()
        permissionManager.stopPermissionMonitoring()
        
        // Verify clean shutdown
        XCTAssertEqual(timerEngine.automationState, .idle)
    }
    
    func testTimerCallbackErrorHandling() async throws {
        // Test that timer callbacks handle errors gracefully without crashing
        
        // Create configuration with potentially problematic values
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
            location: CGPoint(x: -100, y: -100), // Invalid coordinates
            clickType: .left,
            clickInterval: 0.2, // 5 CPS
            targetApplication: "NonExistentApp",
            maxClicks: 2, // Limit for testing
            maxDuration: nil,
            stopOnError: false, // Continue despite errors
            randomizeLocation: false,
            locationVariance: 0,
            useDynamicMouseTracking: false,
            cpsRandomizerConfig: cpsConfig
        )
        
        // Start automation - should not crash despite invalid configuration
        timerEngine.startAutomation(with: config)
        
        // Allow timer to attempt clicks with invalid config
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Should still be able to stop safely
        timerEngine.stopAutomation()
        
        // Verify clean shutdown
        XCTAssertEqual(timerEngine.automationState, .idle)
    }
    
    func testHighFrequencyTimerStability() async throws {
        // Test high-frequency timer operations for MainActor stability
        
        // Configure for high frequency
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
            location: CGPoint(x: 200, y: 200),
            clickType: .left,
            clickInterval: 0.02, // 50 CPS
            targetApplication: nil,
            maxClicks: 5, // Limit for testing
            maxDuration: nil,
            stopOnError: false,
            randomizeLocation: false,
            locationVariance: 0,
            useDynamicMouseTracking: false,
            cpsRandomizerConfig: cpsConfig
        )
        
        // Start high-frequency automation
        timerEngine.startAutomation(with: config)
        
        // Run for short duration to test stability
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify timer is still active and responsive
        XCTAssertEqual(timerEngine.automationState, .running)
        
        // Should be able to stop cleanly
        timerEngine.stopAutomation()
        XCTAssertEqual(timerEngine.automationState, .idle)
    }
}