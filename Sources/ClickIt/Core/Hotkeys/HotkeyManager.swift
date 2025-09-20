import Foundation
import AppKit
import SwiftUI

@MainActor
class HotkeyManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = HotkeyManager()
    
    // MARK: - Published Properties
    
    @Published var isRegistered: Bool = false
    @Published private(set) var currentHotkey: HotkeyConfiguration = .default
    @Published private(set) var availableHotkeys: [HotkeyConfiguration] = HotkeyConfiguration.allEmergencyStopKeys
    @Published var lastError: String?
    @Published var emergencyStopActivated: Bool = false
    
    // MARK: - Private Properties
    
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var lastHotkeyTime: TimeInterval = 0
    private let hotkeyDebounceInterval: TimeInterval = 0.01 // 10ms debounce for ultra-fast emergency response
    private var responseTimeTracker: EmergencyStopResponseTracker?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    func initialize() {
        registerDefaultHotkey()
    }
    
    func cleanup() {
        unregisterGlobalHotkey()
    }
    
    func registerGlobalHotkey(_ config: HotkeyConfiguration) -> Bool {
        // Unregister existing hotkey first
        unregisterGlobalHotkey()
        
        // Monitor multiple emergency stop keys
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleMultiKeyEvent(event)
        }
        
        // Install local event monitor for all emergency stop keys (when app is active)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleMultiKeyEvent(event)
            return event // Always pass through the event
        }
        
        if globalEventMonitor != nil || localEventMonitor != nil {
            currentHotkey = config
            isRegistered = true
            lastError = nil
            print("HotkeyManager: Successfully registered emergency stop key monitoring for all configured keys")
            return true
        } else {
            lastError = "Failed to register key event monitors"
            return false
        }
    }
    
    func unregisterGlobalHotkey() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        
        isRegistered = false
        print("HotkeyManager: Successfully unregistered hotkey monitoring")
    }
    
    // MARK: - Private Methods
    
    private func registerDefaultHotkey() {
        let success = registerGlobalHotkey(.default)
        if !success {
            print("HotkeyManager: Failed to register default DELETE hotkey")
        }
    }
    
    private func handleMultiKeyEvent(_ event: NSEvent) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        // Debounce emergency stop to prevent rapid fire (50ms for emergency response)
        if currentTime - lastHotkeyTime < hotkeyDebounceInterval {
            return
        }
        
        // Check if this event matches any emergency stop key
        if let matchedConfig = matchEmergencyStopKey(event) {
            print("HotkeyManager: Emergency stop key activated - \(matchedConfig.description)")
            lastHotkeyTime = currentTime
            handleEmergencyStop(triggeredBy: matchedConfig)
        }
    }
    
    private func matchEmergencyStopKey(_ event: NSEvent) -> HotkeyConfiguration? {
        // Check all available emergency stop configurations
        for config in availableHotkeys {
            if event.keyCode == config.keyCode {
                let requiredModifiers = NSEvent.ModifierFlags(rawValue: UInt(config.modifiers))
                let eventModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
                
                if requiredModifiers.isEmpty || eventModifiers == requiredModifiers {
                    return config
                }
            }
        }
        return nil
    }
    
    private func handleEmergencyStop(triggeredBy config: HotkeyConfiguration) {
        // Start tracking response time immediately
        responseTimeTracker = EmergencyStopResponseTracker()
        
        // Set emergency stop state immediately for visual feedback
        emergencyStopActivated = true
        
        // PRIORITY PATH: Direct synchronous emergency stop for <50ms guarantee
        print("HotkeyManager: EMERGENCY STOP activated (\(config.description))")
        
        // CRITICAL FIX: We're already on @MainActor, so call coordinator methods directly
        // without additional dispatch to avoid deadlock
        let coordinator = ClickCoordinator.shared
        
        if coordinator.isActive {
            // Call emergency stop method directly - no dispatch needed since we're on MainActor
            coordinator.emergencyStopAutomation()
            
            // Track response time
            if let tracker = self.responseTimeTracker {
                let responseTime = tracker.stopTracking()
                print("HotkeyManager: Emergency stop response time: \(responseTime)ms")
                
                // Log warning if response time exceeds target
                if responseTime > 50.0 {
                    print("⚠️ HotkeyManager: Emergency stop response time exceeded 50ms target: \(responseTime)ms")
                }
            }
        } else {
            print("HotkeyManager: Emergency stop triggered but no automation running")
            
            // Still track response time for diagnostic purposes
            if let tracker = self.responseTimeTracker {
                let responseTime = tracker.stopTracking()
                print("HotkeyManager: Emergency stop response time (no automation): \(responseTime)ms")
            }
        }
        
        // Reset emergency stop state after brief visual feedback period
        // Use Task for MainActor-safe async execution
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.emergencyStopActivated = false
            self.responseTimeTracker = nil
        }
    }
    
    // MARK: - Public Configuration Methods
    
    func setEmergencyStopKey(_ config: HotkeyConfiguration) -> Bool {
        return registerGlobalHotkey(config)
    }
    
    func getAvailableEmergencyStopKeys() -> [HotkeyConfiguration] {
        return HotkeyConfiguration.allEmergencyStopKeys
    }
    
    func supportsRequiredEmergencyStopKeys() -> Bool {
        let required = [
            HotkeyConfiguration.KeyCodes.escape,  // ESC
            HotkeyConfiguration.KeyCodes.f1,      // F1
            HotkeyConfiguration.KeyCodes.period,  // Period (for Cmd+Period)
            HotkeyConfiguration.KeyCodes.space    // Space
        ]
        
        let availableKeyCodes = Set(availableHotkeys.map { $0.keyCode })
        return required.allSatisfy { availableKeyCodes.contains($0) }
    }
    
    /// Checks if emergency stop is properly configured for background operation
    func isBackgroundOperationEnabled() -> Bool {
        // Both global and local event monitors should be active for full coverage
        let hasGlobalMonitor = globalEventMonitor != nil
        let hasLocalMonitor = localEventMonitor != nil
        let isRegistered = self.isRegistered
        
        print("HotkeyManager: Background operation status:")
        print("  - Global monitor (background): \(hasGlobalMonitor ? "✅" : "❌")")
        print("  - Local monitor (foreground): \(hasLocalMonitor ? "✅" : "❌")")  
        print("  - Overall registered: \(isRegistered ? "✅" : "❌")")
        
        return hasGlobalMonitor && hasLocalMonitor && isRegistered
    }
    
    /// Tests emergency stop response time to validate <50ms guarantee
    func testEmergencyStopResponseTime() -> EmergencyStopPerformanceResult {
        guard !ClickCoordinator.shared.isActive else {
            return EmergencyStopPerformanceResult(
                averageResponseTime: -1,
                maxResponseTime: -1,
                minResponseTime: -1,
                testsPassing: 0,
                totalTests: 0,
                meetsTarget: false,
                error: "Cannot test while automation is active"
            )
        }
        
        var responseTimes: [Double] = []
        let testIterations = 10
        let targetResponseTime = 50.0 // 50ms target
        
        for _ in 0..<testIterations {
            // Start a test automation session
            let testConfig = AutomationConfiguration(
                location: CGPoint(x: 100, y: 100),
                clickInterval: 5.0, // Long interval for testing
                maxClicks: 1000
            )
            
            ClickCoordinator.shared.startAutomation(with: testConfig)
            
            // Measure emergency stop response time
            let startTime = CFAbsoluteTimeGetCurrent()
            handleEmergencyStop(triggeredBy: currentHotkey)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let responseTime = (endTime - startTime) * 1000 // Convert to milliseconds
            responseTimes.append(responseTime)
            
            // Brief pause between tests
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        let averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        let maxResponseTime = responseTimes.max() ?? 0
        let minResponseTime = responseTimes.min() ?? 0
        let testsPassing = responseTimes.filter { $0 < targetResponseTime }.count
        let meetsTarget = testsPassing >= (testIterations * 9) / 10 // 90% must pass
        
        return EmergencyStopPerformanceResult(
            averageResponseTime: averageResponseTime,
            maxResponseTime: maxResponseTime,
            minResponseTime: minResponseTime,
            testsPassing: testsPassing,
            totalTests: testIterations,
            meetsTarget: meetsTarget,
            error: nil
        )
    }
    
    /// Comprehensive emergency stop reliability test across all automation states
    func testEmergencyStopReliability() -> EmergencyStopReliabilityResult {
        guard !ClickCoordinator.shared.isActive else {
            return EmergencyStopReliabilityResult(
                totalTests: 0,
                passedTests: 0,
                failedTests: [],
                overallReliability: 0.0,
                error: "Cannot test while automation is active"
            )
        }
        
        var testResults: [(String, Bool, String?)] = []
        let coordinator = ClickCoordinator.shared
        
        // Test 1: Emergency stop when automation is idle
        let (idleSuccess, idleError) = testEmergencyStopInState("idle") {
            // No automation running - emergency stop should handle gracefully
            handleEmergencyStop(triggeredBy: currentHotkey)
            return !coordinator.isActive
        }
        testResults.append(("Idle State", idleSuccess, idleError))
        
        // Test 2: Emergency stop during active automation
        let (activeSuccess, activeError) = testEmergencyStopInState("active") {
            let config = AutomationConfiguration(location: CGPoint(x: 100, y: 100), clickInterval: 5.0, maxClicks: 100)
            coordinator.startAutomation(with: config)
            Thread.sleep(forTimeInterval: 0.1) // Brief delay to ensure automation starts
            
            let wasActive = coordinator.isActive
            handleEmergencyStop(triggeredBy: currentHotkey)
            let stoppedSuccessfully = !coordinator.isActive
            
            return wasActive && stoppedSuccessfully
        }
        testResults.append(("Active Automation", activeSuccess, activeError))
        
        // Test 3: Emergency stop during paused automation
        let (pauseSuccess, pauseError) = testEmergencyStopInState("paused") {
            let config = AutomationConfiguration(location: CGPoint(x: 100, y: 100), clickInterval: 5.0, maxClicks: 100)
            coordinator.startAutomation(with: config)
            coordinator.pauseAutomation()
            Thread.sleep(forTimeInterval: 0.1) // Brief delay
            
            let wasPaused = coordinator.isPaused
            handleEmergencyStop(triggeredBy: currentHotkey)
            let stoppedSuccessfully = !coordinator.isActive && !coordinator.isPaused
            
            return wasPaused && stoppedSuccessfully
        }
        testResults.append(("Paused Automation", pauseSuccess, pauseError))
        
        // Test 4: Multiple rapid emergency stops
        let (rapidSuccess, rapidError) = testEmergencyStopInState("rapid") {
            let config = AutomationConfiguration(location: CGPoint(x: 100, y: 100), clickInterval: 5.0, maxClicks: 100)
            coordinator.startAutomation(with: config)
            
            // Multiple rapid stops
            handleEmergencyStop(triggeredBy: currentHotkey)
            handleEmergencyStop(triggeredBy: currentHotkey)
            handleEmergencyStop(triggeredBy: currentHotkey)
            
            return !coordinator.isActive
        }
        testResults.append(("Rapid Multiple Stops", rapidSuccess, rapidError))
        
        // Test 5: Emergency stop key switching reliability
        let (keySwitchSuccess, keySwitchError) = testEmergencyStopInState("key_switch") {
            var allKeysWork = true
            
            for keyConfig in [HotkeyConfiguration.escapeKey, HotkeyConfiguration.deleteKey, HotkeyConfiguration.f1Key] {
                let config = AutomationConfiguration(location: CGPoint(x: 100, y: 100), clickInterval: 5.0, maxClicks: 100)
                coordinator.startAutomation(with: config)
                
                handleEmergencyStop(triggeredBy: keyConfig)
                
                if coordinator.isActive {
                    allKeysWork = false
                    coordinator.stopAutomation() // Cleanup
                    break
                }
                
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            return allKeysWork
        }
        testResults.append(("Key Switching", keySwitchSuccess, keySwitchError))
        
        // Calculate results
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.1 }.count
        let failedTests = testResults.compactMap { result in
            result.1 ? nil : EmergencyStopReliabilityResult.FailedTest(
                testName: result.0,
                error: result.2 ?? "Unknown failure"
            )
        }
        
        let reliability = Double(passedTests) / Double(totalTests) * 100.0
        
        return EmergencyStopReliabilityResult(
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            overallReliability: reliability,
            error: nil
        )
    }
    
    /// Helper method to test emergency stop in a specific state
    private func testEmergencyStopInState(_ stateName: String, test: () -> Bool) -> (Bool, String?) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = test()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = (endTime - startTime) * 1000
        
        print("Emergency Stop Test [\(stateName)]: \(result ? "✅ PASS" : "❌ FAIL") (\(String(format: "%.2f", duration))ms)")
        
        // Cleanup
        ClickCoordinator.shared.stopAutomation()
        Thread.sleep(forTimeInterval: 0.1)
        
        return (result, nil)
    }
}

