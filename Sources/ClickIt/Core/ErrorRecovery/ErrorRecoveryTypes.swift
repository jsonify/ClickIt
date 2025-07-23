import Foundation
import CoreGraphics

// MARK: - Error Analysis Types

/// Types of errors that can occur in the system
enum ErrorType {
    case permissionIssue
    case clickFailure
    case targetProcessIssue
    case performanceIssue
    case configurationError
    case systemResource
}

/// Context information for an error occurrence
struct ErrorContext {
    let originalError: ClickError
    let attemptCount: Int
    let configuration: ClickConfiguration
    let timestamp: Date
    
    init(originalError: ClickError, attemptCount: Int, configuration: ClickConfiguration) {
        self.originalError = originalError
        self.attemptCount = attemptCount
        self.configuration = configuration
        self.timestamp = Date()
    }
}

/// Comprehensive analysis of an error situation
struct ErrorAnalysis {
    let errorType: ErrorType
    let originalError: ClickError
    let systemResourceIssues: Bool
    let permissionStatus: PermissionStatus
    let context: ErrorContext
    let timestamp: Date
}

/// Current permission status for the application
struct PermissionStatus {
    let accessibility: Bool
    let screenRecording: Bool
    
    var allGranted: Bool {
        return accessibility && screenRecording
    }
}

// MARK: - Recovery Strategy Types

/// Available recovery strategies
enum RecoveryStrategy {
    case automaticRetry
    case recheckPermissions
    case resourceCleanup
    case fallbackToSystemWide
    case adjustPerformanceSettings
    case gracefulDegradation
}

/// Action plan for recovering from an error
struct RecoveryAction {
    let strategy: RecoveryStrategy
    let shouldRetry: Bool
    let maxRetries: Int
    let retryDelay: TimeInterval
    let userNotification: ErrorNotification?
    let permissionStatus: PermissionStatus?
    
    init(
        strategy: RecoveryStrategy,
        shouldRetry: Bool,
        maxRetries: Int,
        retryDelay: TimeInterval,
        userNotification: ErrorNotification? = nil,
        permissionStatus: PermissionStatus? = nil
    ) {
        self.strategy = strategy
        self.shouldRetry = shouldRetry
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.userNotification = userNotification
        self.permissionStatus = permissionStatus
    }
}

// MARK: - Notification Types

/// Severity levels for error notifications
enum NotificationSeverity {
    case info
    case warning
    case error
    
    var systemIcon: String {
        switch self {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .info:
            return "blue"
        case .warning:
            return "orange"
        case .error:
            return "red"
        }
    }
}

/// User-facing error notification
struct ErrorNotification: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let severity: NotificationSeverity
    let timestamp: Date
    let showRecoveryActions: Bool
    let recoveryActions: [RecoveryActionButton]
    
    init(
        id: UUID,
        title: String,
        message: String,
        severity: NotificationSeverity,
        timestamp: Date,
        showRecoveryActions: Bool,
        recoveryActions: [RecoveryActionButton] = []
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
        self.showRecoveryActions = showRecoveryActions
        self.recoveryActions = recoveryActions
    }
}

/// Action buttons for error notifications
struct RecoveryActionButton {
    let title: String
    let action: RecoveryButtonAction
}

/// Actions that can be triggered from recovery buttons
enum RecoveryButtonAction {
    case retry
    case openSystemSettings(PermissionType)
    case openSettings
    case stopAutomation
    case switchToSystemWide
}

// MARK: - Statistics Types

/// Statistics about recovery operations
struct RecoveryStatistics {
    let totalRecoveryAttempts: Int
    let successfulRecoveries: Int
    let failedRecoveries: Int
    let successRate: Double
    let lastRecoveryAttempt: Date?
    let averageRecoveryTime: TimeInterval
    
    init(
        totalRecoveryAttempts: Int = 0,
        successfulRecoveries: Int = 0,
        failedRecoveries: Int = 0,
        successRate: Double = 0.0,
        lastRecoveryAttempt: Date? = nil,
        averageRecoveryTime: TimeInterval = 0.0
    ) {
        self.totalRecoveryAttempts = totalRecoveryAttempts
        self.successfulRecoveries = successfulRecoveries
        self.failedRecoveries = failedRecoveries
        self.successRate = successRate
        self.lastRecoveryAttempt = lastRecoveryAttempt
        self.averageRecoveryTime = averageRecoveryTime
    }
}

/// Record of a single recovery attempt
struct RecoveryAttempt {
    let errorType: ErrorType
    let success: Bool
    let timestamp: Date
    let attemptNumber: Int
}

// MARK: - System Health Types

/// Current system resource status
struct SystemResourceStatus {
    let memoryPressure: Bool
    let cpuPressure: Bool
    let lowDiskSpace: Bool
    let timestamp: Date
    
    var hasIssues: Bool {
        return memoryPressure || cpuPressure || lowDiskSpace
    }
}

/// Thresholds for system resource monitoring
struct SystemResourceThresholds {
    static let memoryPressureThreshold: Double = 0.8 // 80% memory usage
    static let cpuPressureThreshold: Double = 0.9 // 90% CPU usage
    static let diskSpaceThreshold: Double = 0.1 // 10% free space minimum
}

// MARK: - Error Recovery Configuration

/// Configuration options for error recovery behavior
struct ErrorRecoveryConfiguration {
    let maxRetryAttempts: Int
    let retryDelayBase: TimeInterval
    let retryDelayMultiplier: Double
    let enableAutomaticRecovery: Bool
    let enableUserNotifications: Bool
    let enableStatisticsCollection: Bool
    
    static let `default` = ErrorRecoveryConfiguration(
        maxRetryAttempts: 3,
        retryDelayBase: 0.5,
        retryDelayMultiplier: 2.0,
        enableAutomaticRecovery: true,
        enableUserNotifications: true,
        enableStatisticsCollection: true
    )
}

// MARK: - Extensions

extension ErrorType: CustomStringConvertible {
    var description: String {
        switch self {
        case .permissionIssue:
            return "Permission Issue"
        case .clickFailure:
            return "Click Failure"
        case .targetProcessIssue:
            return "Target Process Issue"
        case .performanceIssue:
            return "Performance Issue"
        case .configurationError:
            return "Configuration Error"
        case .systemResource:
            return "System Resource Issue"
        }
    }
}

extension RecoveryStrategy: CustomStringConvertible {
    var description: String {
        switch self {
        case .automaticRetry:
            return "Automatic Retry"
        case .recheckPermissions:
            return "Recheck Permissions"
        case .resourceCleanup:
            return "Resource Cleanup"
        case .fallbackToSystemWide:
            return "Fallback to System-wide"
        case .adjustPerformanceSettings:
            return "Adjust Performance Settings"
        case .gracefulDegradation:
            return "Graceful Degradation"
        }
    }
}