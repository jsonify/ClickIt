import Foundation
import Sparkle

/// Central manager for handling app updates using Sparkle framework
@MainActor
class UpdaterManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isUpdateAvailable: Bool = false
    @Published var updateVersion: String?
    @Published var updateBuildNumber: String?
    @Published var updateReleaseNotes: String?
    @Published var isCheckingForUpdates: Bool = false
    @Published var lastUpdateCheck: Date?
    @Published var updateError: String?
    
    // Note: Direct SUAppcastItem storage omitted due to sendability constraints
    
    // MARK: - Private Properties
    private let updaterController: SPUStandardUpdaterController
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Settings
    var autoUpdateEnabled: Bool {
        get { userDefaults.bool(forKey: AppConstants.autoUpdateEnabledKey) }
        set { 
            userDefaults.set(newValue, forKey: AppConstants.autoUpdateEnabledKey)
            configureAutomaticChecks()
        }
    }
    
    var checkForBetaUpdates: Bool {
        get { userDefaults.bool(forKey: AppConstants.checkForBetaUpdatesKey) }
        set { 
            userDefaults.set(newValue, forKey: AppConstants.checkForBetaUpdatesKey)
            // Note: Appcast URL will be configured via Info.plist or separately
        }
    }
    
    // MARK: - Initialization
    override init() {
        // Initialize Sparkle updater controller
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        super.init()
        
        setupUpdater()
        configureAutomaticChecks()
    }
    
    // MARK: - Public Methods
    
    /// Manually check for updates
    func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        
        isCheckingForUpdates = true
        updateError = nil
        
        updaterController.updater.checkForUpdates()
        userDefaults.set(Date(), forKey: AppConstants.lastUpdateCheckKey)
        lastUpdateCheck = Date()
        
        // Reset checking state after a timeout to handle cases where delegate isn't called
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.isCheckingForUpdates = false
        }
    }
    
    /// Trigger the update installation process
    func installUpdate() {
        updaterController.updater.checkForUpdates()
    }
    
    /// Check if an update should be skipped
    func shouldSkipVersion(_ version: String) -> Bool {
        let skippedVersion = userDefaults.string(forKey: AppConstants.skipVersionKey)
        return skippedVersion == version
    }
    
    /// Mark a version to be skipped
    func skipVersion(_ version: String) {
        userDefaults.set(version, forKey: AppConstants.skipVersionKey)
    }
    
    /// Clear skipped version
    func clearSkippedVersion() {
        userDefaults.removeObject(forKey: AppConstants.skipVersionKey)
    }
    
    /// Get the current app version
    var currentVersion: String {
        return AppConstants.appVersion
    }
    
    /// Get time since last update check
    var timeSinceLastCheck: TimeInterval? {
        guard let lastCheck = userDefaults.object(forKey: AppConstants.lastUpdateCheckKey) as? Date else {
            return nil
        }
        return Date().timeIntervalSince(lastCheck)
    }
    
    // MARK: - Private Methods
    
    private func setupUpdater() {
        // Configure updater settings
        updaterController.updater.automaticallyChecksForUpdates = autoUpdateEnabled
        updaterController.updater.updateCheckInterval = AppConstants.updateCheckInterval
        
        // Set appcast URL if not configured in Info.plist
        if updaterController.updater.feedURL == nil {
            updaterController.updater.feedURL = URL(string: AppConstants.appcastURL)
        }
        
        // Set initial defaults if not set
        if !userDefaults.bool(forKey: "hasSetDefaultUpdateSettings") {
            userDefaults.set(true, forKey: AppConstants.autoUpdateEnabledKey)
            userDefaults.set(false, forKey: AppConstants.checkForBetaUpdatesKey)
            userDefaults.set(true, forKey: "hasSetDefaultUpdateSettings")
        }
        
        // Load last update check date
        if let lastCheck = userDefaults.object(forKey: AppConstants.lastUpdateCheckKey) as? Date {
            lastUpdateCheck = lastCheck
        }
    }
    
    private func configureAutomaticChecks() {
        updaterController.updater.automaticallyChecksForUpdates = autoUpdateEnabled
        updaterController.updater.updateCheckInterval = AppConstants.updateCheckInterval
    }
    
    // Note: Appcast URL configuration will be handled via Info.plist
    // or through a different Sparkle configuration method
}

// MARK: - Sparkle Delegate Extensions

extension UpdaterManager: SPUUpdaterDelegate {
    
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        DispatchQueue.main.async {
            self.isCheckingForUpdates = false
            self.isUpdateAvailable = false
            self.updateVersion = nil
            self.updateBuildNumber = nil
            self.updateReleaseNotes = nil
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        // Extract string data to avoid sendability issues
        let version = item.displayVersionString
        let buildNumber = item.versionString
        let releaseNotesURL = item.releaseNotesURL?.absoluteString
        
        DispatchQueue.main.async {
            self.isCheckingForUpdates = false
            self.isUpdateAvailable = true
            self.updateVersion = version
            self.updateBuildNumber = buildNumber
            self.updateReleaseNotes = releaseNotesURL
            // Note: currentUpdateItem is omitted due to sendability constraints
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        DispatchQueue.main.async {
            self.isCheckingForUpdates = false
            self.updateError = error.localizedDescription
        }
    }
}

// MARK: - Update Information Helper

extension UpdaterManager {
    
    /// Format the version information for display
    func formatVersionInfo() -> String {
        guard let version = updateVersion else { return "No update information available" }
        
        if let buildNumber = updateBuildNumber, version != buildNumber {
            return "\(version) (\(buildNumber))"
        } else {
            return version
        }
    }
    
    /// Get release notes as attributed string if available
    func getReleaseNotes() -> AttributedString? {
        guard let releaseNotesURL = updateReleaseNotes,
              let releaseNotesData = releaseNotesURL.data(using: .utf8) else {
            return nil
        }
        
        // Simple plain text conversion - could be enhanced to support HTML/Markdown
        let plainText = String(data: releaseNotesData, encoding: .utf8) ?? "Release notes unavailable"
        return AttributedString(plainText)
    }
    
    /// Check if current version is a beta version
    var isCurrentVersionBeta: Bool {
        return currentVersion.contains("beta") || currentVersion.contains("rc")
    }
}