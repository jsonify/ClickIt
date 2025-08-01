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
    
    /// Click statistics
    @Published var clickCount: Int = 0
    @Published var successRate: Double = 1.0
    @Published var averageClickTime: TimeInterval = 0
    
    /// Elapsed time since automation started
    var elapsedTime: TimeInterval {
        guard isActive && sessionStartTime > 0 else { return 0 }
        return CFAbsoluteTimeGetCurrent() - sessionStartTime
    }
    
    /// Current automation configuration
    @Published var automationConfig: AutomationConfiguration?
    
    /// Active automation task
    private var automationTask: Task<Void, Never>?
    
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
        
        // Show visual feedback overlay if enabled
        if configuration.showVisualFeedback {
            if configuration.useDynamicMouseTracking {
                print("ClickCoordinator: Starting dynamic automation with visual feedback")
                // For dynamic mode, show overlay at current mouse position (in AppKit coordinates)
                let currentAppKitPosition = NSEvent.mouseLocation
                VisualFeedbackOverlay.shared.showOverlay(at: currentAppKitPosition, isActive: true)
            } else {
                print("ClickCoordinator: Starting fixed automation with visual feedback at \(configuration.location)")
                VisualFeedbackOverlay.shared.showOverlay(at: configuration.location, isActive: true)
            }
        } else {
            print("ClickCoordinator: Starting automation without visual feedback")
        }
        
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
        automationTask?.cancel()
        automationTask = nil
        
        // Hide visual feedback overlay immediately
        print("ClickCoordinator: About to hide visual feedback overlay")
        VisualFeedbackOverlay.shared.hideOverlay()
        print("ClickCoordinator: Visual feedback overlay hidden")
        
        automationConfig = nil
        print("ClickCoordinator: stopAutomation() completed")
    }
    
    /// Performs a single click with the given configuration
    /// - Parameter configuration: Click configuration
    /// - Returns: Result of the click operation
    func performSingleClick(configuration: ClickConfiguration) async -> ClickResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await ClickEngine.shared.performClick(configuration: configuration)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let clickTime = endTime - startTime
        
        await updateStatistics(result: result, clickTime: clickTime)
        
        return result
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
    
    // MARK: - Private Methods
    
    /// Runs the main automation loop
    /// - Parameter configuration: Automation configuration
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
            
            // Apply click interval
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
    
    /// Executes a single automation step
    /// - Parameter configuration: Automation configuration
    /// - Returns: Result of the automation step
    private func executeAutomationStep(configuration: AutomationConfiguration) async -> ClickResult {
        let baseLocation: CGPoint
        
        if configuration.useDynamicMouseTracking {
            // Get current mouse position dynamically and convert coordinate systems
            baseLocation = await MainActor.run {
                let appKitPosition = NSEvent.mouseLocation
                print("[Dynamic Debug] Current mouse position (AppKit): \(appKitPosition)")
                
                // Convert from AppKit coordinates to CoreGraphics coordinates with multi-monitor support
                let cgPosition = CoordinateUtils.convertAppKitToCoreGraphics(appKitPosition)
                print("[Dynamic Debug] Converted to CoreGraphics coordinates: \(cgPosition)")
                return cgPosition
            }
        } else {
            // Use the fixed configured location
            baseLocation = configuration.location
        }
        
        let location = configuration.randomizeLocation ? 
            randomizeLocation(base: baseLocation, variance: configuration.locationVariance) :
            baseLocation
        
        print("ClickCoordinator: Executing automation step at \(location) (dynamic: \(configuration.useDynamicMouseTracking))")
        
        // Update visual feedback overlay if enabled
        if configuration.showVisualFeedback {
            await MainActor.run {
                if configuration.useDynamicMouseTracking {
                    // Convert back to AppKit coordinates for overlay positioning
                    let appKitLocation = CoordinateUtils.convertCoreGraphicsToAppKit(location)
                    print("[Dynamic Debug] Overlay position (AppKit): \(appKitLocation)")
                    VisualFeedbackOverlay.shared.updateOverlay(at: appKitLocation, isActive: true)
                } else {
                    VisualFeedbackOverlay.shared.updateOverlay(at: location, isActive: true)
                }
            }
        }
        
        // Perform the actual click
        print("ClickCoordinator: Performing actual click at \(location)")
        let result: ClickResult
        
        if let targetApp = configuration.targetApplication {
            result = await performBackgroundClick(
                bundleIdentifier: targetApp,
                at: location,
                clickType: configuration.clickType
            )
        } else {
            let config = ClickConfiguration(
                type: configuration.clickType,
                location: location,
                targetPID: nil
            )
            result = await performSingleClick(configuration: config)
        }
        
        print("ClickCoordinator: Click result: success=\(result.success)")
        
        // Show click pulse for successful clicks
        if configuration.showVisualFeedback && result.success {
            await MainActor.run {
                if configuration.useDynamicMouseTracking {
                    // Convert back to AppKit coordinates for pulse positioning
                    let appKitLocation = CoordinateUtils.convertCoreGraphicsToAppKit(location)
                    VisualFeedbackOverlay.shared.showClickPulse(at: appKitLocation)
                } else {
                    VisualFeedbackOverlay.shared.showClickPulse(at: location)
                }
            }
        }
        
        return result
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
    
    // MARK: - Coordinate conversion methods removed
    // These have been consolidated into CoordinateUtils for reuse across the codebase
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
    let showVisualFeedback: Bool
    let useDynamicMouseTracking: Bool
    
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
        showVisualFeedback: Bool = true,
        useDynamicMouseTracking: Bool = false
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
        self.showVisualFeedback = showVisualFeedback
        self.useDynamicMouseTracking = useDynamicMouseTracking
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
    ///   - showVisualFeedback: Whether to show visual feedback overlay
    func startSimpleAutomation(at location: CGPoint, interval: TimeInterval, maxClicks: Int? = nil, showVisualFeedback: Bool = true) {
        let config = AutomationConfiguration(
            location: location,
            clickInterval: interval,
            maxClicks: maxClicks,
            showVisualFeedback: showVisualFeedback,
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
    ///   - showVisualFeedback: Whether to show visual feedback overlay
    func startRandomizedAutomation(
        at location: CGPoint,
        interval: TimeInterval,
        variance: CGFloat,
        maxClicks: Int? = nil,
        showVisualFeedback: Bool = true
    ) {
        let config = AutomationConfiguration(
            location: location,
            clickInterval: interval,
            maxClicks: maxClicks,
            randomizeLocation: true,
            locationVariance: variance,
            showVisualFeedback: showVisualFeedback,
            useDynamicMouseTracking: false
        )
        startAutomation(with: config)
    }
}