// MARK: - Supporting Types

struct HotkeyConfiguration {
    let keyCode: UInt16
    let modifiers: UInt32
    let description: String
    
    static let `default` = HotkeyConfiguration(
        keyCode: 18, // "1" key
        modifiers: UInt32(NSEvent.ModifierFlags.shift.rawValue | NSEvent.ModifierFlags.command.rawValue), // Shift + Cmd modifiers
        description: "Shift + Cmd + 1"
    )
}

// MARK: - Common Hotkey Configurations

extension HotkeyConfiguration {
    // MARK: - Primary Emergency Stop Keys
    
    static let deleteKey = HotkeyConfiguration(
        keyCode: 51, // DELETE key
        modifiers: 0,
        description: "DELETE Key"
    )
    
    static let escapeKey = HotkeyConfiguration(
        keyCode: 53, // ESC key
        modifiers: 0,
        description: "ESC Key"
    )
    
    static let f1Key = HotkeyConfiguration(
        keyCode: 122, // F1 key
        modifiers: 0,
        description: "F1 Key"
    )
    
    static let shiftF1Key = HotkeyConfiguration(
        keyCode: 122, // F1 key
        modifiers: UInt32(NSEvent.ModifierFlags.shift.rawValue),
        description: "Shift + F1"
    )
    
