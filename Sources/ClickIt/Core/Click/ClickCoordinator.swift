import Foundation
import CoreGraphics
import Combine
import AppKit

/// High-level coordinator for click operations and automation
@MainActor
class ClickCoordinator: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance of the click coordinator
    static let shared = ClickCoordinator()
    
    /// Current click session state
    @Published var isActive: Bool = false
    
    /// Pause state for automation
    @Published var isPaused: Bool = false
    
    /// Click statistics
    @Published var clickCount: Int = 0
    @Published var successRate: Double = 1.0
    @Published var averageClickTime: TimeInterval = 0
    
    /// Elapsed time manager for real-time tracking
    private let timeManager = ElapsedTimeManager.shared
    
    /// Error recovery manager for handling failures
    private let errorRecoveryManager = ErrorRecoveryManager()
    
    /// Elapsed time since automation started (legacy compatibility)
    var elapsedTime: TimeInterval {
        return timeManager.currentSessionTime
    }
    
    /// Current automation configuration
    @Published var automationConfig: AutomationConfiguration?
    
    /// Active automation task
    private var automationTask: Task<Void, Never>?
    
    /// High-precision timer for optimized automation timing
    private var automationTimer: HighPrecisionTimer?
    
    /// CPS randomizer for human-like timing patterns
    private var cpsRandomizer: CPSRandomizer?
    
    /// Performance monitor for resource optimization
    private let performanceMonitor = PerformanceMonitor.shared
    
    /// Statistics tracking
    private var sessionStartTime: TimeInterval = 0
    private var totalClicks: Int = 0
    private var successfulClicks: Int = 0
    private var totalClickTime: TimeInterval = 0
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Starts a click automation session
    /// - Parameter configuration: Automation configuration
    func startAutomation(with configuration: AutomationConfiguration) {
        guard !isActive else { return }
        
        automationConfig = configuration
        isActive = true
        resetStatistics()
        
        // Start real-time elapsed time tracking
        timeManager.startTracking()
        
        print("ClickCoordinator: Starting automation at \(configuration.location)")
        
        // Start performance monitoring if not already running
        if !performanceMonitor.isMonitoring {
            performanceMonitor.startMonitoring()
        }
        
        // SIMPLE WORKING APPROACH: Use basic Task with Task.sleep()
        automationTask = Task {
            await runAutomationLoop(configuration: configuration)
        }
    }
    
    /// Stops the current automation session
    func stopAutomation() {
        print("ClickCoordinator: stopAutomation() called")
        
        // Prevent multiple simultaneous stops
        guard isActive else {
            print("ClickCoordinator: automation already stopped")
            return
        }
        
        isActive = false
        isPaused = false  // Clear pause state when stopping
        
        // Stop automation timer
        automationTimer?.stopTimer()
        automationTimer = nil
        
        // Cancel any remaining automation task
        automationTask?.cancel()
        automationTask = nil
        
        // Stop real-time elapsed time tracking
        timeManager.stopTracking()
        
        automationConfig = nil
        print("ClickCoordinator: stopAutomation() completed")
    }
    
    /// EMERGENCY PRIORITY: Immediate automation termination for <50ms response guarantee
    func emergencyStopAutomation() {
        print("ClickCoordinator: EMERGENCY STOP - immediate termination")
        
        // Critical: Set inactive state first to prevent any new operations
        isActive = false
        isPaused = false
        
        // Immediate timer and task cancellation without waiting
        automationTimer?.stopTimer()
        automationTimer = nil
        automationTask?.cancel()
        automationTask = nil
        
        // Priority cleanup - all operations must be synchronous for speed
        timeManager.stopTracking()
        automationConfig = nil
        
        print("ClickCoordinator: EMERGENCY STOP completed")
    }
    
    /// Pauses the current automation session
    func pauseAutomation() {
        guard isActive && !isPaused else { 
            print("ClickCoordinator: pauseAutomation() - not active or already paused")
            return 
        }
        
        print("ClickCoordinator: pauseAutomation() called")
        isPaused = true
        
        // Pause elapsed time tracking
        timeManager.pauseTracking()
        
        print("ClickCoordinator: automation paused")
    }
    
    /// Resumes the current automation session
    func resumeAutomation() {
        guard isActive && isPaused else { 
            print("ClickCoordinator: resumeAutomation() - not active or not paused")
            return 
        }
        
        print("ClickCoordinator: resumeAutomation() called")
        isPaused = false
        
        // Resume elapsed time tracking
        timeManager.resumeTracking()
        
        print("ClickCoordinator: automation resumed")
    }
    
    /// Performs a single click with the given configuration
    /// - Parameter configuration: Click configuration
    /// - Returns: Result of the click operation
    func performSingleClick(configuration: ClickConfiguration) async -> ClickResult {
        print("🎯 [ClickCoordinator] performSingleClick() - MainActor: \(Thread.isMainThread)")
        print("   Location: \(configuration.location), Type: \(configuration.type)")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            print("📞 [ClickCoordinator] Calling ClickEngine.performClick()...")
            let result = await ClickEngine.shared.performClick(configuration: configuration)
            print("✅ [ClickCoordinator] ClickEngine returned - Success: \(result.success)")
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let clickTime = endTime - startTime
            
            print("📊 [ClickCoordinator] Updating statistics...")
            await updateStatistics(result: result, clickTime: clickTime)
            print("✅ [ClickCoordinator] Statistics updated successfully")
            
            return result
        } catch {
            print("❌ [ClickCoordinator] performSingleClick failed with error: \(error)")
            return ClickResult(
                success: false,
                actualLocation: configuration.location,
                timestamp: startTime,
                error: .eventPostingFailed
            )
        }
    }
    
    /// Performs a sequence of clicks with specified timing
    /// - Parameters:
    ///   - configurations: Array of click configurations
    ///   - interval: Interval between clicks
    /// - Returns: Array of click results
    func performClickSequence(configurations: [ClickConfiguration], interval: TimeInterval) async -> [ClickResult] {
        var results: [ClickResult] = []
        
        for (index, config) in configurations.enumerated() {
            let result = await performSingleClick(configuration: config)
            results.append(result)
            
            // Add delay between clicks (except for the last one)
            if index < configurations.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
        
        return results
    }
    
    /// Performs background clicks on a specific application
    /// - Parameters:
    ///   - bundleIdentifier: Target application bundle identifier
    ///   - location: Click location
    ///   - clickType: Type of click
    /// - Returns: Result of the click operation
    func performBackgroundClick(
        bundleIdentifier: String,
        at location: CGPoint,
        clickType: ClickType = .left
    ) async -> ClickResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await BackgroundClicker.shared.clickOnApplication(
            bundleIdentifier: bundleIdentifier,
            location: location,
            clickType: clickType
        )
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let clickTime = endTime - startTime
        
        await updateStatistics(result: result, clickTime: clickTime)
        
        return result
    }
    
    /// Tests click precision and performance
    /// - Parameters:
    ///   - location: Location to test
    ///   - iterations: Number of test iterations
    /// - Returns: Precision test results
    func testClickPrecision(at location: CGPoint, iterations: Int = 50) async -> PrecisionTestResult {
        await ClickPrecisionTester.shared.testClickPrecision(at: location, iterations: iterations)
    }
    
    /// Runs a comprehensive system validation
    /// - Returns: System validation results
    func validateSystem() -> SystemValidationResult {
        ClickPrecisionTester.shared.validateSystemRequirements()
    }
    
    /// Gets current session statistics
    /// - Returns: Current session statistics
    func getSessionStatistics() -> SessionStatistics {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let sessionDuration = sessionStartTime > 0 ? currentTime - sessionStartTime : 0
        
        return SessionStatistics(
            duration: sessionDuration,
            totalClicks: totalClicks,
            successfulClicks: successfulClicks,
            failedClicks: totalClicks - successfulClicks,
            successRate: totalClicks > 0 ? Double(successfulClicks) / Double(totalClicks) : 0,
            averageClickTime: totalClicks > 0 ? totalClickTime / Double(totalClicks) : 0,
            clicksPerSecond: sessionDuration > 0 ? Double(totalClicks) / sessionDuration : 0,
            isActive: isActive
        )
    }
    
    /// Gets current error recovery manager for UI access
    /// - Returns: Current error recovery manager
    var errorRecovery: ErrorRecoveryManager {
        return errorRecoveryManager
    }
    
    /// Gets recovery statistics for display
    /// - Returns: Current recovery statistics
    func getRecoveryStatistics() -> RecoveryStatistics {
        return errorRecoveryManager.getRecoveryStatistics()
    }
    
    /// Gets current performance metrics
    /// - Returns: Current performance report
    func getPerformanceMetrics() -> PerformanceReport {
        return performanceMonitor.getPerformanceReport()
    }
    
    /// Gets timing accuracy statistics from the automation timer
    /// - Returns: Timing accuracy statistics
    func getTimingAccuracy() -> TimingAccuracyStats? {
        return automationTimer?.getTimingAccuracy()
    }
    
    /// Optimizes performance based on current metrics
    func optimizePerformance() {
        performanceMonitor.optimizeMemoryUsage()
        
        // Reset timing statistics for fresh measurement
        automationTimer?.resetTimingStats()
        
        print("[ClickCoordinator] Performance optimization completed")
    }
    
    // MARK: - Private Methods - Simple Working Automation Loop
    
    /// Simple automation loop from working version (6b0b525)
    private func runAutomationLoop(configuration: AutomationConfiguration) async {
        while isActive && !Task.isCancelled {
            let result = await executeAutomationStep(configuration: configuration)
            
            if !result.success {
                // Handle failed click based on configuration
                if configuration.stopOnError {
                    await MainActor.run {
                        stopAutomation()
                    }
                    break
                }
            }
            
            // Apply click interval using simple Task.sleep - NO TIMER CALLBACKS!
            if configuration.clickInterval > 0 {
                try? await Task.sleep(nanoseconds: UInt64(configuration.clickInterval * 1_000_000_000))
            }
            
            // Check for maximum clicks limit
            if let maxClicks = configuration.maxClicks, totalClicks >= maxClicks {
                await MainActor.run {
                    stopAutomation()
                }
                break
            }
            
            // Check for maximum duration limit
            if let maxDuration = configuration.maxDuration {
                let elapsedTime = CFAbsoluteTimeGetCurrent() - sessionStartTime
                if elapsedTime >= maxDuration {
                    await MainActor.run {
                        stopAutomation()
                    }
                    break
                }
            }
        }
    }
    
    /// Simple automation step execution from working version
    private func executeAutomationStep(configuration: AutomationConfiguration) async -> ClickResult {
        print("ClickCoordinator: executeAutomationStep() - Simple working approach")
        
        // Use the working performSingleClick method
        let result = await performSingleClick(
            configuration: ClickConfiguration(
                type: configuration.clickType,
                location: configuration.location,
                targetPID: nil
            )
        )
        
        // Update visual feedback if enabled
        if configuration.showVisualFeedback {
            VisualFeedbackOverlay.shared.updateOverlay(at: configuration.location, isActive: true)
        }
        
        return result
    }
    
    // MARK: - Private Methods - Complex Methods (Unused)
    
    /// Starts optimized automation loop using HighPrecisionTimer for better CPU efficiency
    /// - Parameter configuration: Automation configuration
    private func startOptimizedAutomationLoop(configuration: AutomationConfiguration) {
        guard configuration.clickInterval > 0 else {
            print("ClickCoordinator: Invalid click interval: \(configuration.clickInterval)")
            return
        }
        
        // Initialize CPS randomizer with configuration
        cpsRandomizer = CPSRandomizer(configuration: configuration.cpsRandomizerConfig)
        
        // Start first automation step
        scheduleNextAutomationStep(configuration: configuration)
        
        print("ClickCoordinator: Started optimized automation loop with \(configuration.clickInterval * 1000)ms base interval, randomization: \(configuration.cpsRandomizerConfig.enabled)")
    }
    
    /// Schedules the next automation step with randomized timing
    /// - Parameter configuration: Automation configuration
    private func scheduleNextAutomationStep(configuration: AutomationConfiguration) {
        guard isActive else { return }
        
        // Calculate next interval with randomization
        let nextInterval = cpsRandomizer?.randomizeInterval(configuration.clickInterval) ?? configuration.clickInterval
        
        // Create new one-shot timer for next step (required for dynamic intervals)
        automationTimer = HighPrecisionTimer()
        automationTimer?.startOneShotTimer(delay: nextInterval) { [weak self] in
            Task { @MainActor in
                await self?.performOptimizedAutomationStep(configuration: configuration)
            }
        }
    }
    
    /// Performs a single optimized automation step with minimal overhead
    /// - Parameter configuration: Automation configuration
    private func performOptimizedAutomationStep(configuration: AutomationConfiguration) async {
        // Quick exit checks for maximum efficiency
        guard isActive else { return }
        
        // Skip execution if paused but keep timer running
        guard !isPaused else { return }
        
        // Check limits before execution for efficiency
        if let maxClicks = configuration.maxClicks, totalClicks >= maxClicks {
            stopAutomation()
            return
        }
        
        if let maxDuration = configuration.maxDuration {
            let elapsedTime = CFAbsoluteTimeGetCurrent() - sessionStartTime
            if elapsedTime >= maxDuration {
                stopAutomation()
                return
            }
        }
        
        // Execute click with minimal overhead
        let result = await executeAutomationStep(configuration: configuration)
        
        // Handle failed click with minimal processing
        if !result.success && configuration.stopOnError {
            stopAutomation()
            return
        }
        
        // Schedule next automation step with randomized timing
        scheduleNextAutomationStep(configuration: configuration)
    }
    
    
    /// Executes a click with integrated error recovery
    /// - Parameters:
    ///   - location: Location to click
    ///   - configuration: Automation configuration
    /// - Returns: Result of the click operation with recovery attempts
    private func executeClickWithRecovery(
        location: CGPoint,
        configuration: AutomationConfiguration
    ) async -> ClickResult {
        let clickConfig = ClickConfiguration(
            type: configuration.clickType,
            location: location,
            targetPID: nil
        )
        
        var attemptCount = 0
        let maxAttempts = 3
        
        while attemptCount < maxAttempts {
            let result: ClickResult
            
            // Perform the click
            if let targetApp = configuration.targetApplication {
                result = await performBackgroundClick(
                    bundleIdentifier: targetApp,
                    at: location,
                    clickType: configuration.clickType
                )
            } else {
                result = await performSingleClick(configuration: clickConfig)
            }
            
            // If successful, return immediately
            if result.success {
                return result
            }
            
            // Handle error with recovery system
            if let error = result.error {
                let context = ErrorContext(
                    originalError: error,
                    attemptCount: attemptCount,
                    configuration: clickConfig
                )
                
                let recoveryAction = await errorRecoveryManager.attemptRecovery(for: context)
                await errorRecoveryManager.recordRecoveryAttempt(success: false, for: context)
                
                // Check if we should retry
                if recoveryAction.shouldRetry && attemptCount < maxAttempts - 1 {
                    attemptCount += 1
                    
                    // Wait for recovery delay
                    if recoveryAction.retryDelay > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(recoveryAction.retryDelay * 1_000_000_000))
                    }
                    
                    // Apply recovery strategy adjustments
                    await applyRecoveryStrategy(recoveryAction.strategy, for: configuration)
                    
                    continue // Retry the operation
                } else {
                    // Max attempts reached or recovery says don't retry
                    print("ClickCoordinator: Recovery failed or max attempts reached for error: \(error)")
                    return result
                }
            }
            
            attemptCount += 1
        }
        
        // This should not be reached, but provide a fallback
        return ClickResult(
            success: false,
            actualLocation: location,
            timestamp: CFAbsoluteTimeGetCurrent(),
            error: .eventPostingFailed
        )
    }
    
    /// Applies recovery strategy adjustments to the automation configuration
    /// - Parameters:
    ///   - strategy: Recovery strategy to apply
    ///   - configuration: Current automation configuration
    private func applyRecoveryStrategy(
        _ strategy: RecoveryStrategy,
        for configuration: AutomationConfiguration
    ) async {
        switch strategy {
        case .resourceCleanup:
            // Give system time to clean up resources
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            
        case .adjustPerformanceSettings:
            // Could adjust timing or other performance-related settings
            // This is a placeholder for future performance adjustments
            break
            
        case .recheckPermissions:
            // Force permission status update
            await PermissionManager.shared.updatePermissionStatus()
            
        case .fallbackToSystemWide:
            // This would modify the configuration to use system-wide clicks
            // For now, we'll just log the intention
            print("ClickCoordinator: Falling back to system-wide clicks")
            
        case .automaticRetry, .gracefulDegradation:
            // These strategies are handled by the retry loop logic
            break
        }
    }
    
    /// Randomizes a location within specified variance
    /// - Parameters:
    ///   - base: Base location
    ///   - variance: Maximum variance in pixels
    /// - Returns: Randomized location
    private func randomizeLocation(base: CGPoint, variance: CGFloat) -> CGPoint {
        let xOffset = CGFloat.random(in: -variance...variance)
        let yOffset = CGFloat.random(in: -variance...variance)
        
        return CGPoint(
            x: base.x + xOffset,
            y: base.y + yOffset
        )
    }
    
    /// Updates session statistics
    /// - Parameters:
    ///   - result: Click result
    ///   - clickTime: Time taken for the click
    private func updateStatistics(result: ClickResult, clickTime: TimeInterval) async {
        await MainActor.run {
            totalClicks += 1
            totalClickTime += clickTime
            
            if result.success {
                successfulClicks += 1
            }
            
            clickCount = totalClicks
            successRate = Double(successfulClicks) / Double(totalClicks)
            averageClickTime = totalClickTime / Double(totalClicks)
        }
    }
    
    /// Resets session statistics
    private func resetStatistics() {
        sessionStartTime = CFAbsoluteTimeGetCurrent()
        totalClicks = 0
        successfulClicks = 0
        totalClickTime = 0
        clickCount = 0
        successRate = 1.0
        averageClickTime = 0
    }
    
    /// Converts AppKit coordinates to CoreGraphics coordinates for multi-monitor setups
    private func convertAppKitToCoreGraphicsMultiMonitor(_ appKitPosition: CGPoint) -> CGPoint {
        // Find which screen contains this point
        for screen in NSScreen.screens {
            if screen.frame.contains(appKitPosition) {
                // Convert using the specific screen's coordinate system
                let cgY = screen.frame.maxY - appKitPosition.y
                let cgPosition = CGPoint(x: appKitPosition.x, y: cgY)
                print("[Multi-Monitor Debug] AppKit \(appKitPosition) → CoreGraphics \(cgPosition) on screen \(screen.frame)")
                return cgPosition
            }
        }
        
        // Fallback to main screen if no screen contains the point
        let mainScreenHeight = NSScreen.main?.frame.height ?? 0
        let fallbackPosition = CGPoint(x: appKitPosition.x, y: mainScreenHeight - appKitPosition.y)
        print("[Multi-Monitor Debug] Fallback conversion: AppKit \(appKitPosition) → CoreGraphics \(fallbackPosition)")
        return fallbackPosition
    }
    
    /// Converts CoreGraphics coordinates back to AppKit coordinates for multi-monitor setups
    private func convertCoreGraphicsToAppKitMultiMonitor(_ cgPosition: CGPoint) -> CGPoint {
        // Find which screen this CoreGraphics position would map to
        // This is a reverse lookup - we need to find the screen that would contain the original AppKit position
        for screen in NSScreen.screens {
            // Check if this position could have come from this screen
            let potentialAppKitY = screen.frame.maxY - cgPosition.y
            let potentialAppKitPosition = CGPoint(x: cgPosition.x, y: potentialAppKitY)
            
            if screen.frame.contains(potentialAppKitPosition) {
                print("[Multi-Monitor Debug] CoreGraphics \(cgPosition) → AppKit \(potentialAppKitPosition) on screen \(screen.frame)")
                return potentialAppKitPosition
            }
        }
        
        // Fallback to main screen conversion
        let mainScreenHeight = NSScreen.main?.frame.height ?? 0
        let fallbackPosition = CGPoint(x: cgPosition.x, y: mainScreenHeight - cgPosition.y)
        print("[Multi-Monitor Debug] Fallback reverse conversion: CoreGraphics \(cgPosition) → AppKit \(fallbackPosition)")
        return fallbackPosition
    }
}

