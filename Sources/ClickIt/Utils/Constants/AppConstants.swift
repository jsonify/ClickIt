import Foundation
import CoreGraphics
import Carbon
import ApplicationServices

enum AppConstants {
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
    
    // App Info
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // Minimum System Requirements
    static let minimumOSVersion = "macOS 15.0"
}

// Framework-specific constants
enum FrameworkConstants {
    // Carbon Framework
    enum CarbonConfig {
        static let escKeyCode: UInt16 = 53
    }
    
    // CoreGraphics
    enum CoreGraphicsConfig {
        static let clickEventType = CGEventType.leftMouseDown
        static let mouseMoveMask = CGEventMask(1 << CGEventType.mouseMoved.rawValue)
    }
}
