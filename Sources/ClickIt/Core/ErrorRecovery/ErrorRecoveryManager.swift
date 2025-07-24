import Foundation
import CoreGraphics
import Combine

/// Comprehensive error recovery manager for handling click failures, permission issues, and system resource problems
class ErrorRecoveryManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isRecovering: Bool = false
    @Published var lastRecoveryAttempt: Date?
    @Published var recoveryStatistics: RecoveryStatistics = RecoveryStatistics()
    @Published var currentErrorNotification: ErrorNotification?
    
    // MARK: - Private Properties
    
    private let permissionManager: PermissionManagerProtocol
    private let systemHealthMonitor: SystemHealthMonitorProtocol
    private var recoveryHistory: [RecoveryAttempt] = []
    private let maxRecoveryAttempts = 3
    private let recoveryTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    init(
        permissionManager: PermissionManagerProtocol? = nil,
        systemHealthMonitor: SystemHealthMonitorProtocol? = nil
    ) {
        self.permissionManager = permissionManager ?? PermissionManager.shared
        self.systemHealthMonitor = systemHealthMonitor ?? SystemHealthMonitor.shared
    }
    
    // MARK: - Error Detection
    
    /// Detects the type of error from a ClickError
    func detectErrorType(from clickError: ClickError) -> ErrorType {
        switch clickError {
        case .permissionDenied:
            return .permissionIssue
        case .targetProcessNotFound:
            return .targetProcessIssue
        case .eventCreationFailed, .eventPostingFailed:
            return .clickFailure
        case .timingConstraintViolation:
            return .performanceIssue
        case .invalidLocation:
            return .configurationError
        }
    }
    
    /// Detects system resource issues that might affect clicking operations
    func detectSystemResourceIssues() -> Bool {
        let resourceStatus = systemHealthMonitor.getSystemResourceStatus()
        return resourceStatus.memoryPressure || resourceStatus.cpuPressure || resourceStatus.lowDiskSpace
    }
    
    /// Performs comprehensive error analysis
    func analyzeError(from clickError: ClickError, context: ErrorContext) -> ErrorAnalysis {
        let errorType = detectErrorType(from: clickError)
        let hasSystemIssues = detectSystemResourceIssues()
        let permissionStatus = PermissionStatus(
            accessibility: permissionManager.checkAccessibilityPermission(),
            screenRecording: permissionManager.checkScreenRecordingPermission()
        )
        
        return ErrorAnalysis(
            errorType: errorType,
            originalError: clickError,
            systemResourceIssues: hasSystemIssues,
            permissionStatus: permissionStatus,
            context: context,
            timestamp: Date()
        )
    }
    
    // MARK: - Recovery Strategies
    
    /// Attempts to recover from an error using appropriate strategy
    func attemptRecovery(for context: ErrorContext) async -> RecoveryAction {
        isRecovering = true
        lastRecoveryAttempt = Date()
        
        defer {
            isRecovering = false
        }
        
        let analysis = analyzeError(from: context.originalError, context: context)
        
        // Check if we've exceeded max retries
        if context.attemptCount >= maxRecoveryAttempts {
            return createGracefulDegradationAction(for: analysis)
        }
        
        // Determine recovery strategy based on error type
        switch analysis.errorType {
        case .permissionIssue:
            return await createPermissionRecoveryAction(for: analysis)
        case .clickFailure:
            return await createClickFailureRecoveryAction(for: analysis)
        case .targetProcessIssue:
            return await createProcessRecoveryAction(for: analysis)
        case .performanceIssue:
            return await createPerformanceRecoveryAction(for: analysis)
        case .configurationError:
            return createConfigurationErrorAction(for: analysis)
        case .systemResource:
            return await createSystemResourceRecoveryAction(for: analysis)
        }
    }
    
    // MARK: - Specific Recovery Actions
    
    private func createPermissionRecoveryAction(for analysis: ErrorAnalysis) async -> RecoveryAction {
        // Attempt to recheck permissions
        let updatedPermissions = PermissionStatus(
            accessibility: permissionManager.checkAccessibilityPermission(),
            screenRecording: permissionManager.checkScreenRecordingPermission()
        )
        
        let notification = ErrorNotification(
            id: UUID(),
            title: "Permission Issue Detected",
            message: "ClickIt is attempting to recover from a permission error. Please ensure accessibility permissions are granted.",
            severity: .warning,
            timestamp: Date(),
            showRecoveryActions: true,
            recoveryActions: [
                RecoveryActionButton(
                    title: "Open System Settings",
                    action: .openSystemSettings(.accessibility)
                ),
                RecoveryActionButton(
                    title: "Retry",
                    action: .retry
                )
            ]
        )
        
        currentErrorNotification = notification
        
        return RecoveryAction(
            strategy: .recheckPermissions,
            shouldRetry: updatedPermissions.accessibility,
            maxRetries: 2,
            retryDelay: 2.0,
            userNotification: notification,
            permissionStatus: updatedPermissions
        )
    }
    
    private func createClickFailureRecoveryAction(for analysis: ErrorAnalysis) async -> RecoveryAction {
        let notification = ErrorNotification(
            id: UUID(),
            title: "Click Operation Failed",
            message: "ClickIt is automatically retrying the click operation. This may be due to temporary system conditions.",
            severity: .info,
            timestamp: Date(),
            showRecoveryActions: false
        )
        
        currentErrorNotification = notification
        
        return RecoveryAction(
            strategy: .automaticRetry,
            shouldRetry: true,
            maxRetries: 3,
            retryDelay: 0.5,
            userNotification: notification
        )
    }
    
    private func createProcessRecoveryAction(for analysis: ErrorAnalysis) async -> RecoveryAction {
        let notification = ErrorNotification(
            id: UUID(),
            title: "Target Process Not Found",
            message: "The target application may have closed or become unavailable. ClickIt will attempt to continue with system-wide clicks.",
            severity: .warning,
            timestamp: Date(),
            showRecoveryActions: true,
            recoveryActions: [
                RecoveryActionButton(
                    title: "Continue with System Clicks",
                    action: .switchToSystemWide
                ),
                RecoveryActionButton(
                    title: "Stop Automation",
                    action: .stopAutomation
                )
            ]
        )
        
        currentErrorNotification = notification
        
        return RecoveryAction(
            strategy: .fallbackToSystemWide,
            shouldRetry: true,
            maxRetries: 1,
            retryDelay: 1.0,
            userNotification: notification
        )
    }
    
    private func createPerformanceRecoveryAction(for analysis: ErrorAnalysis) async -> RecoveryAction {
        let notification = ErrorNotification(
            id: UUID(),
            title: "Performance Issue Detected",
            message: "ClickIt detected timing constraints were violated. Adjusting performance settings to improve reliability.",
            severity: .warning,
            timestamp: Date(),
            showRecoveryActions: false
        )
        
        currentErrorNotification = notification
        
        return RecoveryAction(
            strategy: .adjustPerformanceSettings,
            shouldRetry: true,
            maxRetries: 2,
            retryDelay: 1.0,
            userNotification: notification
        )
    }
    
    private func createSystemResourceRecoveryAction(for analysis: ErrorAnalysis) async -> RecoveryAction {
        // Attempt to clean up resources
        await performResourceCleanup()
        
        let notification = ErrorNotification(
            id: UUID(),
            title: "System Resource Issue",
            message: "ClickIt detected high system resource usage. Performing cleanup and adjusting operation parameters.",
            severity: .warning,
            timestamp: Date(),
            showRecoveryActions: false
        )
        
        currentErrorNotification = notification
        
        return RecoveryAction(
            strategy: .resourceCleanup,
            shouldRetry: true,
            maxRetries: 2,
            retryDelay: 2.0,
            userNotification: notification
        )
    }
    
    private func createConfigurationErrorAction(for analysis: ErrorAnalysis) -> RecoveryAction {
        let notification = ErrorNotification(
            id: UUID(),
            title: "Configuration Error",
            message: "The click location or configuration is invalid. Please check your settings and try again.",
            severity: .error,
            timestamp: Date(),
            showRecoveryActions: true,
            recoveryActions: [
                RecoveryActionButton(
                    title: "Check Configuration",
                    action: .openSettings
                ),
                RecoveryActionButton(
                    title: "Stop Automation",
                    action: .stopAutomation
                )
            ]
        )
        
        currentErrorNotification = notification
        
        return RecoveryAction(
            strategy: .gracefulDegradation,
            shouldRetry: false,
            maxRetries: 0,
            retryDelay: 0,
            userNotification: notification
        )
    }
    
    private func createGracefulDegradationAction(for analysis: ErrorAnalysis) -> RecoveryAction {
        let notification = ErrorNotification(
            id: UUID(),
            title: "Maximum Recovery Attempts Reached",
            message: "ClickIt was unable to recover from the error after multiple attempts. Automation has been stopped for safety.",
            severity: .error,
            timestamp: Date(),
            showRecoveryActions: true,
            recoveryActions: [
                RecoveryActionButton(
                    title: "Review Settings",
                    action: .openSettings
                ),
                RecoveryActionButton(
                    title: "Check System Settings",
                    action: .openSystemSettings(.accessibility)
                )
            ]
        )
        
        currentErrorNotification = notification
        
        return RecoveryAction(
            strategy: .gracefulDegradation,
            shouldRetry: false,
            maxRetries: 0,
            retryDelay: 0,
            userNotification: notification
        )
    }
    
    // MARK: - Resource Management
    
    private func performResourceCleanup() async {
        // Force garbage collection
        // Note: In production code, you might want to be more specific about cleanup
        
        // Clear any cached data
        recoveryHistory = recoveryHistory.suffix(10) // Keep only recent history
        
        // Yield control to allow system to perform cleanup
        await Task.yield()
        
        // Small delay to allow system recovery
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
    
    // MARK: - Statistics and Monitoring
    
    /// Records a recovery attempt result
    func recordRecoveryAttempt(success: Bool, for context: ErrorContext) async {
        let attempt = RecoveryAttempt(
            errorType: detectErrorType(from: context.originalError),
            success: success,
            timestamp: Date(),
            attemptNumber: context.attemptCount + 1
        )
        
        recoveryHistory.append(attempt)
        updateRecoveryStatistics()
    }
    
    /// Gets current recovery statistics
    func getRecoveryStatistics() -> RecoveryStatistics {
        return recoveryStatistics
    }
    
    private func updateRecoveryStatistics() {
        let totalAttempts = recoveryHistory.count
        let successfulAttempts = recoveryHistory.filter { $0.success }.count
        
        recoveryStatistics = RecoveryStatistics(
            totalRecoveryAttempts: totalAttempts,
            successfulRecoveries: successfulAttempts,
            failedRecoveries: totalAttempts - successfulAttempts,
            successRate: totalAttempts > 0 ? Double(successfulAttempts) / Double(totalAttempts) : 0.0,
            lastRecoveryAttempt: recoveryHistory.last?.timestamp,
            averageRecoveryTime: calculateAverageRecoveryTime()
        )
    }
    
    private func calculateAverageRecoveryTime() -> TimeInterval {
        // This would be calculated based on actual recovery timing in a real implementation
        return 2.0 // Placeholder
    }
    
    // MARK: - Notification Management
    
    /// Clears the current error notification
    func clearErrorNotification() {
        currentErrorNotification = nil
    }
    
    /// Dismisses error notification with specified ID
    func dismissNotification(withId id: UUID) {
        if currentErrorNotification?.id == id {
            currentErrorNotification = nil
        }
    }
}

// MARK: - Protocol Definitions

protocol PermissionManagerProtocol {
    func checkAccessibilityPermission() -> Bool
    func checkScreenRecordingPermission() -> Bool
    func updatePermissionStatus() async
    func requestAccessibilityPermission() async -> Bool
    func requestScreenRecordingPermission() async -> Bool
}

extension PermissionManager: PermissionManagerProtocol {}

protocol SystemHealthMonitorProtocol {
    func checkMemoryPressure() -> Bool
    func checkCPUPressure() -> Bool
    func checkDiskSpace() -> Bool
    func getSystemResourceStatus() -> SystemResourceStatus
}