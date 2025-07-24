import Foundation
import CoreGraphics

/// Codable configuration struct for saving and loading automation presets
struct PresetConfiguration: Codable, Identifiable {
    // MARK: - Properties
    
    /// Unique identifier for the preset
    let id: UUID
    
    /// User-provided name for the preset
    let name: String
    
    /// Creation timestamp
    let createdAt: Date
    
    /// Last modified timestamp
    let lastModified: Date
    
    // MARK: - Core Click Configuration
    
    /// Target click location
    let targetPoint: CGPoint?
    
    /// Click type (left, right)
    let clickType: ClickType
    
    /// Click timing configuration
    let intervalHours: Int
    let intervalMinutes: Int
    let intervalSeconds: Int
    let intervalMilliseconds: Int
    
    // MARK: - Duration Configuration
    
    /// Duration mode for stopping automation
    let durationMode: DurationMode
    
    /// Duration in seconds for time-limited automation
    let durationSeconds: Double
    
    /// Maximum number of clicks for click-count automation
    let maxClicks: Int
    
    // MARK: - Advanced Settings
    
    /// Whether to randomize click location
    let randomizeLocation: Bool
    
    /// Location variance for randomization in pixels
    let locationVariance: Double
    
    /// Whether to stop automation on errors
    let stopOnError: Bool
    
    /// Whether to show visual feedback overlay
    let showVisualFeedback: Bool
    
    /// Whether to play sound feedback
    let playSoundFeedback: Bool
    
    // MARK: - Emergency Stop Configuration
    
    /// Selected emergency stop key configuration
    let selectedEmergencyStopKey: HotkeyConfiguration
    
    /// Whether emergency stop is enabled
    let emergencyStopEnabled: Bool
    
    // MARK: - Timer Mode Configuration
    
    /// Timer mode setting
    let timerMode: TimerMode
    
    /// Timer duration in minutes
    let timerDurationMinutes: Int
    
    /// Timer duration in seconds
    let timerDurationSeconds: Int
    
    // MARK: - Computed Properties
    
    /// Total click interval in milliseconds
    var totalMilliseconds: Int {
        (intervalHours * 3600 + intervalMinutes * 60 + intervalSeconds) * 1000 + intervalMilliseconds
    }
    
    /// Estimated clicks per second
    var estimatedCPS: Double {
        guard totalMilliseconds > 0 else { return 0.0 }
        return 1000.0 / Double(totalMilliseconds)
    }
    
