// swiftlint:disable file_header
import Foundation
import CoreGraphics
import AppKit

/// Utility functions for coordinate system conversions between AppKit and CoreGraphics
/// with proper multi-monitor support
struct CoordinateUtils {
    
    // MARK: - AppKit to CoreGraphics Conversion
    
    /// Converts AppKit coordinates to CoreGraphics coordinates for multi-monitor setups
    /// - Parameter appKitPosition: Position in AppKit coordinate system (Y increases upward from screen bottom)
    /// - Returns: Position in CoreGraphics coordinate system (Y increases downward from screen top)
    static func convertAppKitToCoreGraphics(_ appKitPosition: CGPoint) -> CGPoint {
        // Find which screen contains this point
        for screen in NSScreen.screens {
            if screen.frame.contains(appKitPosition) {
                // FIXED: Proper multi-monitor coordinate conversion
                // AppKit Y increases upward from screen bottom
                // CoreGraphics Y increases downward from screen top  
                // Formula: CG_Y = screen.origin.Y + (screen.height - (AppKit_Y - screen.origin.Y))
                let relativeY = appKitPosition.y - screen.frame.origin.y  // Y relative to screen bottom
                let cgY = screen.frame.origin.y + (screen.frame.height - relativeY)  // Convert to CG coordinates
                let cgPosition = CGPoint(x: appKitPosition.x, y: cgY)
                
                print("[CoordinateUtils] Multi-monitor conversion: AppKit \(appKitPosition) → CoreGraphics \(cgPosition) on screen \(screen.frame)")
                print("[CoordinateUtils] Calculation: relativeY=\(relativeY), cgY=\(screen.frame.origin.y) + (\(screen.frame.height) - \(relativeY)) = \(cgY)")
                
                return cgPosition
            }
        }
        
        // Fallback to main screen if no screen contains the point
        let mainScreenHeight = NSScreen.main?.frame.height ?? 0
        let fallbackPosition = CGPoint(x: appKitPosition.x, y: mainScreenHeight - appKitPosition.y)
        print("[CoordinateUtils] Fallback conversion: AppKit \(appKitPosition) → CoreGraphics \(fallbackPosition)")
        return fallbackPosition
    }
    
    // MARK: - CoreGraphics to AppKit Conversion
    
    /// Converts CoreGraphics coordinates back to AppKit coordinates for multi-monitor setups
    /// - Parameter cgPosition: Position in CoreGraphics coordinate system (Y increases downward from screen top)
    /// - Returns: Position in AppKit coordinate system (Y increases upward from screen bottom)
    static func convertCoreGraphicsToAppKit(_ cgPosition: CGPoint) -> CGPoint {
        // Find which screen this CoreGraphics position would map to
        // This is a reverse lookup - we need to find the screen that would contain the original AppKit position
        for screen in NSScreen.screens {
            // Check if this position could have come from this screen
            let potentialAppKitY = screen.frame.maxY - cgPosition.y
            let potentialAppKitPosition = CGPoint(x: cgPosition.x, y: potentialAppKitY)
            
            if screen.frame.contains(potentialAppKitPosition) {
                print("[CoordinateUtils] CoreGraphics \(cgPosition) → AppKit \(potentialAppKitPosition) on screen \(screen.frame)")
                return potentialAppKitPosition
            }
        }
        
        // Fallback to main screen conversion
        let mainScreenHeight = NSScreen.main?.frame.height ?? 0
        let fallbackPosition = CGPoint(x: cgPosition.x, y: mainScreenHeight - cgPosition.y)
        print("[CoordinateUtils] Fallback reverse conversion: CoreGraphics \(cgPosition) → AppKit \(fallbackPosition)")
        return fallbackPosition
    }
    
    // MARK: - Multi-Monitor Support Functions
    
    /// Checks if a position is within any available screen bounds
    /// - Parameter position: Position to check (in AppKit coordinates)
    /// - Returns: True if position is within any screen bounds
    static func isPositionWithinAnyScreen(_ position: CGPoint) -> Bool {
        for screen in NSScreen.screens {
            if screen.frame.contains(position) {
                print("[CoordinateUtils] Position \(position) is valid on screen: \(screen.frame)")
                return true
            }
        }
        print("[CoordinateUtils] Position \(position) is not within any screen bounds")
        return false
    }
    
    /// Gets all available screen frames for debugging purposes
    /// - Returns: Array of all screen frames
    static func getAllScreenFrames() -> [CGRect] {
        return NSScreen.screens.map { $0.frame }
    }
    
    /// Gets the main screen frame
    /// - Returns: Main screen frame, or zero rect if unavailable
    static func getMainScreenFrame() -> CGRect {
        return NSScreen.main?.frame ?? CGRect.zero
    }
}