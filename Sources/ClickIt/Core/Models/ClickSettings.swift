import Foundation
import SwiftUI
import Combine

/// Configuration settings for click automation
@MainActor
class ClickSettings: ObservableObject {
    // MARK: - Published Properties

    /// Click interval in milliseconds
    @Published var clickIntervalMs: Double = 1000.0 {
        didSet {
            // Only save settings, no validation to avoid recursion
            saveSettings()
        }
    }
    
    /// Clicks per second (computed property)
    var clicksPerSecond: Double {
        get {
            1000.0 / clickIntervalMs
        }
        set {
            let newValue = max(1.0, min(100.0, newValue)) // Clamp between 1-100 CPS
            clickIntervalMs = 1000.0 / newValue
        }
    }

    /// Selected click type
    @Published var clickType: ClickType = .left {
        didSet {
            saveSettings()
        }
    }

    /// Duration mode for stopping automation
    @Published var durationMode: DurationMode = .unlimited {
        didSet {
            saveSettings()
        }
    }

    /// Duration value in seconds (when duration mode is not unlimited)
    @Published var durationSeconds: Double = 60.0 {
        didSet {
            // Only save settings, no validation to avoid recursion
            saveSettings()
        }
    }

    /// Maximum number of clicks (when duration mode is click count)
    @Published var maxClicks: Int = 100 {
        didSet {
            // Only save settings, no validation to avoid recursion
            saveSettings()
        }
    }

    /// Currently selected click location
    @Published var clickLocation: CGPoint = .zero {
        didSet {
            saveSettings()
        }
    }

    /// Currently selected target application
    @Published var targetApplication: String? {
        didSet {
            saveSettings()
        }
    }

    /// Whether to randomize click location
    @Published var randomizeLocation: Bool = false {
        didSet {
            saveSettings()
        }
    }

    /// Location randomization variance in pixels
    @Published var locationVariance: Double = 5.0 {
        didSet {
            // Only save settings, no validation to avoid recursion
            saveSettings()
        }
    }

    /// Whether to stop automation on errors
    @Published var stopOnError: Bool = false {
        didSet {
            saveSettings()
        }
    }

    /// Whether to show visual feedback during automation
    @Published var showVisualFeedback: Bool = true {
        didSet {
            saveSettings()
        }
    }

    /// Whether to play sound feedback
    @Published var playSoundFeedback: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - CPS Randomization Properties
    
    /// Whether to enable CPS timing randomization
    @Published var randomizeTiming: Bool = false {
        didSet {
            saveSettings()
        }
    }
    
    /// Timing variance as percentage (0.0-1.0, representing 0%-100%)
    @Published var timingVariancePercentage: Double = 0.1 {
        didSet {
            // Clamp between 0-100%
            timingVariancePercentage = max(0.0, min(1.0, timingVariancePercentage))
            saveSettings()
        }
    }
    
    /// Statistical distribution pattern for randomization
    @Published var distributionPattern: CPSRandomizer.DistributionPattern = .normal {
        didSet {
            saveSettings()
        }
    }
    
    /// Anti-detection humanness level
    @Published var humannessLevel: CPSRandomizer.HumannessLevel = .medium {
        didSet {
            saveSettings()
        }
    }

    // MARK: - Computed Properties

    /// Click interval in seconds
    var clickIntervalSeconds: Double {
        clickIntervalMs / 1000.0
    }

    /// Whether the current settings are valid
    var isValid: Bool {
        clickLocation != .zero && clickIntervalMs >= (AppConstants.minClickInterval * 1000)
    }

    /// Validation message for current settings
    var validationMessage: String? {
        if clickLocation == .zero {
            return "Please select a click location"
        }
        if clickIntervalMs < (AppConstants.minClickInterval * 1000) {
            return "Click interval must be at least \(Int(AppConstants.minClickInterval * 1000))ms"
        }
        return nil
    }

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ClickItSettings"

    // MARK: - Initialization

    init() {
        loadSettings()
    }

    // MARK: - Settings Management

    /// Save current settings to UserDefaults
    private func saveSettings() {
        let settings = SettingsData(
            clickIntervalMs: clickIntervalMs,
            clickType: clickType,
            durationMode: durationMode,
            durationSeconds: durationSeconds,
            maxClicks: maxClicks,
            clickLocation: clickLocation,
            targetApplication: targetApplication,
            randomizeLocation: randomizeLocation,
            locationVariance: locationVariance,
            stopOnError: stopOnError,
            showVisualFeedback: showVisualFeedback,
            playSoundFeedback: playSoundFeedback,
            randomizeTiming: randomizeTiming,
            timingVariancePercentage: timingVariancePercentage,
            distributionPattern: distributionPattern,
            humannessLevel: humannessLevel
        )

        do {
            let encoded = try JSONEncoder().encode(settings)
            userDefaults.set(encoded, forKey: settingsKey)
        } catch {
            print("ClickSettings: Failed to save settings - \(error.localizedDescription)")
        }
    }

