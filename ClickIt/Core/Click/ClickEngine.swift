// swiftlint:disable file_header
import Foundation
import CoreGraphics
import ApplicationServices

/// High performance click engine for mouse event generation
class ClickEngine: @unchecked Sendable {
    // MARK: Properties
    
    /// Shared instance of the click engine
    static let shared = ClickEngine()
    
    /// Queue for handling click operations
    private let clickQueue = DispatchQueue(label: "com.clickit.clickengine", qos: .userInteractive)
    
    /// Timer for precision measurement
    private var precisionTimer: CFAbsoluteTime = 0
    
    // MARK: Initialization
    
    private init() {}
    
    // MARK: Public Methods
    
    /// Performs a single click operation
    /// - Parameter configuration: Click configuration specifying type, location, and options
    /// - Returns: Result of the click operation
    func performClick(configuration: ClickConfiguration) async -> ClickResult {
        await withCheckedContinuation { continuation in
            clickQueue.async {
                let result = self.executeClick(configuration: configuration)
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Performs a click operation synchronously
    /// - Parameter configuration: Click configuration specifying type, location, and options
    /// - Returns: Result of the click operation
    func performClickSync(configuration: ClickConfiguration) -> ClickResult {
        executeClick(configuration: configuration)
    }
    
    /// Performs a sequence of clicks
    /// - Parameter configurations: Array of click configurations
    /// - Returns: Array of click results
    func performClickSequence(configurations: [ClickConfiguration]) async -> [ClickResult] {
        var results: [ClickResult] = []
        
        for config in configurations {
            let result = await performClick(configuration: config)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: Private Methods
    
    /// Executes a click operation on the current queue
    /// - Parameter configuration: Click configuration
    /// - Returns: Result of the click operation
    private func executeClick(configuration: ClickConfiguration) -> ClickResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Validate location
        guard isValidLocation(configuration.location) else {
            return ClickResult(
                success: false,
                actualLocation: configuration.location,
                timestamp: startTime,
                error: .invalidLocation
            )
        }
        
        // Create mouse down event
        guard let mouseDownEvent = createMouseEvent(
            type: configuration.type.mouseDownEventType,
            location: configuration.location,
            button: configuration.type.mouseButton
        ) else {
            return ClickResult(
                success: false,
                actualLocation: configuration.location,
                timestamp: startTime,
                error: .eventCreationFailed
            )
        }
        
        // Create mouse up event
        guard let mouseUpEvent = createMouseEvent(
            type: configuration.type.mouseUpEventType,
            location: configuration.location,
            button: configuration.type.mouseButton
        ) else {
            return ClickResult(
                success: false,
                actualLocation: configuration.location,
                timestamp: startTime,
                error: .eventCreationFailed
            )
        }
        
        // Post events
        let postResult = postMouseEvents(
            downEvent: mouseDownEvent,
            upEvent: mouseUpEvent,
            targetPID: configuration.targetPID,
            delay: configuration.delayBetweenDownUp
        )
        
        _ = CFAbsoluteTimeGetCurrent()
        
        return ClickResult(
            success: postResult.success,
            actualLocation: configuration.location,
            timestamp: startTime,
            error: postResult.error
        )
    }
    
    /// Creates a mouse event
    /// - Parameters:
    ///   - type: Type of mouse event
    ///   - location: Location of the event
    ///   - button: Mouse button
    /// - Returns: Created mouse event or nil if creation failed
    private func createMouseEvent(type: CGEventType, location: CGPoint, button: CGMouseButton) -> CGEvent? {
        CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: location,
            mouseButton: button
        )
    }
    
    /// Posts mouse down and up events with precise timing
    /// - Parameters:
    ///   - downEvent: Mouse down event
    ///   - upEvent: Mouse up event
    ///   - targetPID: Target process ID (nil for systemwide)
    ///   - delay: Delay between down and up events
    /// - Returns: Result of posting operation
    private func postMouseEvents(
        downEvent: CGEvent,
        upEvent: CGEvent,
        targetPID: pid_t?,
        delay: TimeInterval
    ) -> (success: Bool, error: ClickError?) {
        let startTime = mach_absolute_time()
        
        print("ClickEngine: About to post mouse down event")
        // Post mouse down event
        let downResult = postEvent(downEvent, targetPID: targetPID)
        guard downResult.success else {
            print("ClickEngine: Mouse down event failed: \(String(describing: downResult.error))")
            return (false, downResult.error)
        }
        print("ClickEngine: Mouse down event posted successfully")
        
        // Precise delay between down and up
        if delay > 0 {
            usleep(UInt32(delay * 1_000_000)) // Convert to microseconds
        }
        
        print("ClickEngine: About to post mouse up event")
        // Post mouse up event
        let upResult = postEvent(upEvent, targetPID: targetPID)
        guard upResult.success else {
            print("ClickEngine: Mouse up event failed: \(String(describing: upResult.error))")
            return (false, upResult.error)
        }
        print("ClickEngine: Mouse up event posted successfully")
        
        let endTime = mach_absolute_time()
        
        // Validate timing precision (within 5ms)
        var timeInfo = mach_timebase_info()
        mach_timebase_info(&timeInfo)
        let elapsedNanos = (endTime - startTime) * UInt64(timeInfo.numer) / UInt64(timeInfo.denom)
        let elapsedMillis = Double(elapsedNanos) / 1_000_000.0
        
        let maxTime = delay * 1000 + AppConstants.maxClickTimingDeviation * 1000
        if elapsedMillis > maxTime {
            print("ClickEngine: Timing constraint violation: \(elapsedMillis)ms > \(maxTime)ms")
            return (false, .timingConstraintViolation)
        }
        
        print("ClickEngine: Click events completed successfully in \(elapsedMillis)ms")
        return (true, nil)
    }
    
    /// Posts a single event to the system or target process
    /// - Parameters:
    ///   - event: Event to post
    ///   - targetPID: Target process ID (nil for systemwide)
    /// - Returns: Result of posting operation
    private func postEvent(_ event: CGEvent, targetPID: pid_t?) -> (success: Bool, error: ClickError?) {
        // Check if we have Accessibility permissions
        guard AXIsProcessTrusted() else {
            print("ClickEngine: Accessibility permission denied")
            return (false, .permissionDenied)
        }
        
        if let pid = targetPID {
            // Validate that the process exists
            guard kill(pid, 0) == 0 else {
                print("ClickEngine: Target process \(pid) not found")
                return (false, .targetProcessNotFound)
            }
            // Post to specific process
            print("ClickEngine: Posting event to PID \(pid)")
            event.postToPid(pid)
        } else {
            // Post systemwide
            print("ClickEngine: Posting event systemwide")
            event.post(tap: .cghidEventTap)
        }
        
        return (true, nil)
    }
    
    /// Validates if a location is within screen bounds
    /// - Parameter location: Location to validate
    /// - Returns: True if location is valid, false otherwise
    private func isValidLocation(_ location: CGPoint) -> Bool {
        let screenBounds = CGDisplayBounds(CGMainDisplayID())
        return screenBounds.contains(location)
    }
}

// MARK: Extensions

extension ClickEngine {
    /// Convenience method for performing a left click
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func leftClick(at location: CGPoint, targetPID: pid_t? = nil) async -> ClickResult {
        let config = ClickConfiguration(type: .left, location: location, targetPID: targetPID)
        return await performClick(configuration: config)
    }
    
    /// Convenience method for performing a right click
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func rightClick(at location: CGPoint, targetPID: pid_t? = nil) async -> ClickResult {
        let config = ClickConfiguration(type: .right, location: location, targetPID: targetPID)
        return await performClick(configuration: config)
    }
    
    /// Convenience method for performing a left click synchronously
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func leftClickSync(at location: CGPoint, targetPID: pid_t? = nil) -> ClickResult {
        let config = ClickConfiguration(type: .left, location: location, targetPID: targetPID)
        return performClickSync(configuration: config)
    }
    
    /// Convenience method for performing a right click synchronously
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func rightClickSync(at location: CGPoint, targetPID: pid_t? = nil) -> ClickResult {
        let config = ClickConfiguration(type: .right, location: location, targetPID: targetPID)
        return performClickSync(configuration: config)
    }
}
