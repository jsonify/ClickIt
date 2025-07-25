//
//  TimerAutomationEngine.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Testing Protocols

@MainActor
protocol ClickCoordinatorProtocol {
    func performSingleClick(configuration: ClickConfiguration) async -> ClickResult
    func emergencyStopAutomation()
}

@MainActor
protocol PerformanceMonitorProtocol {
    var isMonitoring: Bool { get }
    func startMonitoring()
    func getPerformanceReport() -> PerformanceReport
}

protocol ErrorRecoveryManagerProtocol {
    func attemptRecovery(for context: ErrorContext) async -> RecoveryAction
}

// Make existing classes conform to protocols
extension ClickCoordinator: ClickCoordinatorProtocol {}
extension PerformanceMonitor: PerformanceMonitorProtocol {}
extension ErrorRecoveryManager: ErrorRecoveryManagerProtocol {}

/// Enhanced timer automation engine for robust automation loops with precise timing control
@MainActor
class TimerAutomationEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current automation state
    @Published var automationState: AutomationState = .idle
    
    /// Current automation session data
    @Published var currentSession: AutomationSession?
    
    /// Real-time automation status
    @Published var automationStatus: AutomationStatus = AutomationStatus()
    
    // MARK: - Private Properties
    
    /// High-precision timer for sub-10ms accuracy
    private var highPrecisionTimer: HighPrecisionTimer?
    
    /// Click coordinator for execution
    private let clickCoordinator: ClickCoordinatorProtocol
    
    /// Error recovery manager for fault tolerance
    private let errorRecoveryManager: ErrorRecoveryManagerProtocol
    
    /// Performance monitor for resource tracking
    private let performanceMonitor: PerformanceMonitorProtocol
    
    /// Current automation configuration
    private var automationConfiguration: AutomationConfiguration?
    
    /// Session statistics tracking
    private var sessionStatistics: SessionStatistics?
    
    /// Timer for regular status updates (10Hz for UI responsiveness)
    private var statusUpdateTimer: Timer?
    
    /// Queue for automation operations
    private let automationQueue = DispatchQueue(
        label: "com.clickit.timer.automation",
        qos: .userInteractive
    )
    
    // MARK: - Initialization
    
    init(
        clickCoordinator: ClickCoordinatorProtocol? = nil,
        errorRecoveryManager: ErrorRecoveryManagerProtocol? = nil,
        performanceMonitor: PerformanceMonitorProtocol? = nil
    ) {
        self.clickCoordinator = clickCoordinator ?? ClickCoordinator.shared
        self.errorRecoveryManager = errorRecoveryManager ?? ErrorRecoveryManager()
        self.performanceMonitor = performanceMonitor ?? PerformanceMonitor.shared
    }
    
    deinit {
        // Synchronous cleanup for deinit
        highPrecisionTimer?.stopTimer()
        highPrecisionTimer = nil
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    // MARK: - Core Automation Control Methods
    
    /// Starts automation with the specified configuration
    /// - Parameter configuration: Automation configuration parameters
    func startAutomation(with configuration: AutomationConfiguration) {
        print("🚀 [TimerAutomationEngine] startAutomation() called - MainActor: \(Thread.isMainThread)")
        
        guard automationState == .idle else {
            print("❌ [TimerAutomationEngine] Cannot start automation - current state: \(automationState)")
            return
        }
        
        print("✅ [TimerAutomationEngine] Starting automation with configuration: \(configuration.location)")
        
        // Store configuration and create session
        automationConfiguration = configuration
        currentSession = AutomationSession(
            startTime: Date(),
            configuration: configuration
        )
        
        // Initialize session statistics
        sessionStatistics = SessionStatistics(
            duration: 0,
            totalClicks: 0,
            successfulClicks: 0,
            failedClicks: 0,
            successRate: 0,
            averageClickTime: 0,
            clicksPerSecond: 0,
            isActive: true
        )
        
        // Transition to running state
        automationState = .running
        
        // Start performance monitoring if not already active
        if !performanceMonitor.isMonitoring {
            performanceMonitor.startMonitoring()
        }
        
        // Start automation loop with high-precision timing
        startAutomationLoop(configuration: configuration)
        
        // Start status update timer for real-time UI updates
        startStatusUpdateTimer()
        
        print("[TimerAutomationEngine] Automation started successfully")
    }
    
    /// Pauses the current automation session
    func pauseAutomation() {
        guard automationState == .running else {
            print("[TimerAutomationEngine] Cannot pause automation - current state: \(automationState)")
            return
        }
        
        print("[TimerAutomationEngine] Pausing automation")
        
        // Transition to paused state
        automationState = .paused
        
        // Pause the high-precision timer (will resume on resume)
        highPrecisionTimer?.pauseTimer()
        
        // Update session with pause timestamp
        currentSession?.pauseSession()
        
        print("[TimerAutomationEngine] Automation paused successfully")
    }
    
    /// Resumes a paused automation session
    func resumeAutomation() {
        guard automationState == .paused else {
            print("[TimerAutomationEngine] Cannot resume automation - current state: \(automationState)")
            return
        }
        
        print("[TimerAutomationEngine] Resuming automation")
        
        // Transition back to running state
        automationState = .running
        
        // Resume the high-precision timer
        highPrecisionTimer?.resumeTimer()
        
        // Update session with resume timestamp
        currentSession?.resumeSession()
        
        print("[TimerAutomationEngine] Automation resumed successfully")
    }
    
    /// Stops the current automation session
    func stopAutomation() {
        guard automationState != .idle else {
            print("[TimerAutomationEngine] Automation already stopped")
            return
        }
        
        print("[TimerAutomationEngine] Stopping automation")
        
        // Stop high-precision timer
        highPrecisionTimer?.stopTimer()
        highPrecisionTimer = nil
        
        // Stop status update timer
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
        
        // Finalize current session
        if var session = currentSession {
            session.endSession()
            currentSession = session
        }
        
        // Transition to idle state
        automationState = .idle
        
        // Clear configuration
        automationConfiguration = nil
        
        print("[TimerAutomationEngine] Automation stopped successfully")
    }
    
    /// Emergency stop with immediate termination (sub-50ms response guarantee)
    func emergencyStopAutomation() {
        print("[TimerAutomationEngine] EMERGENCY STOP - immediate termination")
        
        // Critical: Set state immediately to prevent new operations
        automationState = .error
        
        // Immediate resource cleanup without waiting
        highPrecisionTimer?.stopTimer()
        highPrecisionTimer = nil
        
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
        
        // Emergency stop click coordinator
        clickCoordinator.emergencyStopAutomation()
        
        // Mark session as emergency stopped
        if var session = currentSession {
            session.emergencyStop()
            currentSession = session
        }
        
        // Transition to idle after emergency cleanup
        automationState = .idle
        automationConfiguration = nil
        
        print("[TimerAutomationEngine] EMERGENCY STOP completed")
    }
    
    // MARK: - State Management and Monitoring
    
    /// Gets the current automation status with real-time data
    /// - Returns: Current automation status
    func getCurrentStatus() -> AutomationStatus {
        return automationStatus
    }
    
    /// Gets current session statistics
    /// - Returns: Session statistics or nil if no active session
    func getSessionStatistics() -> SessionStatistics? {
        return sessionStatistics
    }
    
    /// Gets timing accuracy statistics from the precision timer
    /// - Returns: Timing accuracy statistics or nil if no active timer
    func getTimingAccuracy() -> TimingAccuracyStats? {
        return highPrecisionTimer?.getTimingAccuracy()
    }
    
    // MARK: - Private Methods
    
    /// Starts the automation loop with high-precision timing
    /// - Parameter configuration: Automation configuration
    private func startAutomationLoop(configuration: AutomationConfiguration) {
        guard configuration.clickInterval > 0 else {
            print("[TimerAutomationEngine] Invalid click interval: \(configuration.clickInterval)")
            automationState = .error
            return
        }
        
        // Create high-precision timer for automation
        highPrecisionTimer = HighPrecisionTimerFactory.createClickTimer(interval: configuration.clickInterval)
        
        // Start repeating timer with automation callback - FIXED CONCURRENCY ISSUE
        highPrecisionTimer?.startRepeatingTimer(interval: configuration.clickInterval) { [weak self] in
            // Use DispatchQueue.main.async to safely get to MainActor context
            DispatchQueue.main.async {
                print("⏰ [TimerAutomationEngine] Timer callback executing - MainActor: \(Thread.isMainThread)")
                Task {
                    await self?.executeAutomationStep()
                }
            }
        }
        
        print("[TimerAutomationEngine] Started automation loop with \(configuration.clickInterval * 1000)ms interval")
    }
    
    /// Executes a single automation step
    private func executeAutomationStep() async {
        print("🔄 [TimerAutomationEngine] executeAutomationStep() - MainActor: \(Thread.isMainThread)")
        
        // Quick state checks for efficiency
        guard automationState == .running,
              let config = automationConfiguration else {
            print("⚠️ [TimerAutomationEngine] Skipping step - state: \(automationState), config: \(automationConfiguration != nil)")
            return
        }
        
        print("✅ [TimerAutomationEngine] Executing automation step at: \(config.location)")
        
        // Check session limits before execution
        if shouldStopDueToLimits(config: config) {
            stopAutomation()
            return
        }
        
        // Execute the automation step through click coordinator
        let result = await performAutomationClick(config: config)
        
        // Update session statistics
        updateSessionStatistics(with: result)
        
        // Handle errors if configured to stop on error
        if !result.success && config.stopOnError {
            print("[TimerAutomationEngine] Stopping automation due to click failure")
            automationState = .error
            stopAutomation()
        }
    }
    
    /// Performs a single automation click through the click coordinator
    /// - Parameter config: Automation configuration
    /// - Returns: Click result
    private func performAutomationClick(config: AutomationConfiguration) async -> ClickResult {
        print("🖱️ [TimerAutomationEngine] performAutomationClick() - About to call clickCoordinator")
        print("   Location: \(config.location), Type: \(config.clickType)")
        
        do {
            // Delegate to click coordinator for actual execution
            let result = await clickCoordinator.performSingleClick(
                configuration: ClickConfiguration(
                    type: config.clickType,
                    location: config.location,
                    targetPID: nil
                )
            )
            
            print("✅ [TimerAutomationEngine] Click completed - Success: \(result.success)")
            return result
        } catch {
            print("❌ [TimerAutomationEngine] Click failed with error: \(error)")
            return ClickResult(
                success: false,
                actualLocation: config.location,
                timestamp: CFAbsoluteTimeGetCurrent(),
                error: .eventPostingFailed
            )
        }
    }
    
    /// Checks if automation should stop due to configured limits
    /// - Parameter config: Automation configuration
    /// - Returns: True if automation should stop
    private func shouldStopDueToLimits(config: AutomationConfiguration) -> Bool {
        guard let session = currentSession else { return false }
        
        // Check click count limit
        if let maxClicks = config.maxClicks,
           session.totalClicks >= maxClicks {
            print("[TimerAutomationEngine] Reached click limit: \(maxClicks)")
            return true
        }
        
        // Check duration limit
        if let maxDuration = config.maxDuration,
           session.duration >= maxDuration {
            print("[TimerAutomationEngine] Reached duration limit: \(maxDuration)s")
            return true
        }
        
        return false
    }
    
    /// Updates session statistics with the latest click result
    /// - Parameter result: Click result to incorporate
    private func updateSessionStatistics(with result: ClickResult) {
        guard var session = currentSession,
              var stats = sessionStatistics else { return }
        
        // Update session data
        session.recordClick(result: result)
        currentSession = session
        
        // Update statistics
        stats = SessionStatistics(
            duration: session.duration,
            totalClicks: session.totalClicks,
            successfulClicks: session.successfulClicks,
            failedClicks: session.failedClicks,
            successRate: session.successRate,
            averageClickTime: session.averageClickTime,
            clicksPerSecond: session.clicksPerSecond,
            isActive: true
        )
        
        sessionStatistics = stats
    }
    
    /// Starts the status update timer for real-time UI updates
    private func startStatusUpdateTimer() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateAutomationStatus()
            }
        }
    }
    
    /// Updates the automation status for UI binding
    private func updateAutomationStatus() {
        let performanceMetrics = performanceMonitor.getPerformanceReport()
        let timingAccuracy = getTimingAccuracy()
        
        automationStatus = AutomationStatus(
            state: automationState,
            session: currentSession,
            statistics: sessionStatistics,
            performanceMetrics: performanceMetrics,
            timingAccuracy: timingAccuracy,
            lastUpdate: Date()
        )
    }
}

