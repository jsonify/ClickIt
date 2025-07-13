# Issue #46: Auto Click Timer Mode Implementation Plan

**GitHub Issue**: https://github.com/jsonify/clickit/issues/46

## 📋 Issue Summary

Implement a new "Auto Click Timer Mode" that allows users to:
1. Start a configurable countdown timer (1 second to 60 minutes)
2. Position their cursor anywhere during the countdown
3. Automatically begin clicking at the cursor's final position when timer expires
4. Use all existing click configuration options (CPS, duration, click type, etc.)

This eliminates the need to pre-select coordinates for dynamic clicking scenarios.

---

## 🏗️ Architecture Analysis

Based on codebase research, the current architecture is well-suited for this feature:

### **Existing Infrastructure ✅**
- **ClickCoordinator**: Already handles automation sessions with duration limits and precise timing
- **ClickItViewModel**: Manages published state for UI binding and automation configuration  
- **AutomationConfiguration**: Supports time-based limits and click constraints
- **Timer Systems**: `PermissionManager` already uses `Timer.scheduledTimer()` for monitoring

### **Integration Points**
- **TargetPointSelectionCard**: Will gain third option alongside "Click to Set" and "Manual Input"
- **ClickItViewModel**: Add timer state properties and countdown management
- **Existing Automation Flow**: Timer mode will be pre-automation phase before calling `ClickCoordinator.startAutomation()`

---

## 🎨 UI Design Specification

### **Enhanced TargetPointSelectionCard**

**Current Options:**
- "Click to Set Point" (immediate coordinate capture)
- "Manual Input" (exact X/Y entry)

**New Addition:**
- **"Auto Click Timer"** button that opens timer configuration interface

### **Timer Configuration Interface**
```
┌─────────────────────────────────────┐
│ 🕐 Auto Click Timer Mode             │
├─────────────────────────────────────┤
│ Timer Duration:                     │
│ [5] minutes [30] seconds            │
│                                     │
│ ⚡ Start Timer & Auto Click          │
│                                     │
│ 💡 Position cursor where you want   │
│    clicking to start, then wait...  │
└─────────────────────────────────────┘
```

### **Active Timer Display**
```
┌─────────────────────────────────────┐
│ ⏰ Starting Auto Click in...         │
│                                     │
│           00:05:23                  │
│                                     │
│ 🎯 Move cursor to target location   │
│ 🛑 Cancel Timer                     │
└─────────────────────────────────────┘
```

---

## 🔧 Technical Implementation Plan

### **Phase 1: ViewModel State Management**

#### **New Published Properties in ClickItViewModel**
```swift
// MARK: - Timer Mode Properties
@Published var timerMode: TimerMode = .off
@Published var timerDurationMinutes: Int = 0
@Published var timerDurationSeconds: Int = 10  
@Published var isCountingDown: Bool = false
@Published var remainingTime: TimeInterval = 0
@Published var timerIsActive: Bool = false

enum TimerMode {
    case off          // Normal immediate automation
    case countdown    // Timer mode with countdown
}
```

#### **Timer Management Methods**
```swift
// MARK: - Timer Mode Methods
func startTimerMode(durationMinutes: Int, durationSeconds: Int) {
    let totalSeconds = durationMinutes * 60 + durationSeconds
    remainingTime = TimeInterval(totalSeconds)
    isCountingDown = true
    timerIsActive = true
    timerMode = .countdown
    
    startCountdownTimer()
}

func cancelTimer() {
    countdownTimer?.invalidate()
    countdownTimer = nil
    resetTimerState()
}

private func onTimerExpired() {
    // Capture current cursor position
    let currentPosition = CGEvent.mouseLocation()
    setTargetPoint(currentPosition)
    
    // Reset timer state
    resetTimerState()
    
    // Start automation with existing flow
    startAutomation()
}

private func resetTimerState() {
    isCountingDown = false
    timerIsActive = false
    remainingTime = 0
    timerMode = .off
}
```

### **Phase 2: UI Components**

#### **Enhanced TargetPointSelectionCard**
- Add "Auto Click Timer" button alongside existing options
- Show timer configuration interface when selected
- Display countdown UI when timer is active
- Handle timer cancellation