// MARK: - Supporting Types

/// Configuration for click automation
struct AutomationConfiguration {
    let location: CGPoint
    let clickType: ClickType
    let clickInterval: TimeInterval
    let targetApplication: String?
    let maxClicks: Int?
    let maxDuration: TimeInterval?
    let stopOnError: Bool
    let randomizeLocation: Bool
    let locationVariance: CGFloat
    let useDynamicMouseTracking: Bool
    let showVisualFeedback: Bool
    let cpsRandomizerConfig: CPSRandomizer.Configuration
    
    init(
        location: CGPoint,
        clickType: ClickType = .left,
        clickInterval: TimeInterval = 1.0,
        targetApplication: String? = nil,
        maxClicks: Int? = nil,
        maxDuration: TimeInterval? = nil,
        stopOnError: Bool = false,
        randomizeLocation: Bool = false,
        locationVariance: CGFloat = 0,
        useDynamicMouseTracking: Bool = false,
        showVisualFeedback: Bool = true,
        cpsRandomizerConfig: CPSRandomizer.Configuration = CPSRandomizer.Configuration()
    ) {
        self.location = location
        self.clickType = clickType
        self.clickInterval = clickInterval
        self.targetApplication = targetApplication
        self.maxClicks = maxClicks
        self.maxDuration = maxDuration
        self.stopOnError = stopOnError
        self.randomizeLocation = randomizeLocation
        self.locationVariance = locationVariance
        self.useDynamicMouseTracking = useDynamicMouseTracking
        self.showVisualFeedback = showVisualFeedback
        self.cpsRandomizerConfig = cpsRandomizerConfig
    }
}

