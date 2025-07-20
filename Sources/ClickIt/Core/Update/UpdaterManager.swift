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
    @Published var lastCheckResult: String?
    
    // Note: Direct SUAppcastItem storage omitted due to sendability constraints
    
    // MARK: - Private Properties
    private var updaterController: SPUStandardUpdaterController
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
        // Initialize without starting
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        super.init()
        
        // Only start updater if not in manual-only mode
        let shouldStartUpdater: Bool
        #if DEBUG
        shouldStartUpdater = !AppConstants.DeveloperUpdateConfig.manualCheckOnly
        #else
        shouldStartUpdater = true
        #endif
        
        // Recreate with self as delegate after super.init()
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: shouldStartUpdater,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        
        setupUpdater()
        configureAutomaticChecks()
    }
    
    // MARK: - Public Methods
    
    /// Manually check for updates
    func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        
        print("🔄 Starting manual update check...")
        isCheckingForUpdates = true
        updateError = nil
        lastCheckResult = nil
        
        updaterController.updater.checkForUpdates()
        userDefaults.set(Date(), forKey: AppConstants.lastUpdateCheckKey)
        lastUpdateCheck = Date()
        
        // Reset checking state after a timeout to handle cases where delegate isn't called
        // This handles scenarios like empty appcast feeds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.isCheckingForUpdates {
                self.isCheckingForUpdates = false
                self.lastCheckResult = "Current version \(self.currentVersionDetailed) is up to date"
                print("⏰ Update check timed out - assuming up to date")
            }
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
    
    /// Get the current app version with build number
    var currentVersionDetailed: String {
        let version = AppConstants.appVersion
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return version != buildNumber ? "\(version) (\(buildNumber))" : version
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
        // Configure updater settings (will be set by configureAutomaticChecks)
        updaterController.updater.updateCheckInterval = AppConstants.updateCheckInterval
        
        // Log feed URL configuration (will be provided by delegate)
        print("✅ Sparkle configured with delegate feed URL: \(AppConstants.appcastURL)")
        
        // Set initial defaults if not set
        if !userDefaults.bool(forKey: "hasSetDefaultUpdateSettings") {
            // In manual-only mode, disable auto-updates by default
            #if DEBUG
            let defaultAutoUpdate = !AppConstants.DeveloperUpdateConfig.manualCheckOnly
            #else
            let defaultAutoUpdate = true
            #endif
            
            userDefaults.set(defaultAutoUpdate, forKey: AppConstants.autoUpdateEnabledKey)
            userDefaults.set(false, forKey: AppConstants.checkForBetaUpdatesKey)
            userDefaults.set(true, forKey: "hasSetDefaultUpdateSettings")
        }
        
        // Load last update check date
        if let lastCheck = userDefaults.object(forKey: AppConstants.lastUpdateCheckKey) as? Date {
            lastUpdateCheck = lastCheck
        }
    }
    
    private func configureAutomaticChecks() {
        // Disable automatic checks in manual-only mode (debug builds)
        let enableAutomaticChecks: Bool
        #if DEBUG
        enableAutomaticChecks = !AppConstants.DeveloperUpdateConfig.manualCheckOnly && autoUpdateEnabled
        #else
        enableAutomaticChecks = autoUpdateEnabled
        #endif
        
        updaterController.updater.automaticallyChecksForUpdates = enableAutomaticChecks
        updaterController.updater.updateCheckInterval = AppConstants.updateCheckInterval
    }
    
    // Note: Appcast URL configuration will be handled via Info.plist
    // or through a different Sparkle configuration method
}

// MARK: - Sparkle Delegate Extensions

extension UpdaterManager: SPUUpdaterDelegate {
    
    /// Provide the feed URL if not configured in Info.plist
    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        print("🔍 Sparkle requesting feed URL: \(AppConstants.appcastURL)")
        return AppConstants.appcastURL
    }
    
    /// Called when update check begins
    nonisolated func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("📦 Sparkle will install update: \(item.displayVersionString)")
    }
    
    /// Called when update check starts
    nonisolated func updater(_ updater: SPUUpdater, userDidSkipThisVersion item: SUAppcastItem) {
        print("⏭️ User skipped version: \(item.displayVersionString)")
    }
    
    /// Called when appcast download finishes
    nonisolated func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        print("📥 Appcast loaded with \(appcast.items.count) items")
        if appcast.items.isEmpty {
            print("⚠️ Empty appcast - no releases available")
        }
    }
    
    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("✅ Sparkle: No updates found")
        DispatchQueue.main.async {
            self.isCheckingForUpdates = false
            self.isUpdateAvailable = false
            self.updateVersion = nil
            self.updateBuildNumber = nil
            self.updateReleaseNotes = nil
            self.lastCheckResult = "Current version \(self.currentVersionDetailed) is up to date"
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        // Extract string data to avoid sendability issues
        let version = item.displayVersionString
        let buildNumber = item.versionString
        let releaseNotesURL = item.releaseNotesURL?.absoluteString
        let currentVersion = AppConstants.appVersion
        
        print("🆕 Sparkle: Found update \(version)")
        DispatchQueue.main.async {
            self.isCheckingForUpdates = false
            self.isUpdateAvailable = true
            self.updateVersion = version
            self.updateBuildNumber = buildNumber
            self.updateReleaseNotes = releaseNotesURL
            self.lastCheckResult = "Update available: \(self.currentVersionDetailed) → \(version)"
            // Note: currentUpdateItem is omitted due to sendability constraints
        }
    }
    
    nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("❌ Sparkle error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isCheckingForUpdates = false
            self.updateError = error.localizedDescription
            self.lastCheckResult = "Failed to check for updates: \(error.localizedDescription)"
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