#### **Timer Configuration Component**
```swift
struct TimerConfigurationView: View {
    @ObservedObject var viewModel: ClickItViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🕐 Auto Click Timer Mode")
                .font(.headline)
            
            HStack {
                Text("Timer Duration:")
                Spacer()
                
                TextField("Min", value: $viewModel.timerDurationMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("minutes")
                
                TextField("Sec", value: $viewModel.timerDurationSeconds, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("seconds")
            }
            
            Button("⚡ Start Timer & Auto Click") {
                viewModel.startTimerMode(
                    durationMinutes: viewModel.timerDurationMinutes,
                    durationSeconds: viewModel.timerDurationSeconds
                )
            }
            .buttonStyle(.borderedProminent)
            
            Text("💡 Position cursor where you want clicking to start, then wait...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
```

#### **Active Timer Display Component**
```swift
struct ActiveTimerView: View {
    @ObservedObject var viewModel: ClickItViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("⏰ Starting Auto Click in...")
                .font(.headline)
            
            Text(timeString(from: viewModel.remainingTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
            
            Text("🎯 Move cursor to target location")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("🛑 Cancel Timer") {
                viewModel.cancelTimer()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

### **Phase 3: Timer Integration**

#### **Countdown Timer Implementation**
```swift
// In ClickItViewModel
private var countdownTimer: Timer?

private func startCountdownTimer() {
    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
        guard let self = self else {
            timer.invalidate()
            return
        }
        
        DispatchQueue.main.async {
            self.remainingTime -= 1.0
            
            if self.remainingTime <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                self.onTimerExpired()
            }
        }
    }
}
```

#### **Enhanced startAutomation Method**
```swift
func startAutomation() {
    // If timer mode is active, start timer instead of immediate automation
    if timerMode == .countdown && !isCountingDown {
        startTimerMode(
            durationMinutes: timerDurationMinutes, 
            durationSeconds: timerDurationSeconds
        )
        return
    }
    
    // Existing automation logic
    guard let target = targetPoint else { return }
    guard canStartAutomation else { return }
    
    // ... rest of existing startAutomation logic
}
```

### **Phase 4: Enhanced TargetPointSelectionCard Integration**

#### **Updated Card Structure**
```swift
struct TargetPointSelectionCard: View {
    @ObservedObject var viewModel: ClickItViewModel
    @State private var showingTimerMode = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Existing coordinate display and validation
            coordinateDisplay
            
