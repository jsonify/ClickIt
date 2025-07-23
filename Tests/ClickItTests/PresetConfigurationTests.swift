import XCTest
@testable import ClickIt

@MainActor
final class PresetConfigurationTests: XCTestCase {
    var testPreset: PresetConfiguration!
    var mockViewModel: ClickItViewModel!
    
    override func setUp() {
        super.setUp()
        testPreset = createValidPresetConfiguration()
        mockViewModel = ClickItViewModel()
    }
    
    override func tearDown() {
        testPreset = nil
        mockViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDirectInitialization() {
        // Given
        let name = "Test Preset"
        let targetPoint = CGPoint(x: 100, y: 200)
        let clickType = ClickType.right
        
        // When
        let preset = PresetConfiguration(
            name: name,
            targetPoint: targetPoint,
            clickType: clickType,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 2,
            intervalMilliseconds: 500,
            durationMode: .unlimited,
            durationSeconds: 30,
            maxClicks: 50,
            randomizeLocation: true,
            locationVariance: 10.0,
            stopOnError: false,
            showVisualFeedback: true,
            playSoundFeedback: true,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: true,
            timerMode: .countdown,
            timerDurationMinutes: 5,
            timerDurationSeconds: 30
        )
        
        // Then
        XCTAssertEqual(preset.name, name)
        XCTAssertEqual(preset.targetPoint, targetPoint)
        XCTAssertEqual(preset.clickType, clickType)
        XCTAssertEqual(preset.intervalSeconds, 2)
        XCTAssertEqual(preset.intervalMilliseconds, 500)
        XCTAssertEqual(preset.durationMode, .unlimited)
        XCTAssertEqual(preset.randomizeLocation, true)
        XCTAssertEqual(preset.locationVariance, 10.0)
        XCTAssertEqual(preset.timerMode, .countdown)
    }
    
    func testInitializationFromViewModel() {
        // Given
        setupMockViewModelWithTestData()
        let presetName = "VM Test Preset"
        
        // When
        let preset = PresetConfiguration(from: mockViewModel, name: presetName)
        
        // Then
        XCTAssertEqual(preset.name, presetName)
        XCTAssertEqual(preset.targetPoint, mockViewModel.targetPoint)
        XCTAssertEqual(preset.clickType, mockViewModel.clickType)
        XCTAssertEqual(preset.intervalHours, mockViewModel.intervalHours)
        XCTAssertEqual(preset.intervalMinutes, mockViewModel.intervalMinutes)
        XCTAssertEqual(preset.intervalSeconds, mockViewModel.intervalSeconds)
        XCTAssertEqual(preset.intervalMilliseconds, mockViewModel.intervalMilliseconds)
        XCTAssertEqual(preset.durationMode, mockViewModel.durationMode)
        XCTAssertEqual(preset.durationSeconds, mockViewModel.durationSeconds)
        XCTAssertEqual(preset.maxClicks, mockViewModel.maxClicks)
        XCTAssertEqual(preset.randomizeLocation, mockViewModel.randomizeLocation)
        XCTAssertEqual(preset.locationVariance, mockViewModel.locationVariance)
        XCTAssertEqual(preset.stopOnError, mockViewModel.stopOnError)
        XCTAssertEqual(preset.showVisualFeedback, mockViewModel.showVisualFeedback)
        XCTAssertEqual(preset.playSoundFeedback, mockViewModel.playSoundFeedback)
        XCTAssertEqual(preset.emergencyStopEnabled, mockViewModel.emergencyStopEnabled)
        XCTAssertEqual(preset.timerMode, mockViewModel.timerMode)
        XCTAssertEqual(preset.timerDurationMinutes, mockViewModel.timerDurationMinutes)
        XCTAssertEqual(preset.timerDurationSeconds, mockViewModel.timerDurationSeconds)
    }
    
    // MARK: - Computed Properties Tests
    
    func testTotalMilliseconds() {
        // Given
        let preset = PresetConfiguration(
            name: "Time Test",
            targetPoint: CGPoint(x: 0, y: 0),
            clickType: .left,
            intervalHours: 1,
            intervalMinutes: 30,
            intervalSeconds: 45,
            intervalMilliseconds: 250,
            durationMode: .unlimited,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let totalMs = preset.totalMilliseconds
        
        // Then
        let expectedMs = (1 * 3600 + 30 * 60 + 45) * 1000 + 250
        XCTAssertEqual(totalMs, expectedMs)
    }
    
    func testEstimatedCPS() {
        // Given
        let preset = PresetConfiguration(
            name: "CPS Test",
            targetPoint: CGPoint(x: 0, y: 0),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 2,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let cps = preset.estimatedCPS
        
        // Then
        XCTAssertEqual(cps, 0.5, accuracy: 0.001, "2000ms interval should give 0.5 CPS")
    }
    
    func testEstimatedCPSWithZeroInterval() {
        // Given
        let preset = PresetConfiguration(
            name: "Zero CPS Test",
            targetPoint: CGPoint(x: 0, y: 0),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 0,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let cps = preset.estimatedCPS
        
        // Then
        XCTAssertEqual(cps, 0.0, "Zero interval should give 0 CPS")
    }
    
    // MARK: - Validation Tests
    
    func testIsValidWithValidConfiguration() {
        // When
        let isValid = testPreset.isValid
        
        // Then
        XCTAssertTrue(isValid, "Valid preset should pass validation")
    }
    
    func testIsValidWithEmptyName() {
        // Given
        let preset = PresetConfiguration(
            name: "",
            targetPoint: CGPoint(x: 100, y: 100),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 1,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let isValid = preset.isValid
        
        // Then
        XCTAssertFalse(isValid, "Preset with empty name should be invalid")
    }
    
    func testIsValidWithWhitespaceOnlyName() {
        // Given
        let preset = PresetConfiguration(
            name: "   \t\n   ",
            targetPoint: CGPoint(x: 100, y: 100),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 1,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let isValid = preset.isValid
        
        // Then
        XCTAssertFalse(isValid, "Preset with whitespace-only name should be invalid")
    }
    
    func testIsValidWithZeroInterval() {
        // Given
        let preset = PresetConfiguration(
            name: "Test",
            targetPoint: CGPoint(x: 100, y: 100),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 0,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let isValid = preset.isValid
        
        // Then
        XCTAssertFalse(isValid, "Preset with zero interval should be invalid")
    }
    
    func testIsValidWithTimeLimitModeAndZeroDuration() {
        // Given
        let preset = PresetConfiguration(
            name: "Test",
            targetPoint: CGPoint(x: 100, y: 100),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 1,
            intervalMilliseconds: 0,
            durationMode: .timeLimit,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let isValid = preset.isValid
        
        // Then
        XCTAssertFalse(isValid, "Preset with time limit mode and zero duration should be invalid")
    }
    
    func testIsValidWithClickCountModeAndZeroMaxClicks() {
        // Given
        let preset = PresetConfiguration(
            name: "Test",
            targetPoint: CGPoint(x: 100, y: 100),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 1,
            intervalMilliseconds: 0,
            durationMode: .clickCount,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let isValid = preset.isValid
        
        // Then
        XCTAssertFalse(isValid, "Preset with click count mode and zero max clicks should be invalid")
    }
    
    // MARK: - Rename Function Tests
    
    func testRenamePreset() {
        // Given
        let originalName = testPreset.name
        let newName = "Renamed Preset"
        
        // When
        let renamedPreset = testPreset.renamed(to: newName)
        
        // Then
        XCTAssertEqual(renamedPreset.name, newName, "Should have new name")
        XCTAssertEqual(renamedPreset.id, testPreset.id, "Should keep same ID")
        XCTAssertEqual(renamedPreset.createdAt, testPreset.createdAt, "Should keep same creation date")
        XCTAssertNotEqual(renamedPreset.lastModified, testPreset.lastModified, "Should update last modified date")
        
        // Verify other properties remain unchanged
        XCTAssertEqual(renamedPreset.clickType, testPreset.clickType)
        XCTAssertEqual(renamedPreset.intervalSeconds, testPreset.intervalSeconds)
        XCTAssertEqual(renamedPreset.durationMode, testPreset.durationMode)
    }
    
    // MARK: - Equatable and Hashable Tests
    
    func testEquality() {
        // Given
        let preset1 = createValidPresetConfiguration()
        let preset2 = createValidPresetConfiguration()
        let preset3 = PresetConfiguration(
            id: preset1.id, // Same ID
            name: "Different Name",
            createdAt: Date(),
            lastModified: Date(),
            targetPoint: CGPoint(x: 999, y: 999),
            clickType: .right,
            intervalHours: 5,
            intervalMinutes: 30,
            intervalSeconds: 15,
            intervalMilliseconds: 750,
            durationMode: .clickCount,
            durationSeconds: 999,
            maxClicks: 999,
            randomizeLocation: true,
            locationVariance: 99.0,
            stopOnError: true,
            showVisualFeedback: false,
            playSoundFeedback: true,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .countdown,
            timerDurationMinutes: 99,
            timerDurationSeconds: 59
        )
        
        // When/Then
        XCTAssertEqual(preset1, preset1, "Preset should equal itself")
        XCTAssertNotEqual(preset1, preset2, "Presets with different IDs should not be equal")
        XCTAssertEqual(preset1, preset3, "Presets with same ID should be equal despite other differences")
    }
    
    func testHashability() {
        // Given
        let preset1 = createValidPresetConfiguration()
        let preset2 = PresetConfiguration(
            id: preset1.id, // Same ID
            name: "Different Name",
            createdAt: Date(),
            lastModified: Date(),
            targetPoint: CGPoint(x: 999, y: 999),
            clickType: .right,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 5,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 0,
            maxClicks: 0,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: false,
            showVisualFeedback: false,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: false,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 0
        )
        
        // When
        let hash1 = preset1.hashValue
        let hash2 = preset2.hashValue
        
        // Then
        XCTAssertEqual(hash1, hash2, "Presets with same ID should have same hash")
    }
    
    // MARK: - Codable Tests
    
    func testEncodingAndDecoding() {
        // Given
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        // When
        do {
            let encodedData = try encoder.encode(testPreset)
            let decodedPreset = try decoder.decode(PresetConfiguration.self, from: encodedData)
            
            // Then
            XCTAssertEqual(decodedPreset.id, testPreset.id)
            XCTAssertEqual(decodedPreset.name, testPreset.name)
            XCTAssertEqual(decodedPreset.targetPoint, testPreset.targetPoint)
            XCTAssertEqual(decodedPreset.clickType, testPreset.clickType)
            XCTAssertEqual(decodedPreset.intervalHours, testPreset.intervalHours)
            XCTAssertEqual(decodedPreset.intervalMinutes, testPreset.intervalMinutes)
            XCTAssertEqual(decodedPreset.intervalSeconds, testPreset.intervalSeconds)
            XCTAssertEqual(decodedPreset.intervalMilliseconds, testPreset.intervalMilliseconds)
            XCTAssertEqual(decodedPreset.durationMode, testPreset.durationMode)
            XCTAssertEqual(decodedPreset.durationSeconds, testPreset.durationSeconds)
            XCTAssertEqual(decodedPreset.maxClicks, testPreset.maxClicks)
            XCTAssertEqual(decodedPreset.randomizeLocation, testPreset.randomizeLocation)
            XCTAssertEqual(decodedPreset.locationVariance, testPreset.locationVariance)
            XCTAssertEqual(decodedPreset.stopOnError, testPreset.stopOnError)
            XCTAssertEqual(decodedPreset.showVisualFeedback, testPreset.showVisualFeedback)
            XCTAssertEqual(decodedPreset.playSoundFeedback, testPreset.playSoundFeedback)
            XCTAssertEqual(decodedPreset.emergencyStopEnabled, testPreset.emergencyStopEnabled)
            XCTAssertEqual(decodedPreset.timerMode, testPreset.timerMode)
            XCTAssertEqual(decodedPreset.timerDurationMinutes, testPreset.timerDurationMinutes)
            XCTAssertEqual(decodedPreset.timerDurationSeconds, testPreset.timerDurationSeconds)
        } catch {
            XCTFail("Encoding/Decoding failed: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createValidPresetConfiguration() -> PresetConfiguration {
        return PresetConfiguration(
            name: "Test Preset",
            targetPoint: CGPoint(x: 150, y: 250),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 1,
            intervalMilliseconds: 500,
            durationMode: .timeLimit,
            durationSeconds: 60,
            maxClicks: 100,
            randomizeLocation: true,
            locationVariance: 5.0,
            stopOnError: true,
            showVisualFeedback: true,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: true,
            timerMode: .off,
            timerDurationMinutes: 1,
            timerDurationSeconds: 30
        )
    }
    
    private func setupMockViewModelWithTestData() {
        mockViewModel.targetPoint = CGPoint(x: 400, y: 300)
        mockViewModel.clickType = .right
        mockViewModel.intervalHours = 0
        mockViewModel.intervalMinutes = 1
        mockViewModel.intervalSeconds = 30
        mockViewModel.intervalMilliseconds = 750
        mockViewModel.durationMode = .clickCount
        mockViewModel.durationSeconds = 120
        mockViewModel.maxClicks = 75
        mockViewModel.randomizeLocation = false
        mockViewModel.locationVariance = 15.0
        mockViewModel.stopOnError = false
        mockViewModel.showVisualFeedback = false
        mockViewModel.playSoundFeedback = true
        mockViewModel.emergencyStopEnabled = false
        mockViewModel.timerMode = .countdown
        mockViewModel.timerDurationMinutes = 2
        mockViewModel.timerDurationSeconds = 45
    }
}