// MARK: - Supporting Types

/// Automation engine states
enum AutomationState: String, CaseIterable {
    case idle = "idle"
    case running = "running"
    case paused = "paused"
    case stopped = "stopped"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .running: return "Running"
        case .paused: return "Paused"
        case .stopped: return "Stopped"
        case .error: return "Error"
        }
    }
    
    var isActive: Bool {
        return self == .running || self == .paused
    }
}

/// Automation session data with comprehensive tracking
struct AutomationSession {
    /// Session start timestamp
    let startTime: Date
    
    /// Automation configuration
    let configuration: AutomationConfiguration
    
    /// Session end timestamp (nil if active)
    private(set) var endTime: Date?
    
    /// Session pause/resume tracking
    private(set) var pauseHistory: [PauseInterval] = []
    
    /// Click statistics
    private(set) var totalClicks: Int = 0
    private(set) var successfulClicks: Int = 0
    private(set) var clickTimes: [TimeInterval] = []
    
    /// Emergency stop flag
    private(set) var wasEmergencyStopped: Bool = false
    
    // MARK: - Computed Properties
    
    /// Total session duration in seconds
    var duration: TimeInterval {
        let endTimestamp = endTime ?? Date()
        let totalDuration = endTimestamp.timeIntervalSince(startTime)
        
        // Subtract pause durations
        let pauseDuration = pauseHistory.reduce(0) { $0 + $1.duration }
        return max(0, totalDuration - pauseDuration)
    }
    