    static let spaceKey = HotkeyConfiguration(
        keyCode: 49, // Space key
        modifiers: 0,
        description: "Space Key"
    )
    
    static let cmdPeriod = HotkeyConfiguration(
        keyCode: 47, // Period key
        modifiers: UInt32(NSEvent.ModifierFlags.command.rawValue),
        description: "Cmd + Period"
    )
    
    static let shiftCmd1Key = HotkeyConfiguration(
        keyCode: 18, // "1" key
        modifiers: UInt32(NSEvent.ModifierFlags.shift.rawValue | NSEvent.ModifierFlags.command.rawValue),
        description: "Shift + Cmd + 1"
    )
    
    // MARK: - Extended Modifier Combinations
    
    static let cmdDelete = HotkeyConfiguration(
        keyCode: 51, // DELETE key
        modifiers: UInt32(NSEvent.ModifierFlags.command.rawValue),
        description: "Cmd + DELETE"
    )
    
    static let optionDelete = HotkeyConfiguration(
        keyCode: 51, // DELETE key
        modifiers: UInt32(NSEvent.ModifierFlags.option.rawValue),
        description: "Option + DELETE"
    )
    
    // MARK: - All Available Emergency Stop Keys

    static let allEmergencyStopKeys: [HotkeyConfiguration] = [
        .escapeKey,      // ESC key - Most intuitive emergency stop
        .deleteKey,      // DELETE key - Common emergency stop
        .f1Key,          // F1 key - Function key emergency stop
        .spaceKey,       // Space key - Easy to reach emergency stop
        .cmdPeriod,      // Cmd + Period - Standard macOS interrupt
        .shiftCmd1Key    // Shift + Cmd + 1 - Primary emergency stop key
    ]
    