    /// Load settings from UserDefaults
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            // No saved settings, use defaults
            return
        }

        do {
            let settings = try JSONDecoder().decode(SettingsData.self, from: data)
            clickIntervalMs = settings.clickIntervalMs
            clickType = settings.clickType
            durationMode = settings.durationMode
            durationSeconds = settings.durationSeconds
            maxClicks = settings.maxClicks
            clickLocation = settings.clickLocation
            targetApplication = settings.targetApplication
            randomizeLocation = settings.randomizeLocation
            locationVariance = settings.locationVariance
            stopOnError = settings.stopOnError
            showVisualFeedback = settings.showVisualFeedback
            playSoundFeedback = settings.playSoundFeedback
            randomizeTiming = settings.randomizeTiming
            timingVariancePercentage = settings.timingVariancePercentage
            distributionPattern = settings.distributionPattern
            humannessLevel = settings.humannessLevel
        } catch {
            print("ClickSettings: Failed to load settings - \(error.localizedDescription). Using defaults.")
        }
    }

    /// Reset all settings to defaults
    func resetToDefaults() {
        clickIntervalMs = 1000.0
        clickType = .left
        durationMode = .unlimited
        durationSeconds = 60.0
        maxClicks = 100
        clickLocation = .zero
        targetApplication = nil
        randomizeLocation = false
        locationVariance = 5.0
        stopOnError = false
        showVisualFeedback = true
        playSoundFeedback = false
        randomizeTiming = false
        timingVariancePercentage = 0.1
        distributionPattern = .normal
        humannessLevel = .medium
        saveSettings()
    }
    
    /// Create CPS randomizer configuration from current settings
    func createCPSRandomizerConfiguration() -> CPSRandomizer.Configuration {
        return CPSRandomizer.Configuration(
            enabled: randomizeTiming,
            variancePercentage: timingVariancePercentage,
            distributionPattern: distributionPattern,
            humannessLevel: humannessLevel,
            minimumInterval: AppConstants.minClickInterval,
            maximumInterval: 10.0 // 10 second maximum
        )
    }

    /// Create automation configuration from current settings
    func createAutomationConfiguration() -> AutomationConfiguration {
        let maxClicksValue = durationMode == .clickCount ? maxClicks : nil
        let maxDurationValue = durationMode == .timeLimit ? durationSeconds : nil
        
        print("ClickSettings: Creating automation config with location \(clickLocation), showVisualFeedback: \(showVisualFeedback)")

        return AutomationConfiguration(
            location: clickLocation,
            clickType: clickType,
            clickInterval: clickIntervalSeconds,
            targetApplication: targetApplication,
            maxClicks: maxClicksValue,
            maxDuration: maxDurationValue,
            stopOnError: stopOnError,
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(locationVariance),
            cpsRandomizerConfig: createCPSRandomizerConfiguration()
        )
    }
}

// MARK: - Supporting Types

/// Duration mode for automation stopping
enum DurationMode: String, CaseIterable, Codable {
    case unlimited = "unlimited"
    case timeLimit = "timeLimit"
    case clickCount = "clickCount"

    var displayName: String {
        switch self {
        case .unlimited:
            return "Unlimited"
        case .timeLimit:
            return "Time Limit"
        case .clickCount:
            return "Click Count"
        }
    }

    var description: String {
        switch self {
        case .unlimited:
            return "Run until manually stopped"
        case .timeLimit:
            return "Stop after specified time"
        case .clickCount:
            return "Stop after specified number of clicks"
        }
    }
}

/// Codable struct for persisting settings
private struct SettingsData: Codable {
    let clickIntervalMs: Double
    let clickType: ClickType
    let durationMode: DurationMode
    let durationSeconds: Double
    let maxClicks: Int
    let clickLocation: CGPoint
    let targetApplication: String?
    let randomizeLocation: Bool
    let locationVariance: Double
    let stopOnError: Bool
    let showVisualFeedback: Bool
    let playSoundFeedback: Bool
    let randomizeTiming: Bool
    let timingVariancePercentage: Double
    let distributionPattern: CPSRandomizer.DistributionPattern
    let humannessLevel: CPSRandomizer.HumannessLevel
}

// MARK: - Extensions

extension ClickType: Codable {}
