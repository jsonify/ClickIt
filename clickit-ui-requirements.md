# ClickIt UI Requirements - SwiftUI Implementation

## Overview
This document outlines the updated UI requirements for ClickIt, a macOS auto-clicker application, designed for implementation using SwiftUI in Xcode. The interface has been redesigned to be more streamlined, user-friendly, and organized into logical groupings.

## Design Philosophy
- **Simplicity First**: Core functionality prominently displayed, advanced features tucked away
- **Native macOS Feel**: Consistent with macOS design patterns using SwiftUI components
- **Efficient Workflow**: Minimal clicks from launch to operation
- **Progressive Disclosure**: Advanced settings revealed only when needed

---

## UI Structure & Layout

### Main Window Configuration
```swift
// Window Properties
- Fixed size: 400x800 points (approximate)
- Minimum macOS version: 15.0+
- Resizable: false
- Background: System gray (dark mode compatible)
```

### Color Scheme
- **Primary Background**: `.gray900` equivalent (`Color(.systemGray6)`)
- **Card Background**: `.gray800` equivalent (`Color(.systemGray5)`)
- **Accent Color**: Blue (`Color.accentColor`)
- **Text Primary**: White (`Color.primary`)
- **Text Secondary**: Gray (`Color.secondary`)

---

## Component Breakdown

### 1. Status Card (`VStack` with `RoundedRectangle`)

**SwiftUI Components:**
- `VStack` with padding
- `HStack` for header with app icon and status
- `LazyVGrid` for statistics (3 columns)
- Primary action `Button` with SF Symbols

**Layout:**
```swift
VStack(spacing: 16) {
    // Header with icon, title, and status indicator
    HStack {
        Image(systemName: "target")
            .foregroundColor(.blue)
        Text("ClickIt")
            .font(.title2.bold())
        Spacer()
        HStack {
            Circle().fill(.green).frame(width: 8, height: 8)
            Text("Ready").foregroundColor(.green)
        }
    }
    
    // Statistics Grid
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
        StatisticView(value: "96", label: "Clicks")
        StatisticView(value: "8s", label: "Elapsed") 
        StatisticView(value: "98%", label: "Success")
    }
    
    // Primary Action Button
    Button(action: toggleAutomation) {
        Label(isRunning ? "Stop Automation" : "Start Automation", 
              systemImage: isRunning ? "stop.fill" : "play.fill")
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
}
.padding()
.background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
```

**Requirements:**
- Status indicator changes color based on app state
- Statistics update in real-time during operation
- Primary button changes appearance and icon when running
- Use SF Symbols for all icons

---

### 2. Target Point Selection (`GroupBox`)

**SwiftUI Components:**
- `GroupBox` with custom label
- `HStack` for coordinate display with status indicator
- `HStack` for action buttons

**Layout:**
```swift
GroupBox {
    VStack(spacing: 12) {
        HStack {
            Text("Position: X: \(targetPoint.x), Y: \(targetPoint.y)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Circle().fill(.green).frame(width: 8, height: 8)
        }
        
        HStack(spacing: 8) {
            Button("Click to Set Point") { setPointMode() }
                .buttonStyle(.borderedProminent)
            Button("Manual Input") { showManualInput() }
                .buttonStyle(.bordered)
        }
    }
} label: {
    Label("Target Point", systemImage: "target")
        .font(.headline)
}
```

**Requirements:**
- Real-time coordinate display
- Visual feedback for point selection state
- Modal sheet for manual coordinate input
- Accessibility labels for VoiceOver support

---

### 3. Configuration Section (`Form` within `GroupBox`)

**SwiftUI Components:**
- `GroupBox` container
- Custom click interval component with `HStack` of `TextField`s
- Real-time calculation display

**Click Interval Component:**
```swift
GroupBox {
    VStack(spacing: 12) {
        Label("Click Interval", systemImage: "clock")
            .font(.headline)
        
        HStack(spacing: 8) {
            TimeInputField(value: $hours, label: "Hours", range: 0...23)
            TimeInputField(value: $minutes, label: "Mins", range: 0...59)
            TimeInputField(value: $seconds, label: "Secs", range: 0...59)
            TimeInputField(value: $milliseconds, label: "Ms", range: 0...999)
        }
        
        HStack {
            Text("Total: \(totalMilliseconds)ms")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text("~\(String(format: "%.2f", cps)) CPS")
                .font(.caption.weight(.medium))
                .foregroundColor(.blue)
        }
    }
}
.background(RoundedRectangle(cornerRadius: 8).stroke(.blue.opacity(0.3)))
```

**Custom TimeInputField:**
```swift
struct TimeInputField: View {
    @Binding var value: Int
    let label: String
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            TextField("0", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
    }
}
```

**Requirements:**
- Live calculation of total milliseconds and CPS
- Input validation with range limits
- Highlighted border to emphasize importance
- Responsive layout for different window sizes

---

### 4. Advanced Settings (`DisclosureGroup`)

**SwiftUI Components:**
- `DisclosureGroup` for expandable section
- `Form` for organized settings
- Custom toggle switches and pickers

