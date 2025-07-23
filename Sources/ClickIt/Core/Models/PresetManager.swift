import Foundation
import Combine

/// Manager for saving, loading, and managing automation presets
@MainActor
class PresetManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = PresetManager()
    
    // MARK: - Published Properties
    
    @Published var availablePresets: [PresetConfiguration] = []
    @Published var lastError: String?
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let presetsKey = "ClickItPresets"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    private init() {
        configureCoders()
        loadPresets()
    }
    
    // MARK: - Public Methods
    
    /// Saves a new preset or updates an existing one
    /// - Parameters:
    ///   - preset: The preset configuration to save
    /// - Returns: True if saved successfully, false otherwise
    @discardableResult
    func savePreset(_ preset: PresetConfiguration) -> Bool {
        clearError()
        
        guard preset.isValid else {
            setError("Invalid preset configuration: \(validatePreset(preset) ?? "Unknown error")")
            return false
        }
        
        // Check for duplicate names (excluding the same preset being updated)
        if availablePresets.contains(where: { $0.name == preset.name && $0.id != preset.id }) {
            setError("A preset with the name '\(preset.name)' already exists")
            return false
        }
        
        // Update existing preset or add new one
        if let existingIndex = availablePresets.firstIndex(where: { $0.id == preset.id }) {
            availablePresets[existingIndex] = preset
        } else {
            availablePresets.append(preset)
        }
        
        // Sort presets by name for consistent ordering
        availablePresets.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        return persistPresets()
    }
    
    /// Loads a preset by ID
    /// - Parameter id: The unique identifier of the preset
    /// - Returns: The preset configuration if found, nil otherwise
    func loadPreset(id: UUID) -> PresetConfiguration? {
        return availablePresets.first { $0.id == id }
    }
    
    /// Loads a preset by name
    /// - Parameter name: The name of the preset
    /// - Returns: The preset configuration if found, nil otherwise
    func loadPreset(name: String) -> PresetConfiguration? {
        return availablePresets.first { $0.name == name }
    }
    
    /// Deletes a preset by ID
    /// - Parameter id: The unique identifier of the preset to delete
    /// - Returns: True if deleted successfully, false otherwise
    @discardableResult
    func deletePreset(id: UUID) -> Bool {
        clearError()
        
        guard let index = availablePresets.firstIndex(where: { $0.id == id }) else {
            setError("Preset not found")
            return false
        }
        
        availablePresets.remove(at: index)
        return persistPresets()
    }
    
    /// Deletes a preset by name
    /// - Parameter name: The name of the preset to delete
    /// - Returns: True if deleted successfully, false otherwise
    @discardableResult
    func deletePreset(name: String) -> Bool {
        clearError()
        
        guard let index = availablePresets.firstIndex(where: { $0.name == name }) else {
            setError("Preset with name '\(name)' not found")
            return false
        }
        
        availablePresets.remove(at: index)
        return persistPresets()
    }
    
    /// Renames an existing preset
    /// - Parameters:
    ///   - id: The unique identifier of the preset to rename
    ///   - newName: The new name for the preset
    /// - Returns: True if renamed successfully, false otherwise
    @discardableResult
    func renamePreset(id: UUID, to newName: String) -> Bool {
        clearError()
        
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            setError("Preset name cannot be empty")
            return false
        }
        
        guard let index = availablePresets.firstIndex(where: { $0.id == id }) else {
            setError("Preset not found")
            return false
        }
        
        // Check for duplicate names
        if availablePresets.contains(where: { $0.name == trimmedName && $0.id != id }) {
            setError("A preset with the name '\(trimmedName)' already exists")
            return false
        }
        
        let updatedPreset = availablePresets[index].renamed(to: trimmedName)
        availablePresets[index] = updatedPreset
        
        // Re-sort after rename
        availablePresets.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        return persistPresets()
    }
    
    /// Validates a preset configuration
    /// - Parameter preset: The preset to validate
    /// - Returns: Validation error message if invalid, nil if valid
    func validatePreset(_ preset: PresetConfiguration) -> String? {
        let trimmedName = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "Preset name cannot be empty"
        }
        
        if preset.totalMilliseconds <= 0 {
            return "Click interval must be greater than 0"
        }
        
        if preset.durationMode == .timeLimit && preset.durationSeconds <= 0 {
            return "Duration must be greater than 0 seconds when using time limit"
        }
        
        if preset.durationMode == .clickCount && preset.maxClicks <= 0 {
            return "Maximum clicks must be greater than 0 when using click count limit"
        }
        
        if preset.locationVariance < 0 {
            return "Location variance cannot be negative"
        }
        
        return nil
    }
    
    /// Exports a preset to JSON data for sharing
    /// - Parameter preset: The preset to export
    /// - Returns: JSON data if successful, nil otherwise
    func exportPreset(_ preset: PresetConfiguration) -> Data? {
        clearError()
        
        do {
            return try encoder.encode(preset)
        } catch {
            setError("Failed to export preset: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Imports a preset from JSON data
    /// - Parameter data: The JSON data containing the preset
    /// - Returns: The imported preset configuration if successful, nil otherwise
    func importPreset(from data: Data) -> PresetConfiguration? {
        clearError()
        
        do {
            var importedPreset = try decoder.decode(PresetConfiguration.self, from: data)
            
            // Generate new ID and update timestamps for imported preset
            importedPreset = PresetConfiguration(
                id: UUID(),
                name: importedPreset.name,
                createdAt: Date(),
                lastModified: Date(),
                targetPoint: importedPreset.targetPoint,
                clickType: importedPreset.clickType,
                intervalHours: importedPreset.intervalHours,
                intervalMinutes: importedPreset.intervalMinutes,
                intervalSeconds: importedPreset.intervalSeconds,
                intervalMilliseconds: importedPreset.intervalMilliseconds,
                durationMode: importedPreset.durationMode,
                durationSeconds: importedPreset.durationSeconds,
                maxClicks: importedPreset.maxClicks,
                randomizeLocation: importedPreset.randomizeLocation,
                locationVariance: importedPreset.locationVariance,
                stopOnError: importedPreset.stopOnError,
                showVisualFeedback: importedPreset.showVisualFeedback,
                playSoundFeedback: importedPreset.playSoundFeedback,
                selectedEmergencyStopKey: importedPreset.selectedEmergencyStopKey,
                emergencyStopEnabled: importedPreset.emergencyStopEnabled,
                timerMode: importedPreset.timerMode,
                timerDurationMinutes: importedPreset.timerDurationMinutes,
                timerDurationSeconds: importedPreset.timerDurationSeconds
            )
            
            // Validate imported preset
            guard importedPreset.isValid else {
                setError("Imported preset is invalid: \(validatePreset(importedPreset) ?? "Unknown error")")
                return nil
            }
            
            // Handle name conflicts
            if availablePresets.contains(where: { $0.name == importedPreset.name }) {
                var counter = 1
                var newName = "\(importedPreset.name) (Imported)"
                
                while availablePresets.contains(where: { $0.name == newName }) {
                    counter += 1
                    newName = "\(importedPreset.name) (Imported \(counter))"
                }
                
                importedPreset = importedPreset.renamed(to: newName)
            }
            
            return importedPreset
        } catch {
            setError("Failed to import preset: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Exports all presets to JSON data for backup
    /// - Returns: JSON data containing all presets if successful, nil otherwise
    func exportAllPresets() -> Data? {
        clearError()
        
        do {
            return try encoder.encode(availablePresets)
        } catch {
            setError("Failed to export all presets: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Imports multiple presets from JSON data
    /// - Parameters:
    ///   - data: The JSON data containing presets array
    ///   - replaceExisting: Whether to replace existing presets or append
    /// - Returns: Number of presets successfully imported
    @discardableResult
    func importAllPresets(from data: Data, replaceExisting: Bool = false) -> Int {
        clearError()
        
        do {
            let importedPresets = try decoder.decode([PresetConfiguration].self, from: data)
            
            if replaceExisting {
                availablePresets.removeAll()
            }
            
            var importedCount = 0
            
            for preset in importedPresets {
                if let validPreset = importPreset(from: try encoder.encode(preset)) {
                    if savePreset(validPreset) {
                        importedCount += 1
                    }
                }
            }
            
            return importedCount
        } catch {
            setError("Failed to import presets: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Clears all saved presets
    /// - Returns: True if cleared successfully, false otherwise
    @discardableResult
    func clearAllPresets() -> Bool {
        clearError()
        availablePresets.removeAll()
        return persistPresets()
    }
    
    /// Reloads presets from UserDefaults
    func reloadPresets() {
        loadPresets()
    }
    
    /// Gets preset count
    var presetCount: Int {
        return availablePresets.count
    }
    
    /// Checks if a preset name is available
    /// - Parameter name: The name to check
    /// - Returns: True if the name is available, false if already in use
    func isPresetNameAvailable(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !availablePresets.contains { $0.name == trimmedName }
    }
    
    // MARK: - Private Methods
    
    private func configureCoders() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private func loadPresets() {
        isLoading = true
        clearError()
        
        defer { isLoading = false }
        
        guard let data = userDefaults.data(forKey: presetsKey) else {
            // No saved presets, start with empty array
            availablePresets = []
            return
        }
        
        do {
            let loadedPresets = try decoder.decode([PresetConfiguration].self, from: data)
            
            // Filter out invalid presets and sort by name
            availablePresets = loadedPresets
                .filter { $0.isValid }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            // If we filtered out invalid presets, persist the cleaned list
            if loadedPresets.count != availablePresets.count {
                persistPresets()
            }
            
        } catch {
            setError("Failed to load presets: \(error.localizedDescription)")
            availablePresets = []
        }
    }
    
    @discardableResult
    private func persistPresets() -> Bool {
        clearError()
        
        do {
            let data = try encoder.encode(availablePresets)
            userDefaults.set(data, forKey: presetsKey)
            return true
        } catch {
            setError("Failed to save presets: \(error.localizedDescription)")
            return false
        }
    }
    
    private func setError(_ message: String) {
        lastError = message
        print("PresetManager Error: \(message)")
    }
    
    private func clearError() {
        lastError = nil
    }
}

// MARK: - Convenience Extensions

extension PresetManager {
    /// Creates a preset from current ClickItViewModel state
    /// - Parameters:
    ///   - viewModel: The view model to create preset from
    ///   - name: The name for the new preset
    /// - Returns: True if saved successfully, false otherwise
    @discardableResult
    func savePresetFromViewModel(_ viewModel: ClickItViewModel, name: String) -> Bool {
        let preset = PresetConfiguration(from: viewModel, name: name)
        return savePreset(preset)
    }
    
    /// Applies a preset to a ClickItViewModel
    /// - Parameters:
    ///   - preset: The preset to apply
    ///   - viewModel: The view model to update
    func applyPreset(_ preset: PresetConfiguration, to viewModel: ClickItViewModel) {
        viewModel.targetPoint = preset.targetPoint
        viewModel.clickType = preset.clickType
        viewModel.intervalHours = preset.intervalHours
        viewModel.intervalMinutes = preset.intervalMinutes
        viewModel.intervalSeconds = preset.intervalSeconds
        viewModel.intervalMilliseconds = preset.intervalMilliseconds
        viewModel.durationMode = preset.durationMode
        viewModel.durationSeconds = preset.durationSeconds
        viewModel.maxClicks = preset.maxClicks
        viewModel.randomizeLocation = preset.randomizeLocation
        viewModel.locationVariance = preset.locationVariance
        viewModel.stopOnError = preset.stopOnError
        viewModel.showVisualFeedback = preset.showVisualFeedback
        viewModel.playSoundFeedback = preset.playSoundFeedback
        viewModel.selectedEmergencyStopKey = preset.selectedEmergencyStopKey
        viewModel.emergencyStopEnabled = preset.emergencyStopEnabled
        viewModel.timerMode = preset.timerMode
        viewModel.timerDurationMinutes = preset.timerDurationMinutes
        viewModel.timerDurationSeconds = preset.timerDurationSeconds
    }
}