    /// Failed clicks count
    var failedClicks: Int {
        return max(0, totalClicks - successfulClicks)
    }
    
    /// Success rate as percentage
    var successRate: Double {
        guard totalClicks > 0 else { return 0 }
        return Double(successfulClicks) / Double(totalClicks)
    }
    
    /// Average click time in seconds
    var averageClickTime: TimeInterval {
        guard !clickTimes.isEmpty else { return 0 }
        return clickTimes.reduce(0, +) / Double(clickTimes.count)
    }
    
    /// Clicks per second rate
    var clicksPerSecond: Double {
        guard duration > 0 else { return 0 }
        return Double(totalClicks) / duration
    }
    
    /// Whether session is currently active
    var isActive: Bool {
        return endTime == nil && !wasEmergencyStopped
    }
    
    // MARK: - Session Management
    
    /// Records a click result in the session
    /// - Parameter result: Click result to record
    mutating func recordClick(result: ClickResult) {
        totalClicks += 1
        
        if result.success {
            successfulClicks += 1
        }
        
        // Record click timing if available
        if let clickTime = result.executionTime {
            clickTimes.append(clickTime)
            
            // Limit history to prevent memory growth
            if clickTimes.count > 1000 {
                clickTimes.removeFirst(clickTimes.count - 1000)
            }
        }
    }
    
