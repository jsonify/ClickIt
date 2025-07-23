//
//  ClickItViewModel.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI
import CoreGraphics
import Combine

@MainActor
class ClickItViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var targetPoint: CGPoint?
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var appStatus: AppStatus = .ready
    
    // Configuration Properties
    @Published var intervalHours = 0
    @Published var intervalMinutes = 0
    @Published var intervalSeconds = 1
    @Published var intervalMilliseconds = 0
    
    @Published var clickType: ClickType = .left
    @Published var durationMode: DurationMode = .unlimited
    @Published var durationSeconds: Double = 60
    @Published var maxClicks = 100
    
    // Advanced Settings
    @Published var randomizeLocation = false
    @Published var locationVariance: Double = 0
    @Published var stopOnError = true
    @Published var showVisualFeedback = true
    @Published var playSoundFeedback = false
    
    // Emergency Stop Settings
    @Published var selectedEmergencyStopKey: HotkeyConfiguration = .default
    @Published var emergencyStopEnabled = true
    
    // Statistics
    @Published var statistics: SessionStatistics?
    
    // MARK: - Timer Mode Properties
    @Published var timerMode: TimerMode = .off
    @Published var timerDurationMinutes: Int = 0
    @Published var timerDurationSeconds: Int = 10
    @Published var isCountingDown: Bool = false
    @Published var remainingTime: TimeInterval = 0
    @Published var timerIsActive: Bool = false
    
    // MARK: - Computed Properties
    var totalMilliseconds: Int {
        (intervalHours * 3600 + intervalMinutes * 60 + intervalSeconds) * 1000 + intervalMilliseconds
    }
    
    var estimatedCPS: Double {
        guard totalMilliseconds > 0 else { return 0.0 }
        return 1000.0 / Double(totalMilliseconds)
    }
    
    var canStartAutomation: Bool {
        targetPoint != nil && totalMilliseconds > 0 && !isRunning && !timerIsActive
    }
    
    var totalTimerSeconds: Int {
        timerDurationMinutes * 60 + timerDurationSeconds
    }
    
    var isValidTimerDuration: Bool {
        let total = totalTimerSeconds
        return total >= 1 && total <= 3600 // 1 second to 60 minutes
    }
    
    var canPause: Bool {
        isRunning && !isPaused
    }
    
    var canResume: Bool {
        isPaused && !isRunning
    }
    
    // MARK: - Dependencies
    private let clickCoordinator = ClickCoordinator.shared
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadEmergencyStopSettings()
    }
    
    // MARK: - Public Methods
    func setTargetPoint(_ point: CGPoint) {
        targetPoint = point
    }
    
    func startAutomation() {
        // If timer mode is requested and not currently counting down, start timer
        if timerMode == .countdown && !isCountingDown {
            startTimerMode(durationMinutes: timerDurationMinutes, durationSeconds: timerDurationSeconds)
            return
        }
        
        guard let point = targetPoint, canStartAutomation else { return }
        
        let config = AutomationConfiguration(
            location: point,
            clickType: clickType,
            clickInterval: Double(totalMilliseconds) / 1000.0,
            targetApplication: nil,
            maxClicks: durationMode == .clickCount ? maxClicks : nil,
            maxDuration: durationMode == .timeLimit ? durationSeconds : nil,
            stopOnError: stopOnError,
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(randomizeLocation ? locationVariance : 0),
            useDynamicMouseTracking: false // Normal automation uses fixed position
        )
        
        clickCoordinator.startAutomation(with: config)
        isRunning = true
        appStatus = .running
    }
    
    private func startDynamicAutomation() {
        guard let point = targetPoint else { 
            print("[Timer Debug] Error: No target point set")
            return 
        }
        
        // Check prerequisites manually (bypass canStartAutomation which checks timerIsActive)
        guard totalMilliseconds > 0 && !isRunning else { 
            print("[Timer Debug] Error: Prerequisites not met - totalMs: \(totalMilliseconds), isRunning: \(isRunning)")
            return 
        }
        
        print("[Timer Debug] Starting dynamic automation with initial point: \(point)")
        
        let config = AutomationConfiguration(
            location: point, // This will be ignored in dynamic mode
            clickType: clickType,
            clickInterval: Double(totalMilliseconds) / 1000.0,
            targetApplication: nil,
            maxClicks: durationMode == .clickCount ? maxClicks : nil,
            maxDuration: durationMode == .timeLimit ? durationSeconds : nil,
            stopOnError: false, // Disable stopOnError for timer mode to avoid timing constraint issues
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(randomizeLocation ? locationVariance : 0),
            useDynamicMouseTracking: true // Enable dynamic mouse tracking for timer mode
        )
        
        print("[Timer Debug] Created automation config with interval: \(config.clickInterval)s, dynamic: \(config.useDynamicMouseTracking)")
        
        clickCoordinator.startAutomation(with: config)
        isRunning = true
        appStatus = .running
        
        print("[Timer Debug] Automation started - isRunning: \(isRunning)")
    }
    
    func stopAutomation() {
        clickCoordinator.stopAutomation()
        cancelTimer() // Also cancel any active timer
        isRunning = false
        isPaused = false
        appStatus = .ready
    }
    
    func pauseAutomation() {
        guard isRunning && !isPaused else { return }
        
        clickCoordinator.stopAutomation()
        ElapsedTimeManager.shared.pauseTracking()
        
        // Update visual feedback to show paused state (dimmed)
        if showVisualFeedback, let point = targetPoint {
            VisualFeedbackOverlay.shared.updateOverlay(at: point, isActive: false)
        }
        
        isRunning = false
        isPaused = true
        appStatus = .paused
    }
    
    func resumeAutomation() {
        guard isPaused && !isRunning else { return }
        
        // Resume elapsed time tracking
        ElapsedTimeManager.shared.resumeTracking()
        
        // Restart automation with current configuration
        guard let point = targetPoint else { return }
        
        let config = AutomationConfiguration(
            location: point,
            clickType: clickType,
            clickInterval: Double(totalMilliseconds) / 1000.0,
            targetApplication: nil,
            maxClicks: durationMode == .clickCount ? maxClicks : nil,
            maxDuration: durationMode == .timeLimit ? durationSeconds : nil,
            stopOnError: stopOnError,
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(randomizeLocation ? locationVariance : 0),
            useDynamicMouseTracking: false
        )
        
        clickCoordinator.startAutomation(with: config)
        isRunning = true
        isPaused = false
        appStatus = .running
        
        // Update visual feedback to show active state
        if showVisualFeedback {
            VisualFeedbackOverlay.shared.updateOverlay(at: point, isActive: true)
        }
    }
    
    // MARK: - Testing Methods
    func startAutomationForTesting() {
        guard let point = targetPoint else { return }
        
        let config = AutomationConfiguration(
            location: point,
            clickType: clickType,
            clickInterval: Double(totalMilliseconds) / 1000.0,
            targetApplication: nil,
            maxClicks: durationMode == .clickCount ? maxClicks : nil,
            maxDuration: durationMode == .timeLimit ? durationSeconds : nil,
            stopOnError: stopOnError,
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(randomizeLocation ? locationVariance : 0),
            useDynamicMouseTracking: false
        )
        
        clickCoordinator.startAutomation(with: config)
        isRunning = true
        appStatus = .running
    }
    
    func resetConfiguration() {
        intervalHours = 0
        intervalMinutes = 0
        intervalSeconds = 1
        intervalMilliseconds = 0
        clickType = .left
        durationMode = .unlimited
        durationSeconds = 60
        maxClicks = 100
        randomizeLocation = false
        locationVariance = 0
        stopOnError = true
        showVisualFeedback = true
        playSoundFeedback = false
        
        // Reset timer configuration
        cancelTimer()
        timerDurationMinutes = 0
        timerDurationSeconds = 10
        timerMode = .off
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Monitor click coordinator state changes
        clickCoordinator.objectWillChange.sink { [weak self] in
            self?.updateStatistics()
        }
        .store(in: &cancellables)
        
        // Monitor automation active state to sync UI state
        clickCoordinator.$isActive.sink { [weak self] isActive in
            guard let self = self else { return }
            
            // Sync ViewModel state with ClickCoordinator state
            if !isActive && (self.isRunning || self.isPaused) {
                print("ClickItViewModel: Automation stopped externally (e.g., DELETE key), updating UI state")
                self.isRunning = false
                self.isPaused = false
                self.appStatus = .ready
                // Also cancel any active timer when automation stops
                self.cancelTimer()
            }
        }
        .store(in: &cancellables)
    }
    
    private func updateStatistics() {
        statistics = clickCoordinator.getSessionStatistics()
    }
    
    /// Checks if a position is within any available screen bounds (supports multiple monitors)
    private func isPositionWithinAnyScreen(_ position: CGPoint) -> Bool {
        for screen in NSScreen.screens {
            if screen.frame.contains(position) {
                print("[Timer Debug] Position \(position) is valid on screen: \(screen.frame)")
                return true
            }
        }
        print("[Timer Debug] Position \(position) is not within any screen bounds")
        return false
    }
    
    /// Converts AppKit coordinates to CoreGraphics coordinates for multi-monitor setups
    private func convertAppKitToCoreGraphics(_ appKitPosition: CGPoint) -> CGPoint {
        // Find which screen contains this point
        for screen in NSScreen.screens {
            if screen.frame.contains(appKitPosition) {
                // Convert using the specific screen's coordinate system
                let cgY = screen.frame.maxY - appKitPosition.y
                let cgPosition = CGPoint(x: appKitPosition.x, y: cgY)
                print("[Timer Debug] Multi-monitor conversion: AppKit \(appKitPosition) → CoreGraphics \(cgPosition) on screen \(screen.frame)")
                return cgPosition
            }
        }
        
        // Fallback to main screen if no screen contains the point
        let mainScreenHeight = NSScreen.main?.frame.height ?? 0
        let fallbackPosition = CGPoint(x: appKitPosition.x, y: mainScreenHeight - appKitPosition.y)
        print("[Timer Debug] Fallback conversion: AppKit \(appKitPosition) → CoreGraphics \(fallbackPosition)")
        return fallbackPosition
    }
    
    // MARK: - Emergency Stop Configuration Methods
    
    func setEmergencyStopKey(_ config: HotkeyConfiguration) {
        selectedEmergencyStopKey = config
        
        // Update the hotkey manager with new configuration
        if emergencyStopEnabled {
            let success = HotkeyManager.shared.setEmergencyStopKey(config)
            if !success {
                appStatus = .error("Failed to register emergency stop key: \(config.description)")
            }
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(config.keyCode, forKey: "EmergencyStopKeyCode")
        UserDefaults.standard.set(config.modifiers, forKey: "EmergencyStopModifiers")
        UserDefaults.standard.set(config.description, forKey: "EmergencyStopDescription")
    }
    
    func toggleEmergencyStop(_ enabled: Bool) {
        emergencyStopEnabled = enabled
        
        if enabled {
            let success = HotkeyManager.shared.setEmergencyStopKey(selectedEmergencyStopKey)
            if !success {
                appStatus = .error("Failed to enable emergency stop")
                emergencyStopEnabled = false
            }
        } else {
            HotkeyManager.shared.unregisterGlobalHotkey()
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(enabled, forKey: "EmergencyStopEnabled")
    }
    
    func getAvailableEmergencyStopKeys() -> [HotkeyConfiguration] {
        return HotkeyManager.shared.getAvailableEmergencyStopKeys()
    }
    
    private func loadEmergencyStopSettings() {
        // Load saved emergency stop settings
        emergencyStopEnabled = UserDefaults.standard.bool(forKey: "EmergencyStopEnabled") 
        
        // Load saved hotkey configuration
        let savedKeyCode = UserDefaults.standard.object(forKey: "EmergencyStopKeyCode") as? UInt16
        let savedModifiers = UserDefaults.standard.object(forKey: "EmergencyStopModifiers") as? UInt32
        let savedDescription = UserDefaults.standard.string(forKey: "EmergencyStopDescription")
        
        if let keyCode = savedKeyCode, let modifiers = savedModifiers, let description = savedDescription {
            selectedEmergencyStopKey = HotkeyConfiguration(
                keyCode: keyCode,
                modifiers: modifiers,
                description: description
            )
        } else {
            // Default to first available emergency stop key if no saved setting
            if let defaultKey = HotkeyConfiguration.allEmergencyStopKeys.first {
                selectedEmergencyStopKey = defaultKey
                emergencyStopEnabled = true // Enable by default
            }
        }
        
        // Initialize hotkey manager with saved settings
        if emergencyStopEnabled {
            let _ = HotkeyManager.shared.setEmergencyStopKey(selectedEmergencyStopKey)
        }
    }
    
    // MARK: - Timer Mode Methods
    
    func startTimerMode(durationMinutes: Int, durationSeconds: Int) {
        guard isValidTimerDuration else {
            appStatus = .error("Invalid timer duration")
            return
        }
        
        let totalSeconds = durationMinutes * 60 + durationSeconds
        remainingTime = TimeInterval(totalSeconds)
        isCountingDown = true
        timerIsActive = true
        timerMode = .countdown
        appStatus = .running
        
        startCountdownTimer()
    }
    
    func cancelTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        resetTimerState()
    }
    
    private func onTimerExpired() {
        defer { resetTimerState() }
        
        print("[Timer Debug] Timer expired, starting dynamic mouse tracking mode")
        
        // For timer mode, we want to use dynamic mouse tracking instead of fixed position
        // Set a placeholder target point to satisfy canStartAutomation
        let appKitPosition = NSEvent.mouseLocation
        print("[Timer Debug] Current mouse position when timer expired (AppKit): \(appKitPosition)")
        
        // Validate cursor position is within any available screen bounds
        guard isPositionWithinAnyScreen(appKitPosition) else {
            let allScreens = NSScreen.screens.map { $0.frame }
            print("[Timer Debug] Error: cursor position \(appKitPosition) is outside all screen bounds \(allScreens)")
            appStatus = .error("Invalid cursor position when timer expired")
            return
        }
        
        // Convert to CoreGraphics coordinates for consistency
        let cgPosition = convertAppKitToCoreGraphics(appKitPosition)
        print("[Timer Debug] Converted initial position to CoreGraphics: \(cgPosition)")
        
        // Set a placeholder target point (will be overridden by dynamic tracking)
        setTargetPoint(cgPosition)
        print("[Timer Debug] Set initial target point: \(cgPosition)")
        
        // Start automation with dynamic mouse tracking enabled
        let originalTimerMode = timerMode
        timerMode = .off
        startDynamicAutomation()
        timerMode = originalTimerMode
    }
    
    private func resetTimerState() {
        isCountingDown = false
        timerIsActive = false
        remainingTime = 0
        timerMode = .off
        if appStatus.displayText.contains("timer") || appStatus.displayText.contains("countdown") {
            appStatus = .ready
        }
    }
    
    private func startCountdownTimer() {
        print("[Timer Debug] Starting countdown timer with \(remainingTime) seconds remaining")
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.remainingTime -= 1.0
                print("[Timer Debug] Countdown tick: \(self.remainingTime) seconds remaining")
                
                if self.remainingTime <= 0 {
                    print("[Timer Debug] Countdown finished, calling onTimerExpired()")
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.onTimerExpired()
                }
            }
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
}

// MARK: - SessionStatistics Extensions
extension SessionStatistics {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedSuccessRate: String {
        String(format: "%.1f%%", successRate * 100)
    }
}

// MARK: - Supporting Types
enum TimerMode {
    case off          // Normal immediate automation
    case countdown    // Timer mode with countdown
}

enum AppStatus {
    case ready
    case running
    case paused
    case error(String)
    
    var displayText: String {
        switch self {
        case .ready:
            return "Ready"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .ready:
            return .green
        case .running:
            return .blue
        case .paused:
            return .orange
        case .error:
            return .red
        }
    }
}
