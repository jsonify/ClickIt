import XCTest
@testable import ClickIt

@MainActor
final class PresetManagerTests: XCTestCase {
    var presetManager: PresetManager!
    var mockViewModel: ClickItViewModel!
    var testPreset: PresetConfiguration!
    
    override func setUp() {
        super.setUp()
        presetManager = PresetManager.shared
        mockViewModel = ClickItViewModel()
        
        // Clear any existing presets for clean test state
        presetManager.clearAllPresets()
        
        // Create a test preset with valid configuration
        testPreset = createValidTestPreset()
    }
    
    override func tearDown() {
        // Clean up after tests
        presetManager.clearAllPresets()
        presetManager = nil
        mockViewModel = nil
        testPreset = nil
        super.tearDown()
    }
    
    // MARK: - Save Preset Tests
    
    func testSaveValidPreset() {
        // When
        let success = presetManager.savePreset(testPreset)
        
        // Then
        XCTAssertTrue(success, "Should successfully save valid preset")
        XCTAssertEqual(presetManager.presetCount, 1, "Should have one saved preset")
        XCTAssertNotNil(presetManager.loadPreset(id: testPreset.id), "Should be able to load saved preset")
    }
    
    func testSaveInvalidPreset() {
        // Given
        let invalidPreset = PresetConfiguration(
            name: "", // Invalid empty name
            targetPoint: CGPoint(x: 100, y: 100),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 1,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 60,
            maxClicks: 100,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: true,
            showVisualFeedback: true,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: true,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 10
        )
        
        // When
        let success = presetManager.savePreset(invalidPreset)
        
        // Then
        XCTAssertFalse(success, "Should fail to save invalid preset")
        XCTAssertEqual(presetManager.presetCount, 0, "Should not save invalid preset")
        XCTAssertNotNil(presetManager.lastError, "Should have error message")
    }
    
    func testSaveDuplicatePresetName() {
        // Given
        presetManager.savePreset(testPreset)
        let duplicateNamePreset = createValidTestPreset(name: testPreset.name)
        
        // When
        let success = presetManager.savePreset(duplicateNamePreset)
        
        // Then
        XCTAssertFalse(success, "Should fail to save preset with duplicate name")
        XCTAssertEqual(presetManager.presetCount, 1, "Should still have only one preset")
        XCTAssertNotNil(presetManager.lastError, "Should have error message about duplicate name")
    }
    
    // MARK: - Load Preset Tests
    
    func testLoadPresetById() {
        // Given
        presetManager.savePreset(testPreset)
        
        // When
        let loadedPreset = presetManager.loadPreset(id: testPreset.id)
        
        // Then
        XCTAssertNotNil(loadedPreset, "Should load preset by ID")
        XCTAssertEqual(loadedPreset?.name, testPreset.name, "Loaded preset should have same name")
        XCTAssertEqual(loadedPreset?.estimatedCPS, testPreset.estimatedCPS, "Loaded preset should have same CPS")
    }
    
    func testLoadPresetByName() {
        // Given
        presetManager.savePreset(testPreset)
        
        // When
        let loadedPreset = presetManager.loadPreset(name: testPreset.name)
        
        // Then
        XCTAssertNotNil(loadedPreset, "Should load preset by name")
        XCTAssertEqual(loadedPreset?.id, testPreset.id, "Loaded preset should have same ID")
    }
    
    func testLoadNonexistentPreset() {
        // When
        let loadedById = presetManager.loadPreset(id: UUID())
        let loadedByName = presetManager.loadPreset(name: "NonexistentPreset")
        
        // Then
        XCTAssertNil(loadedById, "Should return nil for nonexistent preset ID")
        XCTAssertNil(loadedByName, "Should return nil for nonexistent preset name")
    }
    
    // MARK: - Delete Preset Tests
    
    func testDeletePresetById() {
        // Given
        presetManager.savePreset(testPreset)
        
        // When
        let success = presetManager.deletePreset(id: testPreset.id)
        
        // Then
        XCTAssertTrue(success, "Should successfully delete preset")
        XCTAssertEqual(presetManager.presetCount, 0, "Should have no presets after deletion")
        XCTAssertNil(presetManager.loadPreset(id: testPreset.id), "Should not be able to load deleted preset")
    }
    
    func testDeletePresetByName() {
        // Given
        presetManager.savePreset(testPreset)
        
        // When
        let success = presetManager.deletePreset(name: testPreset.name)
        
        // Then
        XCTAssertTrue(success, "Should successfully delete preset by name")
        XCTAssertEqual(presetManager.presetCount, 0, "Should have no presets after deletion")
    }
    