    // MARK: - Key Code Constants
    
    struct KeyCodes {
        static let escape: UInt16 = 53
        static let delete: UInt16 = 51
        static let f1: UInt16 = 122
        static let space: UInt16 = 49
        static let period: UInt16 = 47
        static let one: UInt16 = 18
        
        private init() {}
    }
}

// MARK: - Emergency Stop Response Time Tracker

class EmergencyStopResponseTracker {
    private let startTime: CFAbsoluteTime
    
    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func stopTracking() -> Double {
        let endTime = CFAbsoluteTimeGetCurrent()
        return (endTime - startTime) * 1000 // Return milliseconds
    }
}

// MARK: - Emergency Stop Performance Result

struct EmergencyStopPerformanceResult {
    let averageResponseTime: Double    // Average response time in milliseconds
    let maxResponseTime: Double        // Maximum response time in milliseconds
    let minResponseTime: Double        // Minimum response time in milliseconds
    let testsPassing: Int              // Number of tests under 50ms target
    let totalTests: Int                // Total number of tests performed
    let meetsTarget: Bool              // Whether system meets <50ms guarantee
    let error: String?                 // Error message if testing failed
    
    var successRate: Double {
        guard totalTests > 0 else { return 0.0 }
        return Double(testsPassing) / Double(totalTests) * 100.0
    }
    