**Layout Structure:**
```swift
DisclosureGroup {
    Form {
        Section("Click Configuration") {
            Picker("Click Type", selection: $clickType) {
                Text("Left Click").tag(ClickType.left)
                Text("Right Click").tag(ClickType.right)
            }
            .pickerStyle(.segmented)
        }
        
        Section("Duration Control") {
            Picker("Duration Mode", selection: $durationMode) {
                Text("Unlimited").tag(DurationMode.unlimited)
                Text("Time Limit").tag(DurationMode.timeLimit)
                Text("Click Count").tag(DurationMode.clickCount)
            }
            .pickerStyle(.segmented)
            
            // Conditional content based on duration mode
            switch durationMode {
            case .timeLimit:
                TimeConfigurationView()
            case .clickCount:
                ClickCountConfigurationView()
            default:
                EmptyView()
            }
        }
        
        Section("Randomization") {
            Toggle("Randomize Location", isOn: $randomizeLocation)
            
            if randomizeLocation {
                VStack {
                    Text("Variance: \(variance)px")
                    Slider(value: $variance, in: 0...50, step: 1)
                }
            }
        }
        
        Section("Feedback") {
            Toggle("Visual Feedback", isOn: $visualFeedback)
            Toggle("Sound Feedback", isOn: $soundFeedback)
            Toggle("Stop on Error", isOn: $stopOnError)
        }
        
        Section("Quick Actions") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                Button("Reset to Defaults") { resetToDefaults() }
                Button("Save Preset") { savePreset() }
                Button("Load Preset") { loadPreset() }
                Button("Export Config") { exportConfig() }
            }
            .buttonStyle(.bordered)
        }
    }
} label: {
    Label("Advanced Settings", systemImage: "gearshape")
        .font(.headline)
}
```

**Requirements:**
- Smooth expand/collapse animation
- Conditional UI based on selected options
- Consistent button styling throughout
- Proper form grouping with section headers

---

### 5. Footer Information

**SwiftUI Components:**
- Simple `HStack` with app version and hotkey info

```swift
HStack {
    Spacer()
    Text("ESC to start/stop • v1.0.0")
        .font(.caption2)
        .foregroundColor(.secondary)
    Spacer()
}
.padding(.vertical, 8)
```

---

## Data Models

### Core Data Structures
```swift
enum ClickType: String, CaseIterable {
    case left = "left"
    case right = "right"
}

enum DurationMode: String, CaseIterable {
    case unlimited = "unlimited"
    case timeLimit = "timeLimit" 
    case clickCount = "clickCount"
}

struct TargetPoint {
    var x: Int
    var y: Int
}

struct ClickConfiguration {
    var targetPoint: TargetPoint
    var clickType: ClickType
    var intervalHours: Int
    var intervalMinutes: Int
    var intervalSeconds: Int
    var intervalMilliseconds: Int
    var durationMode: DurationMode
    var timeLimit: TimeInterval?
    var clickCountLimit: Int?
    var randomizeLocation: Bool
    var variance: Double
    var visualFeedback: Bool
    var soundFeedback: Bool
    var stopOnError: Bool
}

struct SessionStatistics {
    var clickCount: Int
    var elapsedTime: TimeInterval
    var successRate: Double
}
```

---

## State Management

### ObservableObject ViewModel
```swift
@MainActor
class ClickItViewModel: ObservableObject {
    @Published var configuration = ClickConfiguration()
    @Published var statistics = SessionStatistics()
    @Published var isRunning = false
    @Published var appStatus: AppStatus = .ready
    @Published var showAdvancedSettings = false
    
    // Computed properties
    var totalMilliseconds: Int {
        configuration.intervalHours * 3600000 +
        configuration.intervalMinutes * 60000 +
        configuration.intervalSeconds * 1000 +
        configuration.intervalMilliseconds
    }
    
    var estimatedCPS: Double {
        totalMilliseconds > 0 ? 1000.0 / Double(totalMilliseconds) : 0
    }
}
```

---

## Accessibility Requirements

### VoiceOver Support
- All interactive elements must have accessibility labels
- Complex controls need accessibility hints
- Statistics should be announced when updated
- Toggle states clearly communicated

### Keyboard Navigation
- Full keyboard navigation support
- Custom focus management for complex components
- Escape key handling for global start/stop

### Reduced Motion
- Respect `@Environment(\.accessibilityReduceMotion)`
- Provide alternative feedback when animations are disabled

---

## Animation & Transitions

### Smooth Transitions
```swift
.animation(.easeInOut(duration: 0.3), value: showAdvancedSettings)
.transition(.opacity.combined(with: .scale(scale: 0.95)))
```

### State Changes
- Button state changes with smooth color transitions
- Statistics counter animations
- Status indicator pulsing during operation
- Disclosure group expand/collapse

---

## Performance Considerations

### SwiftUI Best Practices
- Use `@State` for local UI state
- Use `@StateObject` for view model instances
- Implement `Equatable` for complex data types to optimize redraws
- Use `LazyVGrid` for grids to improve performance

### Memory Management
- Proper cleanup of timers and observers
- Weak references where appropriate
- Efficient image loading for icons

---

## Testing Requirements

### Unit Tests
- ViewModel logic testing
- Configuration validation
- Calculation accuracy (CPS, intervals)

### UI Tests
- Navigation flow testing
- Accessibility testing
- State persistence testing
- Form validation testing

### Manual Testing Checklist
- [ ] All buttons respond correctly
- [ ] Advanced settings expand/collapse smoothly
- [ ] Time calculations are accurate
- [ ] VoiceOver navigation works properly
- [ ] Keyboard shortcuts function correctly
- [ ] App handles edge cases gracefully

---

## Implementation Notes

### Development Environment
- **Xcode Version**: 15.0+
- **macOS Deployment Target**: 15.0+
- **SwiftUI Version**: iOS 17.0+ / macOS 14.0+ features
- **Architecture**: MVVM with SwiftUI

### Third-Party Dependencies
- None required for UI implementation
- Consider SwiftUI introspection for advanced customization if needed

### Localization
- All user-facing strings should be localized
- Use `String(localized:)` for text
- Support for RTL languages where applicable