/// Session statistics
struct SessionStatistics {
    let duration: TimeInterval
    let totalClicks: Int
    let successfulClicks: Int
    let failedClicks: Int
    let successRate: Double
    let averageClickTime: TimeInterval
    let clicksPerSecond: Double
    let isActive: Bool
}

// MARK: - Extensions

extension ClickCoordinator {
    /// Convenience method for starting simple click automation
    /// - Parameters:
    ///   - location: Location to click
    ///   - interval: Interval between clicks
    ///   - maxClicks: Maximum number of clicks (optional)
    func startSimpleAutomation(at location: CGPoint, interval: TimeInterval, maxClicks: Int? = nil) {
        let config = AutomationConfiguration(
            location: location,
            clickInterval: interval,
            maxClicks: maxClicks,
            useDynamicMouseTracking: false
        )
        startAutomation(with: config)
    }
    
    /// Convenience method for starting randomized click automation
    /// - Parameters:
    ///   - location: Base location to click
    ///   - interval: Interval between clicks
    ///   - variance: Location randomization variance
    ///   - maxClicks: Maximum number of clicks (optional)
    func startRandomizedAutomation(
        at location: CGPoint,
        interval: TimeInterval,
        variance: CGFloat,
        maxClicks: Int? = nil
    ) {
        let config = AutomationConfiguration(
            location: location,
            clickInterval: interval,
            maxClicks: maxClicks,
            randomizeLocation: true,
            locationVariance: variance,
            useDynamicMouseTracking: false
        )
        startAutomation(with: config)
    }
}
