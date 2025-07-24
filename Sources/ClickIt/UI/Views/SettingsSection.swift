import SwiftUI

enum SettingsSection: String, CaseIterable {
    case clickBehavior
    case timing
    case targeting
    case feedback
    case automation
    case advanced

    var title: String {
        switch self {
        case .clickBehavior: return "Click Behavior"
        case .timing: return "Timing & Duration"
        case .targeting: return "Targeting"
        case .feedback: return "Feedback"
        case .automation: return "Automation"
        case .advanced: return "Advanced"
        }
    }

    var subtitle: String {
        switch self {
        case .clickBehavior: return "Click type and randomization"
        case .timing: return "Duration, timing & randomization"
        case .targeting: return "Application targeting"
        case .feedback: return "Visual and audio feedback"
        case .automation: return "Automation behavior"
        case .advanced: return "Technical settings"
        }
    }

    var icon: String {
        switch self {
        case .clickBehavior: return "cursorarrow.click"
        case .timing: return "clock"
        case .targeting: return "target"
        case .feedback: return "eye"
        case .automation: return "play.rectangle"
        case .advanced: return "gearshape.2"
        }
    }

    var color: Color {
        switch self {
        case .clickBehavior: return .blue
        case .timing: return .green
        case .targeting: return .orange
        case .feedback: return .purple
        case .automation: return .red
        case .advanced: return .gray
        }
    }

    var description: String {
        switch self {
        case .clickBehavior:
            return "Configure mouse click behavior, including click type selection and location randomization for more natural clicking patterns."
        case .timing:
            return "Configure timing intervals, duration controls, and randomization patterns for human-like automation behavior."
        case .targeting:
            return "Configure application targeting and window handling settings for precise automation control."
        case .feedback:
            return "Customize visual and audio feedback options to monitor automation progress and status."
        case .automation:
            return "Configure automation behavior, error handling, and global hotkey controls for reliable operation."
        case .advanced:
            return "Access advanced technical settings, debugging tools, and configuration management options."
        }
    }
}