    /// Whether this preset configuration is valid
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               totalMilliseconds > 0 &&
               (durationMode != .timeLimit || durationSeconds > 0) &&
               (durationMode != .clickCount || maxClicks > 0)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        targetPoint: CGPoint?,
        clickType: ClickType,
        intervalHours: Int,
        intervalMinutes: Int,
        intervalSeconds: Int,
        intervalMilliseconds: Int,
        durationMode: DurationMode,
        durationSeconds: Double,
        maxClicks: Int,
        randomizeLocation: Bool,
        locationVariance: Double,
        stopOnError: Bool,
        showVisualFeedback: Bool,
        playSoundFeedback: Bool,
        selectedEmergencyStopKey: HotkeyConfiguration,
        emergencyStopEnabled: Bool,
        timerMode: TimerMode,
        timerDurationMinutes: Int,
        timerDurationSeconds: Int
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.targetPoint = targetPoint
        self.clickType = clickType
        self.intervalHours = intervalHours
        self.intervalMinutes = intervalMinutes
        self.intervalSeconds = intervalSeconds
        self.intervalMilliseconds = intervalMilliseconds
        self.durationMode = durationMode
        self.durationSeconds = durationSeconds
        self.maxClicks = maxClicks
        self.randomizeLocation = randomizeLocation
        self.locationVariance = locationVariance
        self.stopOnError = stopOnError
        self.showVisualFeedback = showVisualFeedback
        self.playSoundFeedback = playSoundFeedback
        self.selectedEmergencyStopKey = selectedEmergencyStopKey
        self.emergencyStopEnabled = emergencyStopEnabled
        self.timerMode = timerMode
        self.timerDurationMinutes = timerDurationMinutes
        self.timerDurationSeconds = timerDurationSeconds
    }
    
    /// Creates a PresetConfiguration from a ClickItViewModel
    @MainActor
    init(from viewModel: ClickItViewModel, name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.lastModified = Date()
        self.targetPoint = viewModel.targetPoint
        self.clickType = viewModel.clickType
        self.intervalHours = viewModel.intervalHours
        self.intervalMinutes = viewModel.intervalMinutes
        self.intervalSeconds = viewModel.intervalSeconds
        self.intervalMilliseconds = viewModel.intervalMilliseconds
        self.durationMode = viewModel.durationMode
        self.durationSeconds = viewModel.durationSeconds
        self.maxClicks = viewModel.maxClicks
        self.randomizeLocation = viewModel.randomizeLocation
        self.locationVariance = viewModel.locationVariance
        self.stopOnError = viewModel.stopOnError
        self.showVisualFeedback = viewModel.showVisualFeedback
        self.playSoundFeedback = viewModel.playSoundFeedback
        self.selectedEmergencyStopKey = viewModel.selectedEmergencyStopKey
        self.emergencyStopEnabled = viewModel.emergencyStopEnabled
        self.timerMode = viewModel.timerMode
        self.timerDurationMinutes = viewModel.timerDurationMinutes
        self.timerDurationSeconds = viewModel.timerDurationSeconds
    }
    
    /// Creates a copy of this preset with an updated name and last modified date
    func renamed(to newName: String) -> PresetConfiguration {
        return PresetConfiguration(
            id: self.id,
            name: newName,
            createdAt: self.createdAt,
            lastModified: Date(),
            targetPoint: self.targetPoint,
            clickType: self.clickType,
            intervalHours: self.intervalHours,
            intervalMinutes: self.intervalMinutes,
            intervalSeconds: self.intervalSeconds,
            intervalMilliseconds: self.intervalMilliseconds,
            durationMode: self.durationMode,
            durationSeconds: self.durationSeconds,
            maxClicks: self.maxClicks,
            randomizeLocation: self.randomizeLocation,
            locationVariance: self.locationVariance,
            stopOnError: self.stopOnError,
            showVisualFeedback: self.showVisualFeedback,
            playSoundFeedback: self.playSoundFeedback,
            selectedEmergencyStopKey: self.selectedEmergencyStopKey,
            emergencyStopEnabled: self.emergencyStopEnabled,
            timerMode: self.timerMode,
            timerDurationMinutes: self.timerDurationMinutes,
            timerDurationSeconds: self.timerDurationSeconds
        )
    }
}

// MARK: - Extensions

extension PresetConfiguration: Equatable {
    static func == (lhs: PresetConfiguration, rhs: PresetConfiguration) -> Bool {
        return lhs.id == rhs.id
    }
}

extension PresetConfiguration: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// MARK: - Custom Codable Implementation for HotkeyConfiguration

extension HotkeyConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case keyCode, modifiers, description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keyCode = try container.decode(UInt16.self, forKey: .keyCode)
        let modifiers = try container.decode(UInt32.self, forKey: .modifiers)
        let description = try container.decode(String.self, forKey: .description)
        self.init(keyCode: keyCode, modifiers: modifiers, description: description)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.keyCode, forKey: .keyCode)
        try container.encode(self.modifiers, forKey: .modifiers)
        try container.encode(self.description, forKey: .description)
    }
}

// MARK: - Custom Codable Implementation for TimerMode

extension TimerMode: Codable {
    enum CodingKeys: String, CodingKey {
        case rawValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .rawValue)
        
        switch rawValue {
        case "off":
            self = .off
        case "countdown":
            self = .countdown
        default:
            self = .off
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let rawValue: String
        switch self {
        case .off:
            rawValue = "off"
        case .countdown:
            rawValue = "countdown"
        }
        try container.encode(rawValue, forKey: .rawValue)
    }
}