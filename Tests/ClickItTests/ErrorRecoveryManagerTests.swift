import XCTest
@testable import ClickIt

final class ErrorRecoveryManagerTests: XCTestCase {
    
    var errorRecoveryManager: ErrorRecoveryManager!
    var mockPermissionManager: MockPermissionManager!
    var mockSystemHealthMonitor: MockSystemHealthMonitor!
    
    override func setUp() {
        super.setUp()
        mockPermissionManager = MockPermissionManager()
        mockSystemHealthMonitor = MockSystemHealthMonitor()
        errorRecoveryManager = ErrorRecoveryManager(
            permissionManager: mockPermissionManager,
            systemHealthMonitor: mockSystemHealthMonitor
        )
    }
    
    override func tearDown() {
        errorRecoveryManager = nil
        mockPermissionManager = nil
        mockSystemHealthMonitor = nil
        super.tearDown()
    }
    
    // MARK: - Error Detection Tests
    
    func testDetectsClickFailureError() {
        // Given
        let clickError = ClickError.eventPostingFailed
        
        // When
        let detectedType = errorRecoveryManager.detectErrorType(from: clickError)
        
        // Then
        XCTAssertEqual(detectedType, .clickFailure)
    }
    
    func testDetectsPermissionError() {
        // Given
        let clickError = ClickError.permissionDenied
        
        // When
        let detectedType = errorRecoveryManager.detectErrorType(from: clickError)
        
        // Then
        XCTAssertEqual(detectedType, .permissionIssue)
    }
    
    func testDetectsSystemResourceError() {
        // Given
        mockSystemHealthMonitor.mockMemoryPressure = true
        
        // When
        let hasResourceIssue = errorRecoveryManager.detectSystemResourceIssues()
        
        // Then
        XCTAssertTrue(hasResourceIssue)
    }
    
    // MARK: - Recovery Strategy Tests
    
    func testAutomaticRetryForClickFailure() async {
        // Given
        let clickError = ClickError.eventPostingFailed
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        
        // Then
        XCTAssertEqual(recoveryAction.strategy, .automaticRetry)
        XCTAssertEqual(recoveryAction.maxRetries, 3)
        XCTAssertTrue(recoveryAction.shouldRetry)
    }
    
    func testPermissionRecoveryStrategy() async {
        // Given
        let clickError = ClickError.permissionDenied
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        mockPermissionManager.mockAccessibilityGranted = false
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        
        // Then
        XCTAssertEqual(recoveryAction.strategy, .recheckPermissions)
        XCTAssertTrue(recoveryAction.shouldRetry)
        XCTAssertNotNil(recoveryAction.permissionStatus)
    }
    
    func testSystemResourceRecoveryStrategy() async {
        // Given
        mockSystemHealthMonitor.mockMemoryPressure = true
        let context = ErrorContext(
            originalError: ClickError.eventCreationFailed,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        
        // Then
        XCTAssertEqual(recoveryAction.strategy, .resourceCleanup)
        XCTAssertTrue(recoveryAction.shouldRetry)
    }
    
    // MARK: - Graceful Degradation Tests
    
    func testGracefulDegradationAfterMaxRetries() async {
        // Given
        let clickError = ClickError.eventPostingFailed
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 3, // Max retries reached
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        
        // Then
        XCTAssertEqual(recoveryAction.strategy, .gracefulDegradation)
        XCTAssertFalse(recoveryAction.shouldRetry)
        XCTAssertNotNil(recoveryAction.userNotification)
    }
    
    func testGracefulDegradationForUnrecoverableErrors() async {
        // Given
        let clickError = ClickError.invalidLocation
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        
        // Then
        XCTAssertEqual(recoveryAction.strategy, .gracefulDegradation)
        XCTAssertFalse(recoveryAction.shouldRetry)
        XCTAssertNotNil(recoveryAction.userNotification)
    }
    
    // MARK: - Error Recovery Integration Tests
    
    func testRecoverySuccessUpdatesStatistics() async {
        // Given
        let clickError = ClickError.eventPostingFailed
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        await errorRecoveryManager.recordRecoveryAttempt(success: true, for: context)
        
        // Then
        let statistics = errorRecoveryManager.getRecoveryStatistics()
        XCTAssertEqual(statistics.totalRecoveryAttempts, 1)
        XCTAssertEqual(statistics.successfulRecoveries, 1)
        XCTAssertEqual(statistics.successRate, 1.0)
    }
    
    func testRecoveryFailureUpdatesStatistics() async {
        // Given
        let clickError = ClickError.permissionDenied
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        await errorRecoveryManager.recordRecoveryAttempt(success: false, for: context)
        
        // Then
        let statistics = errorRecoveryManager.getRecoveryStatistics()
        XCTAssertEqual(statistics.totalRecoveryAttempts, 1)
        XCTAssertEqual(statistics.successfulRecoveries, 0)
        XCTAssertEqual(statistics.successRate, 0.0)
    }
    
    // MARK: - Error Notification Tests
    
    func testCreatesUserNotificationForRecoverableError() async {
        // Given
        let clickError = ClickError.permissionDenied
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        
        // Then
        XCTAssertNotNil(recoveryAction.userNotification)
        XCTAssertTrue(recoveryAction.userNotification!.message.contains("permission"))
        XCTAssertEqual(recoveryAction.userNotification!.severity, .warning)
        XCTAssertTrue(recoveryAction.userNotification!.showRecoveryActions)
    }
    
    func testCreatesUserNotificationForUnrecoverableError() async {
        // Given
        let clickError = ClickError.invalidLocation
        let context = ErrorContext(
            originalError: clickError,
            attemptCount: 0,
            configuration: createTestClickConfiguration()
        )
        
        // When
        let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
        
        // Then
        XCTAssertNotNil(recoveryAction.userNotification)
        XCTAssertTrue(recoveryAction.userNotification!.message.contains("invalid location"))
        XCTAssertEqual(recoveryAction.userNotification!.severity, .error)
        XCTAssertFalse(recoveryAction.userNotification!.showRecoveryActions)
    }
    
    // MARK: - Helper Methods
    
    private func createTestClickConfiguration() -> ClickConfiguration {
        return ClickConfiguration(
            type: .left,
            location: CGPoint(x: 100, y: 100),
            targetPID: nil
        )
    }
}

// MARK: - Mock Classes

class MockPermissionManager: PermissionManagerProtocol {
    var mockAccessibilityGranted = true
    var mockScreenRecordingGranted = true
    
    nonisolated func checkAccessibilityPermission() -> Bool {
        return mockAccessibilityGranted
    }
    
    nonisolated func checkScreenRecordingPermission() -> Bool {
        return mockScreenRecordingGranted
    }
    
    func updatePermissionStatus() {
        // Mock implementation
    }
    
    func requestAccessibilityPermission() async -> Bool {
        return mockAccessibilityGranted
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        return mockScreenRecordingGranted
    }
}

class MockSystemHealthMonitor: SystemHealthMonitorProtocol {
    var mockMemoryPressure = false
    var mockCPUPressure = false
    var mockDiskSpace = true
    
    func checkMemoryPressure() -> Bool {
        return mockMemoryPressure
    }
    
    func checkCPUPressure() -> Bool {
        return mockCPUPressure
    }
    
    func checkDiskSpace() -> Bool {
        return mockDiskSpace
    }
    
    func getSystemResourceStatus() -> SystemResourceStatus {
        return SystemResourceStatus(
            memoryPressure: mockMemoryPressure,
            cpuPressure: mockCPUPressure,
            lowDiskSpace: !mockDiskSpace,
            timestamp: Date()
        )
    }
}