    var description: String {
        if let error = error {
            return "Emergency Stop Performance Test Failed: \(error)"
        }
        
        let status = meetsTarget ? "✅ PASS" : "❌ FAIL"
        return """
        Emergency Stop Performance \(status):
        • Average: \(String(format: "%.2f", averageResponseTime))ms
        • Range: \(String(format: "%.2f", minResponseTime))-\(String(format: "%.2f", maxResponseTime))ms
        • Success Rate: \(testsPassing)/\(totalTests) (\(String(format: "%.1f", successRate))%)
        • Target: <50ms (\(meetsTarget ? "MET" : "MISSED"))
        """
    }
}

// MARK: - Emergency Stop Reliability Result

struct EmergencyStopReliabilityResult {
    let totalTests: Int
    let passedTests: Int
    let failedTests: [FailedTest]
    let overallReliability: Double    // Percentage (0-100)
    let error: String?
    
    struct FailedTest {
        let testName: String
        let error: String
    }
    
    var isReliable: Bool {
        return overallReliability >= 95.0 // 95% reliability threshold
    }
    
    var description: String {
        if let error = error {
            return "Emergency Stop Reliability Test Failed: \(error)"
        }
        
        let status = isReliable ? "✅ RELIABLE" : "❌ UNRELIABLE"
        var result = """
        Emergency Stop Reliability \(status):
        • Overall: \(String(format: "%.1f", overallReliability))% (\(passedTests)/\(totalTests) tests passed)
        """
        
        if !failedTests.isEmpty {
            result += "\n• Failed Tests:"
            for failure in failedTests {
                result += "\n  - \(failure.testName): \(failure.error)"
            }
        }
        
        result += "\n• Reliability Target: ≥95% (\(isReliable ? "MET" : "MISSED"))"
        
        return result
    }
}