    func testDeleteNonexistentPreset() {
        // When
        let successById = presetManager.deletePreset(id: UUID())
        let successByName = presetManager.deletePreset(name: "NonexistentPreset")
        
        // Then
        XCTAssertFalse(successById, "Should fail to delete nonexistent preset by ID")
        XCTAssertFalse(successByName, "Should fail to delete nonexistent preset by name")
        XCTAssertNotNil(presetManager.lastError, "Should have error message")
    }
    
    // MARK: - Rename Preset Tests
    
    func testRenamePreset() {
        // Given
        presetManager.savePreset(testPreset)
        let newName = "Renamed Test Preset"
        
        // When
        let success = presetManager.renamePreset(id: testPreset.id, to: newName)
        
        // Then
        XCTAssertTrue(success, "Should successfully rename preset")
        let loadedPreset = presetManager.loadPreset(id: testPreset.id)
        XCTAssertEqual(loadedPreset?.name, newName, "Preset should have new name")
        XCTAssertNil(presetManager.loadPreset(name: testPreset.name), "Old name should not exist")
    }
    
    func testRenameToEmptyName() {
        // Given
        presetManager.savePreset(testPreset)
        
        // When
        let success = presetManager.renamePreset(id: testPreset.id, to: "   ")
        
        // Then
        XCTAssertFalse(success, "Should fail to rename to empty name")
        XCTAssertNotNil(presetManager.lastError, "Should have error message")
    }
    
    func testRenameToExistingName() {
        // Given
        let anotherPreset = createValidTestPreset(name: "Another Preset")
        presetManager.savePreset(testPreset)
        presetManager.savePreset(anotherPreset)
        
        // When
        let success = presetManager.renamePreset(id: testPreset.id, to: anotherPreset.name)
        
        // Then
        XCTAssertFalse(success, "Should fail to rename to existing name")
        XCTAssertNotNil(presetManager.lastError, "Should have error message about duplicate name")
    }
    
    // MARK: - Validation Tests
    
    func testValidateValidPreset() {
        // When
        let validationError = presetManager.validatePreset(testPreset)
        
        // Then
        XCTAssertNil(validationError, "Valid preset should have no validation errors")
    }
    
    func testValidatePresetWithEmptyName() {
        // Given
        let invalidPreset = createValidTestPreset(name: "")
        
        // When
        let validationError = presetManager.validatePreset(invalidPreset)
        
        // Then
        XCTAssertNotNil(validationError, "Should have validation error for empty name")
        XCTAssertTrue(validationError!.contains("name"), "Error should mention name")
    }
    
    func testValidatePresetWithZeroInterval() {
        // Given
        let invalidPreset = PresetConfiguration(
            name: "Invalid Interval",
            targetPoint: CGPoint(x: 100, y: 100),
            clickType: .left,
            intervalHours: 0,
            intervalMinutes: 0,
            intervalSeconds: 0,
            intervalMilliseconds: 0,
            durationMode: .unlimited,
            durationSeconds: 60,
            maxClicks: 100,
            randomizeLocation: false,
            locationVariance: 0,
            stopOnError: true,
            showVisualFeedback: true,
            playSoundFeedback: false,
            selectedEmergencyStopKey: .deleteKey,
            emergencyStopEnabled: true,
            timerMode: .off,
            timerDurationMinutes: 0,
            timerDurationSeconds: 10
        )
        
        // When
        let validationError = presetManager.validatePreset(invalidPreset)
        
        // Then
        XCTAssertNotNil(validationError, "Should have validation error for zero interval")
        XCTAssertTrue(validationError!.contains("interval"), "Error should mention interval")
    }
    
    // MARK: - Export/Import Tests
    
    func testExportPreset() {
        // When
        let exportData = presetManager.exportPreset(testPreset)
        
        // Then
        XCTAssertNotNil(exportData, "Should successfully export preset")
        XCTAssertGreaterThan(exportData!.count, 0, "Export data should not be empty")
    }
    
    func testImportValidPreset() {
        // Given
        let exportData = presetManager.exportPreset(testPreset)!
        
        // When
        let importedPreset = presetManager.importPreset(from: exportData)
        
        // Then
        XCTAssertNotNil(importedPreset, "Should successfully import preset")
        XCTAssertEqual(importedPreset?.name, testPreset.name, "Imported preset should have same name")
        XCTAssertNotEqual(importedPreset?.id, testPreset.id, "Imported preset should have new ID")
    }
    