            // Target point selection options
            if viewModel.isCountingDown {
                ActiveTimerView(viewModel: viewModel)
            } else if showingTimerMode {
                TimerConfigurationView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                targetSelectionOptions
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var targetSelectionOptions: some View {
        VStack(spacing: 12) {
            // Existing "Click to Set Point" button
            clickToSetButton
            
            // New "Auto Click Timer" button  
            Button("🕐 Auto Click Timer") {
                withAnimation {
                    showingTimerMode = true
                }
            }
            .buttonStyle(.bordered)
            
            // Existing manual input section
            manualInputSection
        }
    }
}
```

---

## ✅ Acceptance Criteria Implementation

### **Functional Requirements**
- [x] **Timer Configuration**: Minutes/seconds input with 1s-60min range
- [x] **Real-time Countdown**: MM:SS format display with 1-second updates
- [x] **Cursor Position Capture**: `CGEvent.mouseLocation()` at timer expiration
- [x] **Timer Cancellation**: Cancel button and ESC hotkey support (via existing hotkey system)
- [x] **Existing Settings Integration**: All current click settings work with timer mode
- [x] **Visual/Audio Feedback**: Inherits from existing feedback system

### **UI/UX Requirements**
- [x] **Clear State Distinction**: Separate UI for configuration vs. active timer
- [x] **Intuitive Controls**: Minutes/seconds input fields with validation
- [x] **Helpful Guidance**: Clear instructions during countdown
- [x] **Smooth Transitions**: Animation between timer states
- [x] **Consistent Styling**: Matches existing ClickIt design system

### **Technical Requirements**
- [x] **Timer Accuracy**: 1-second granularity using `Timer.scheduledTimer`
- [x] **Precise Cursor Capture**: `CGEvent.mouseLocation()` for exact coordinates
- [x] **No Interference**: Timer mode is additive to existing functionality
- [x] **Resource Cleanup**: Proper timer invalidation on cancellation/completion
- [x] **Background Operation**: Timer works when ClickIt window not focused

---

## 🎛️ Configuration & Validation

### **Timer Duration Validation**
```swift
// In ClickItViewModel
var totalTimerSeconds: Int {
    timerDurationMinutes * 60 + timerDurationSeconds
}

var isValidTimerDuration: Bool {
    let total = totalTimerSeconds
    return total >= 1 && total <= 3600 // 1 second to 60 minutes
}
```

### **Default Values**
- **Default Timer**: 10 seconds (0 minutes, 10 seconds)
- **Minimum Duration**: 1 second
- **Maximum Duration**: 60 minutes (3600 seconds)

### **Integration with Existing Features**
- **Presets**: Timer configurations can be saved with preset system
- **Global Hotkeys**: ESC key will cancel active timer (extend existing hotkey handler)
- **Statistics**: Timer countdown time excluded from session statistics
- **Visual Feedback**: Timer expiration triggers existing visual feedback overlay

---

## 🔧 Implementation Steps

### **Step 1: ViewModel Enhancement** ⭐ *Start Here*
1. Add timer-related `@Published` properties to `ClickItViewModel`
2. Implement timer management methods (`startTimerMode`, `cancelTimer`, etc.)
3. Add timer duration validation logic
4. Enhance `startAutomation()` method to handle timer mode

### **Step 2: UI Components**
1. Create `TimerConfigurationView` component
2. Create `ActiveTimerView` component  
3. Add timer formatting utility functions
4. Test components in isolation with preview

### **Step 3: TargetPointSelectionCard Integration**
1. Add "Auto Click Timer" button to existing options
2. Integrate timer configuration and active timer views
3. Add smooth transitions between states
4. Update card layout to accommodate new UI states

### **Step 4: Timer System Implementation**
1. Implement countdown timer with `Timer.scheduledTimer`
2. Add cursor position capture logic using `CGEvent.mouseLocation()`
3. Integrate timer expiration with existing automation flow
4. Add proper timer cleanup and error handling

### **Step 5: Testing & Validation**
1. Test timer accuracy and countdown display
2. Verify cursor position capture precision
3. Test integration with all existing click settings
4. Validate timer cancellation and ESC hotkey
5. Test edge cases (system sleep, app focus loss, etc.)

### **Step 6: Documentation & Polish**
1. Update user-facing documentation
2. Add helpful tooltips and guidance text
3. Ensure consistent visual styling
4. Performance testing and optimization

---

## 🔍 Edge Cases & Error Handling

### **System Integration**
- **App Focus Loss**: Timer continues running in background
- **System Sleep**: Timer pauses and resumes with system (standard `Timer` behavior)
- **Invalid Cursor Position**: Validate cursor is within screen bounds before automation

### **User Experience**
- **Timer During Automation**: Prevent starting timer while automation is active
- **Multiple Timers**: Only one timer active at a time (cancel existing before starting new)
- **Cursor Over ClickIt App**: Valid scenario - clicking will occur on ClickIt window

### **Error Recovery**
```swift
private func onTimerExpired() {
    defer { resetTimerState() }
    
    let currentPosition = CGEvent.mouseLocation()
    
    // Validate cursor position is within screen bounds
    let screenBounds = NSScreen.main?.frame ?? CGRect.zero
    guard screenBounds.contains(currentPosition) else {
        // Show error message to user
        appStatus = .error("Invalid cursor position when timer expired")
        return
    }
    
    setTargetPoint(currentPosition)
    startAutomation()
}
```

---

## 🎯 Success Metrics

### **Functional Success**
- Timer countdown displays accurately with 1-second precision
- Cursor position captured exactly when timer expires
- All existing click settings work seamlessly with timer mode
- Timer can be cancelled via UI button and ESC hotkey

### **User Experience Success**  
- Intuitive timer configuration with clear duration input
- Smooth UI transitions between timer states
- Helpful guidance text during countdown phase
- Consistent visual design matching existing ClickIt aesthetic

### **Technical Success**
- No interference with existing immediate automation functionality
- Proper timer resource cleanup on cancellation/completion
- Timer operates correctly when app is not focused
- Integration with existing hotkey and feedback systems

---

**Implementation Priority**: High - Significantly improves user workflow
**Effort Estimate**: Medium - Primarily UI changes leveraging existing automation infrastructure  
**Dependencies**: None - Purely additive feature using current systems

This implementation plan provides a comprehensive roadmap for adding Auto Click Timer Mode while maintaining the robustness and usability of the existing ClickIt application.