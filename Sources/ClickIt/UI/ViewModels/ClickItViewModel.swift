//
//  ClickItViewModel.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI
import CoreGraphics
import AppKit
import Combine

@MainActor
class ClickItViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var targetPoint: CGPoint?
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var appStatus: AppStatus = .ready

    // Settings
    @Published var clickSettings = ClickSettings()

    // Expose settings for UI binding
    var settings: ClickSettings {
        clickSettings
    }

    // Configuration Properties
    @Published var intervalHours = 0 {
        didSet {
            if isInitialized { syncSettingsFromViewModel() }
        }
    }
    @Published var intervalMinutes = 0 {
        didSet {
            if isInitialized { syncSettingsFromViewModel() }
        }
    }
    @Published var intervalSeconds = 10 {
        didSet {
            if isInitialized { syncSettingsFromViewModel() }
        }
    }
    @Published var intervalMilliseconds = 0 {
        didSet {
            if isInitialized { syncSettingsFromViewModel() }
        }
    }
    
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
    @Published var timerDurationSeconds: Int = 5
    @Published var isCountingDown: Bool = false
    @Published var remainingTime: TimeInterval = 0
    @Published var timerIsActive: Bool = false

    // MARK: - Initialization State
    private var isInitialized = false
    
    // MARK: - Computed Properties
    var totalMilliseconds: Int {
        (intervalHours * 3600 + intervalMinutes * 60 + intervalSeconds) * 1000 + intervalMilliseconds
    }
    
    var estimatedCPS: Double {
        guard totalMilliseconds > 0 else { return 0.0 }
        return 1000.0 / Double(totalMilliseconds)
    }
    
    var canStartAutomation: Bool {
        targetPoint != nil &&
        totalMilliseconds > 0 &&
        !isRunning &&
        !timerIsActive &&
        clickSettings.isValid
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
    private let schedulingManager = SchedulingManager.shared

    // MARK: - Active Target Mode State
    private var isProcessingActiveTargetClick = false
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadEmergencyStopSettings()

        // Initial sync without guard
        clickSettings.clickIntervalMs = Double(totalMilliseconds)
        if let point = targetPoint {
            clickSettings.clickLocation = point
        }

        isInitialized = true
    }
    
    // MARK: - Public Methods
    func setTargetPoint(_ point: CGPoint) {
        targetPoint = point
        clickSettings.clickLocation = point  // Sync with ClickSettings
    }

    private func syncSettingsFromViewModel() {
        // Guard against calling during initialization
        guard isInitialized else { return }

        // Sync timing settings
        clickSettings.clickIntervalMs = Double(totalMilliseconds)

        // Sync target point if set
        if let point = targetPoint {
            clickSettings.clickLocation = point
        }
    }
    
    func startAutomation() {
        // If timer mode is requested and not currently counting down, start timer
        if timerMode == .countdown && !isCountingDown {
            startTimerMode(durationMinutes: timerDurationMinutes, durationSeconds: timerDurationSeconds)
            return
        }

        // In active target mode, only require targetPoint and interval
        // In normal mode, require full canStartAutomation checks
        let hasMinimumRequirements = targetPoint != nil && totalMilliseconds > 0 && !isRunning
        let canStart = clickSettings.isActiveTargetMode ? hasMinimumRequirements : canStartAutomation

        guard let point = targetPoint, canStart else {
            print("ClickItViewModel: Cannot start automation - missing prerequisites")
            print("  targetPoint: \(targetPoint != nil), totalMs: \(totalMilliseconds), isRunning: \(isRunning)")
            print("  activeTargetMode: \(clickSettings.isActiveTargetMode), canStartAutomation: \(canStartAutomation)")
            return
        }

        // Handle scheduling modes
        switch clickSettings.schedulingMode {
        case .immediate:
            // Start automation immediately
            executeAutomation(at: point)

        case .scheduled:
            // Schedule automation for later
            scheduleAutomation(at: point)
        }
    }

    private func executeAutomation(at point: CGPoint) {
        print("ClickItViewModel: Executing automation immediately")

        // Disable mouse monitoring while automation is running to prevent
        // automated clicks from triggering the click handler
        if clickSettings.isActiveTargetMode {
            HotkeyManager.shared.unregisterMouseMonitor()
            print("ClickItViewModel: Disabled mouse monitoring during automation")
        }

        let config = createAutomationConfiguration(at: point)
        clickCoordinator.startAutomation(with: config)
        isRunning = true
        appStatus = .running
    }

    private func scheduleAutomation(at point: CGPoint) {
        let scheduledTime = clickSettings.scheduledDateTime
        print("ClickItViewModel: Scheduling automation for \(scheduledTime)")

        let success = schedulingManager.scheduleTask(for: scheduledTime) { [weak self] in
            guard let self = self else { return }

            let actualTime = Date()
            let timingError = actualTime.timeIntervalSince(scheduledTime)

            print("ClickItViewModel: 🎯 SCHEDULED AUTOMATION EXECUTING")
            print("  Scheduled: \(scheduledTime)")
            print("  Actual: \(actualTime)")
            print("  Error: \(timingError)s")

            // Execute automation without alert popup
            self.executeAutomation(at: point)
        }

        if success {
            appStatus = .scheduled(scheduledTime)
        } else {
            appStatus = .error("Invalid scheduled time")
        }
    }

    private func createAutomationConfiguration(at point: CGPoint) -> AutomationConfiguration {
        return AutomationConfiguration(
            location: point,
            clickType: clickType,
            clickInterval: Double(totalMilliseconds) / 1000.0,
            targetApplication: nil,
            maxClicks: durationMode == .clickCount ? maxClicks : nil,
            maxDuration: durationMode == .timeLimit ? durationSeconds : nil,
            stopOnError: clickSettings.isActiveTargetMode ? false : stopOnError, // Disable stopOnError for active target mode
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(randomizeLocation ? locationVariance : 0),
            useDynamicMouseTracking: clickSettings.isActiveTargetMode, // Use active target mode setting
            showVisualFeedback: showVisualFeedback
        )
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
            useDynamicMouseTracking: true, // Enable dynamic mouse tracking for timer mode
            showVisualFeedback: showVisualFeedback
        )
        
        print("[Timer Debug] Created automation config with interval: \(config.clickInterval)s, dynamic: \(config.useDynamicMouseTracking)")
        
        // REVERTED TO WORKING APPROACH: Use ClickCoordinator directly
        clickCoordinator.startAutomation(with: config)
        isRunning = true
        appStatus = .running
        
        print("[Timer Debug] Automation started with direct ClickCoordinator - dynamic: \(config.useDynamicMouseTracking)")
        print("[Timer Debug] Automation started - isRunning: \(isRunning)")
    }
    
    func stopAutomation() {
        // SIMPLE WORKING APPROACH: Direct ClickCoordinator call
        clickCoordinator.stopAutomation()
        cancelTimer() // Also cancel any active timer
        schedulingManager.cancelScheduledTask() // Cancel any scheduled tasks
        isRunning = false
        appStatus = .ready

        // Re-enable mouse monitoring if active target mode is still enabled
        if clickSettings.isActiveTargetMode {
            HotkeyManager.shared.registerMouseMonitor()
            print("ClickItViewModel: Re-enabled mouse monitoring after automation stopped")
        }

        print("ClickItViewModel: Stopped automation with direct ClickCoordinator")
    }
    
    func cancelScheduledTask() {
        schedulingManager.cancelScheduledTask()
        if case .scheduled = appStatus {
            appStatus = .ready
        }
    }

    func pauseAutomation() {
        guard isRunning && !isPaused else { return }
        
        // SIMPLE WORKING APPROACH: Direct ClickCoordinator call  
        clickCoordinator.pauseAutomation()
        isPaused = true
        appStatus = .paused
        
        print("ClickItViewModel: Paused automation with direct ClickCoordinator")
    }
    
    func resumeAutomation() {
        guard isPaused && !isRunning else { return }
        
        // SIMPLE WORKING APPROACH: Direct ClickCoordinator call
        clickCoordinator.resumeAutomation()
        isPaused = false
        isRunning = true
        appStatus = .running
        
        print("ClickItViewModel: Resumed automation with direct ClickCoordinator")
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
            useDynamicMouseTracking: false,
            showVisualFeedback: true
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
    
    // MARK: - Settings Export/Import
    
    /// Exports all current settings to a file
    func exportSettings() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "ClickIt-Settings-\(DateFormatter.filenameSafe.string(from: Date())).json"
        panel.title = "Export ClickIt Settings"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            let clickSettings = ClickSettings()
            
            // Update clickSettings with current viewModel values
            clickSettings.clickIntervalMs = Double((self?.totalMilliseconds ?? 1000))
            clickSettings.clickType = self?.clickType ?? .left
            clickSettings.durationMode = self?.durationMode ?? .unlimited
            clickSettings.durationSeconds = self?.durationSeconds ?? 60
            clickSettings.maxClicks = self?.maxClicks ?? 100
            if let targetPoint = self?.targetPoint {
                clickSettings.clickLocation = targetPoint
            }
            clickSettings.randomizeLocation = self?.randomizeLocation ?? false
            clickSettings.locationVariance = self?.locationVariance ?? 0
            clickSettings.stopOnError = self?.stopOnError ?? true
            clickSettings.showVisualFeedback = self?.showVisualFeedback ?? true
            clickSettings.playSoundFeedback = self?.playSoundFeedback ?? false
            
            guard let exportData = clickSettings.exportAllSettings() else {
                print("ViewModel: Failed to export settings")
                return
            }
            
            do {
                try exportData.write(to: url)
                print("ViewModel: Successfully exported settings to \(url.path)")
            } catch {
                print("ViewModel: Failed to write export file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Imports settings from a file
    func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.title = "Import ClickIt Settings"
        panel.allowsMultipleSelection = false
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.urls.first else { return }
            
            do {
                let importData = try Data(contentsOf: url)
                let clickSettings = ClickSettings()
                
                guard clickSettings.importSettings(from: importData) else {
                    print("ViewModel: Failed to import settings")
                    return
                }
                
                // Update viewModel with imported settings
                DispatchQueue.main.async {
                    self?.loadFromClickSettings(clickSettings)
                    print("ViewModel: Successfully imported settings from \(url.path)")
                }
                
            } catch {
                print("ViewModel: Failed to read import file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Updates viewModel properties from ClickSettings instance
    private func loadFromClickSettings(_ settings: ClickSettings) {
        // Convert milliseconds back to time components
        let totalMs = Int(settings.clickIntervalMs)
        intervalMilliseconds = totalMs % 1000
        let totalSeconds = totalMs / 1000
        intervalSeconds = totalSeconds % 60
        let totalMinutes = totalSeconds / 60
        intervalMinutes = totalMinutes % 60
        intervalHours = totalMinutes / 60
        
        // Update other settings
        clickType = settings.clickType
        durationMode = settings.durationMode
        durationSeconds = settings.durationSeconds
        maxClicks = settings.maxClicks
        if settings.clickLocation != .zero {
            targetPoint = settings.clickLocation
        }
        randomizeLocation = settings.randomizeLocation
        locationVariance = settings.locationVariance
        stopOnError = settings.stopOnError
        showVisualFeedback = settings.showVisualFeedback
        playSoundFeedback = settings.playSoundFeedback
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // SIMPLE WORKING APPROACH: Monitor click coordinator state changes only
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

                // Re-enable mouse monitoring if active target mode is still enabled
                if self.clickSettings.isActiveTargetMode {
                    HotkeyManager.shared.registerMouseMonitor()
                    print("ClickItViewModel: Re-enabled mouse monitoring after external stop")
                }
            }
        }
        .store(in: &cancellables)

        // Monitor active target mode changes
        clickSettings.$isActiveTargetMode.sink { [weak self] isEnabled in
            guard let self = self else { return }
            self.handleActiveTargetModeChange(isEnabled)
        }
        .store(in: &cancellables)
    }
    
    private func updateStatistics() {
        // SIMPLE WORKING APPROACH: Use ClickCoordinator statistics directly
        statistics = clickCoordinator.getSessionStatistics()
    }

    // MARK: - Active Target Mode Management

    private func handleActiveTargetModeChange(_ isEnabled: Bool) {
        print("ClickItViewModel: Active target mode changed to \(isEnabled)")

        if isEnabled {
            // Enable active target mode
            CursorManager.shared.showTargetCursor()
            setupMouseClickHandler()
        } else {
            // Disable active target mode
            CursorManager.shared.restoreNormalCursor()
            removeMouseClickHandler()
        }
    }

    private func setupMouseClickHandler() {
        // Set up the RIGHT click handler for active target mode (TOGGLE start/stop)
        HotkeyManager.shared.onRightMouseClick = { [weak self] in
            Task { @MainActor in
                self?.handleActiveTargetRightClick()
            }
        }

        // Register mouse monitoring
        HotkeyManager.shared.registerMouseMonitor()
        print("ClickItViewModel: Right-click handler registered (TOGGLE start/stop)")
    }

    private func removeMouseClickHandler() {
        // Remove the click handler
        HotkeyManager.shared.onRightMouseClick = nil

        // Unregister mouse monitoring
        HotkeyManager.shared.unregisterMouseMonitor()
        print("ClickItViewModel: Right-click handler removed")
    }

    private func handleActiveTargetRightClick() {
        // Prevent re-entrancy from rapid clicks or automated clicks
        guard !isProcessingActiveTargetClick else {
            print("ClickItViewModel: Ignoring right-click - already processing")
            return
        }

        isProcessingActiveTargetClick = true
        defer {
            // Reset the flag after a short delay to allow next click
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.isProcessingActiveTargetClick = false
            }
        }

        print("ClickItViewModel: Active target RIGHT-CLICK detected, isRunning: \(isRunning)")

        // Right-click: TOGGLE automation (start if stopped, stop if running)
        if isRunning {
            // Stop automation
            stopAutomation()
            print("ClickItViewModel: Stopped automation via right-click")
        } else {
            // Start automation - but only if other prerequisites are met
            if canStartAutomation || clickSettings.isActiveTargetMode {
                // In active target mode, capture the current mouse position
                // This is just for validation - the actual clicking will use live position
                if clickSettings.isActiveTargetMode {
                    let currentMousePosition = NSEvent.mouseLocation
                    targetPoint = currentMousePosition
                    clickSettings.clickLocation = currentMousePosition
                    print("ClickItViewModel: Captured mouse position for active target mode: \(currentMousePosition)")
                }

                startAutomation()
                print("ClickItViewModel: Started automation via right-click")
            } else {
                print("ClickItViewModel: Cannot start automation - prerequisites not met")
            }
        }
    }

    // MARK: - Emergency Stop
    
    /// Performs emergency stop using ClickCoordinator directly
    func emergencyStopAutomation() {
        // SIMPLE WORKING APPROACH: Direct ClickCoordinator call
        clickCoordinator.emergencyStopAutomation()

        // Cancel any active timer
        cancelTimer()

        // Update UI state immediately
        isRunning = false
        isPaused = false
        appStatus = .ready

        // Re-enable mouse monitoring if active target mode is still enabled
        if clickSettings.isActiveTargetMode {
            HotkeyManager.shared.registerMouseMonitor()
            print("ClickItViewModel: Re-enabled mouse monitoring after emergency stop")
        }

        print("ClickItViewModel: Emergency stop executed with direct ClickCoordinator")
    }
    
    /// Checks if a position is within any available screen bounds (supports multiple monitors)
    private func isPositionWithinAnyScreen(_ position: CGPoint) -> Bool {
        return CoordinateUtils.isPositionWithinAnyScreen(position)
    }
    
    /// Converts AppKit coordinates to CoreGraphics coordinates for multi-monitor setups
    private func convertAppKitToCoreGraphics(_ appKitPosition: CGPoint) -> CGPoint {
        return CoordinateUtils.convertAppKitToCoreGraphics(appKitPosition)
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
            let allScreens = CoordinateUtils.getAllScreenFrames()
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
            // We're already on MainActor via timer on main RunLoop, call directly
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
    case scheduled(Date)
    case error(String)

    var displayText: String {
        switch self {
        case .ready:
            return "Ready"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .scheduled(let date):
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.timeZone = TimeZone(identifier: "GMT")
            return "Scheduled for \(formatter.string(from: date)) GMT"
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
        case .scheduled:
            return .purple
        case .error:
            return .red
        }
    }
}