    func testImportInvalidData() {
        // Given
        let invalidData = "invalid json".data(using: .utf8)!
        
        // When
        let importedPreset = presetManager.importPreset(from: invalidData)
        
        // Then
        XCTAssertNil(importedPreset, "Should fail to import invalid data")
        XCTAssertNotNil(presetManager.lastError, "Should have error message")
    }
    
    func testImportWithNameConflict() {
        // Given
        presetManager.savePreset(testPreset)
        let exportData = presetManager.exportPreset(testPreset)!
        
        // When
        let importedPreset = presetManager.importPreset(from: exportData)
        
        // Then
        XCTAssertNotNil(importedPreset, "Should successfully import preset with name conflict")
        XCTAssertTrue(importedPreset!.name.contains("Imported"), "Should rename to avoid conflict")
        XCTAssertNotEqual(importedPreset?.name, testPreset.name, "Should have different name")
    }
    
    // MARK: - ViewModel Integration Tests
    
    func testSavePresetFromViewModel() {
        // Given
        setupMockViewModelWithTestData()
        
        // When
        let success = presetManager.savePresetFromViewModel(mockViewModel, name: "VM Test Preset")
        
        // Then
        XCTAssertTrue(success, "Should successfully save preset from view model")
        XCTAssertEqual(presetManager.presetCount, 1, "Should have one saved preset")
        
        let savedPreset = presetManager.loadPreset(name: "VM Test Preset")
        XCTAssertNotNil(savedPreset, "Should be able to load saved preset")
        XCTAssertEqual(savedPreset?.clickType, mockViewModel.clickType, "Should preserve click type")
        XCTAssertEqual(savedPreset?.intervalSeconds, mockViewModel.intervalSeconds, "Should preserve interval")
    }
    
    func testApplyPresetToViewModel() {
        // Given
        let originalClickType = mockViewModel.clickType
        let originalInterval = mockViewModel.intervalSeconds
        
        // When
        presetManager.applyPreset(testPreset, to: mockViewModel)
        
        // Then
        XCTAssertEqual(mockViewModel.clickType, testPreset.clickType, "Should apply click type")
        XCTAssertEqual(mockViewModel.intervalSeconds, testPreset.intervalSeconds, "Should apply interval")
        XCTAssertEqual(mockViewModel.targetPoint, testPreset.targetPoint, "Should apply target point")
        
        // Verify it actually changed from original values (assuming test preset is different)
        if testPreset.clickType != originalClickType {
            XCTAssertNotEqual(mockViewModel.clickType, originalClickType, "Click type should have changed")
        }
    }
    
    // MARK: - Utility Functions Tests
    
    func testIsPresetNameAvailable() {
        // Given
        presetManager.savePreset(testPreset)
        
        // When/Then
        XCTAssertFalse(presetManager.isPresetNameAvailable(testPreset.name), "Existing name should not be available")
        XCTAssertFalse(presetManager.isPresetNameAvailable(""), "Empty name should not be available")
        XCTAssertFalse(presetManager.isPresetNameAvailable("   "), "Whitespace name should not be available")
        XCTAssertTrue(presetManager.isPresetNameAvailable("New Preset Name"), "New name should be available")
    }
    
    func testClearAllPresets() {
        // Given
        presetManager.savePreset(testPreset)
        presetManager.savePreset(createValidTestPreset(name: "Another Preset"))
        
        // When
        let success = presetManager.clearAllPresets()
        
        // Then
        XCTAssertTrue(success, "Should successfully clear all presets")
        XCTAssertEqual(presetManager.presetCount, 0, "Should have no presets after clearing")
    }
    
    // MARK: - Helper Methods
    
    private func createValidTestPreset(name: String = "Test Preset") -> PresetConfiguration {
        return PresetConfiguration(
            name: name,
            targetPoint: CGPoint(x: 100, y: 200),
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
        mockViewModel.targetPoint = CGPoint(x: 300, y: 400)
        mockViewModel.clickType = .right
        mockViewModel.intervalSeconds = 2
        mockViewModel.intervalMilliseconds = 250
        mockViewModel.durationMode = .clickCount
        mockViewModel.maxClicks = 50
        mockViewModel.randomizeLocation = true
        mockViewModel.locationVariance = 10.0
    }
}