    /// Pauses the session
    mutating func pauseSession() {
        // Add new pause interval
        pauseHistory.append(PauseInterval(startTime: Date()))
    }
    
    /// Resumes the session
    mutating func resumeSession() {
        // Complete the most recent pause interval
        if var lastPause = pauseHistory.last, lastPause.endTime == nil {
            lastPause.endTime = Date()
            pauseHistory[pauseHistory.count - 1] = lastPause
        }
    }
    
    /// Ends the session normally
    mutating func endSession() {
        endTime = Date()
        
        // Complete any ongoing pause interval
        if var lastPause = pauseHistory.last, lastPause.endTime == nil {
            lastPause.endTime = Date()
            pauseHistory[pauseHistory.count - 1] = lastPause
        }
    }
    
    /// Marks session as emergency stopped
    mutating func emergencyStop() {
        wasEmergencyStopped = true
        endTime = Date()
    }
}

/// Pause interval tracking
struct PauseInterval {
    let startTime: Date
    var endTime: Date?
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

/// Real-time automation status for UI binding
struct AutomationStatus {
    let state: AutomationState
    let session: AutomationSession?
    let statistics: SessionStatistics?
    let performanceMetrics: PerformanceReport?
    let timingAccuracy: TimingAccuracyStats?
    let lastUpdate: Date
    
    init(
        state: AutomationState = .idle,
        session: AutomationSession? = nil,
        statistics: SessionStatistics? = nil,
        performanceMetrics: PerformanceReport? = nil,
        timingAccuracy: TimingAccuracyStats? = nil,
        lastUpdate: Date = Date()
    ) {
        self.state = state
        self.session = session
        self.statistics = statistics
        self.performanceMetrics = performanceMetrics
        self.timingAccuracy = timingAccuracy
        self.lastUpdate = lastUpdate
    }
    
    /// Whether automation is currently active
    var isActive: Bool {
        return state.isActive
    }
    
    /// Whether timing is within acceptable tolerance
    var isTimingAccurate: Bool {
        return timingAccuracy?.isWithinTolerance ?? false
    }
    
    /// Overall automation health status
    var healthStatus: AutomationHealthStatus {
        if !isActive {
  

           return .idle
        }
        
        if state == .error {
            return .error
        }
        
        // Check timing accuracy
        if let timing = timingAccuracy, !timing.isWithinTolerance {
            return .warning
        }
        
        // Check success rate
        if let stats = statistics, stats.successRate < 0.95 {
            return .warning
        }
        
        return .healthy
    }
}

/// Automation health status for monitoring
enum AutomationHealthStatus {
    case idle
    case healthy
    case warning
    case error
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .healthy: return "Healthy"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .healthy: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Extensions

extension ClickResult {
    /// Estimated execution time (placeholder for future implementation)
    var executionTime: TimeInterval? {
        // This would be calculated based on timestamp differences
        // For now, return nil as this data isn't currently tracked
        return nil
    }
}