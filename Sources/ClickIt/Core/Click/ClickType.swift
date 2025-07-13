import Foundation
import CoreGraphics

/// Types of mouse clicks supported by the application
enum ClickType: String, CaseIterable {
    case left = "left"
    case right = "right"

    /// CoreGraphics event type for mouse down
    var mouseDownEventType: CGEventType {
        switch self {
        case .left:
            return .leftMouseDown
        case .right:
            return .rightMouseDown
        }
    }

    /// CoreGraphics event type for mouse up
    var mouseUpEventType: CGEventType {
        switch self {
        case .left:
            return .leftMouseUp
        case .right:
            return .rightMouseUp
        }
    }

    /// CoreGraphics mouse button for the click type
    var mouseButton: CGMouseButton {
        switch self {
        case .left:
            return .left
        case .right:
            return .right
        }
    }

    /// A system icon name for the click type.
    var icon: String {
        switch self {
        case .left:
            return "cursorarrow.click"
        case .right:
            return "cursorarrow.click.2"
        }
    }

    /// A description of the click type.
    var description: String {
        switch self {
        case .left:
            return "Simulates a standard primary mouse click."
        case .right:
            return "Simulates a secondary mouse click, often used to open contextual menus."
        }
    }
}

/// Configuration for a mouse click operation
struct ClickConfiguration {
    let type: ClickType
    let location: CGPoint
    let targetPID: pid_t?
    let delayBetweenDownUp: TimeInterval
    
    init(type: ClickType, location: CGPoint, targetPID: pid_t? = nil, delayBetweenDownUp: TimeInterval = 0.01) {
        self.type = type
        self.location = location
        self.targetPID = targetPID
        self.delayBetweenDownUp = delayBetweenDownUp
    }
}

/// Result of a click operation
struct ClickResult {
    let success: Bool
    let actualLocation: CGPoint
    let timestamp: TimeInterval
    let error: ClickError?
    
    init(success: Bool, actualLocation: CGPoint, timestamp: TimeInterval, error: ClickError? = nil) {
        self.success = success
        self.actualLocation = actualLocation
        self.timestamp = timestamp
        self.error = error
    }
}

/// Errors that can occur during click operations
enum ClickError: Error, LocalizedError {
    case invalidLocation
    case eventCreationFailed
    case eventPostingFailed
    case targetProcessNotFound
    case permissionDenied
    case timingConstraintViolation
    
    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Invalid click location specified"
        case .eventCreationFailed:
            return "Failed to create mouse event"
        case .eventPostingFailed:
            return "Failed to post mouse event to system"
        case .targetProcessNotFound:
            return "Target process not found"
        case .permissionDenied:
            return "Permission denied for mouse event generation"
        case .timingConstraintViolation:
            return "Click timing constraint violated"
        }
    }
}