import Foundation
import CoreGraphics
import Carbon
import ApplicationServices

struct AppConstants {
    // Window Configuration
    static let defaultWindowWidth: CGFloat = 300
    static let defaultWindowHeight: CGFloat = 200
    
    // Framework Requirements
    static let requiredFrameworks = [
        "CoreGraphics",
        "Carbon",
        "ApplicationServices"
    ]
    
    // Permissions
    static let requiredPermissions = [
        "Accessibility",
        "Screen Recording"
    ]
    
    // Permission URLs
    static let accessibilitySettingsURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    static let screenRecordingSettingsURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    
    // Permission Monitoring
    static let permissionCheckInterval: TimeInterval = 1.0
    
    // App Info
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // Minimum System Requirements
    static let minimumOSVersion = "macOS 15.0"
    
    // Click Engine Configuration
    static let maxClickTimingDeviation: TimeInterval = 0.005 // 5ms
    static let maxClickPositionDeviation: CGFloat = 1.0 // 1 pixel
    static let defaultClickDelay: TimeInterval = 0.01 // 10ms
    static let defaultClickInterval: TimeInterval = 1.0 // 1 second
    static let minClickInterval: TimeInterval = 0.001 // 1ms minimum
    static let maxClickInterval: TimeInterval = 60.0 // 60 seconds maximum
    
    // Performance Limits
    static let maxClicksPerSecond: Double = 100.0
    static let maxConcurrentClicks: Int = 10
    
    // Cache Configuration
    static let processCacheValidityDuration: TimeInterval = 30.0 // 30 seconds
    
    // System Requirements
    static let minimumMemoryRequirementGB: Double = 4.0
    
    // Auto-Update Configuration
    static let appcastURL = "https://jsonify.github.io/clickit/appcast.xml"
    static let updateCheckInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    static let betaAppcastURL = "https://jsonify.github.io/clickit/appcast-beta.xml"
    static let githubReleasesAPI = "https://api.github.com/repos/jsonify/clickit/releases"
    static let githubRepository = "jsonify/clickit"
    
    // Update Settings Keys (UserDefaults)
    static let autoUpdateEnabledKey = "autoUpdateEnabled"
    static let checkForBetaUpdatesKey = "checkForBetaUpdates"
    static let lastUpdateCheckKey = "lastUpdateCheck"
    static let skipVersionKey = "skipVersion"
    
    // Development Update Configuration (Phase 1 MVP)
    struct DeveloperUpdateConfig {
        static let enabled = true
        static let manualCheckOnly = true
        static let skipBetaChannel = true
        static let skipSkipVersion = true
        
        // Build-specific configuration
        #if DEBUG
        static let updateConfigMode = "development"
        static let enableAutomaticChecking = false
        static let showAdvancedOptions = false
        #elseif BETA
        static let updateConfigMode = "beta"
        static let enableAutomaticChecking = true
        static let showAdvancedOptions = true
        static let enableBetaChannel = true
        #else
        static let updateConfigMode = "production"
        static let enableAutomaticChecking = true
        static let showAdvancedOptions = true
        static let enableBetaChannel = false
        #endif
        
        // Private initializer to prevent instantiation
        private init() {}
    }
    
    // Private initializer to prevent instantiation
    private init() {}
}

// Framework-specific constants
struct FrameworkConstants {
    // Carbon Framework
    struct CarbonConfig {
        static let deleteKeyCode: UInt16 = 51  // DELETE/Backspace key
        static let escKeyCode: UInt16 = 53     // ESC key (legacy, avoid using)
        
        // Private initializer to prevent instantiation
        private init() {}
    }
    
    // CoreGraphics
    struct CoreGraphicsConfig {
        static let clickEventType = CGEventType.leftMouseDown
        static let mouseMoveMask = CGEventMask(1 << CGEventType.mouseMoved.rawValue)
        
        // Private initializer to prevent instantiation
        private init() {}
    }
    
    // Private initializer to prevent instantiation
    private init() {}
}
