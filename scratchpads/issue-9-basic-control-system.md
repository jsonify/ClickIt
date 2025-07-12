# Issue #9: Basic Control System - Analysis & Implementation Plan

**GitHub Issue**: https://github.com/jsonify/clickit/issues/9

## Current Implementation Analysis

### ✅ Already Implemented Features

1. **Start/stop buttons in UI** 
   - Location: `ConfigurationPanel.swift:253-275`
   - Implementation: Toggle between start/stop buttons based on `clickCoordinator.isActive`
   - Status: ✅ Complete

2. **Click counter display**
   - Location: `StatisticsView.swift:19`
   - Implementation: Shows `clickCoordinator.clickCount`
   - Status: ✅ Complete

3. **Manual stop functionality**
   - Location: `ConfigurationPanel.swift:350-352`
   - Implementation: `stopAutomation()` method calls `clickCoordinator.stopAutomation()`
   - Status: ✅ Complete

4. **Basic error handling and user feedback**
   - Location: `ClickCoordinator.swift:190-198`
   - Implementation: Error handling with `stopOnError` configuration option
   - Status: ✅ Complete

5. **Automatic stopping when click count reached**
   - Location: `ClickCoordinator.swift:206-211`
   - Implementation: Checks `maxClicks` limit and stops automation
   - Status: ✅ Complete

### ❌ Missing Features

1. **Elapsed time display**
   - Current: StatisticsView shows clicks, success rate, avg click time
   - Missing: Session elapsed time display
   - Impact: Users can't see how long automation has been running

2. **Automatic stopping when time duration reached**
   - Current: UI has timeLimit mode in DurationMode enum
   - Missing: AutomationConfiguration doesn't support time duration limits
   - Missing: ClickCoordinator automation loop doesn't check time limits
   - Impact: Users can set time limits in UI but they don't work

## Implementation Plan

### Task 1: Add Elapsed Time Display to StatisticsView

**Changes needed:**
- Add elapsed time calculation to StatisticsView
- Display formatted elapsed time (e.g., "1m 23s")
- Use `clickCoordinator.sessionStartTime` for calculation

### Task 2: Implement Time-Based Duration Stopping

**Changes needed:**

1. **Extend AutomationConfiguration**
   - Add `maxDuration: TimeInterval?` property
   - Update initializer to accept maxDuration parameter

2. **Update ClickSettings.createAutomationConfiguration()**
   - Pass `durationSeconds` when `durationMode == .timeLimit`
   - Convert seconds to TimeInterval for maxDuration

3. **Enhance ClickCoordinator automation loop**
   - Track session start time in automation loop
   - Check elapsed time against maxDuration limit
   - Stop automation when time limit reached

## Implementation Approach

### Non-Complex Solutions

1. **For elapsed time display**: Calculate from existing sessionStartTime
2. **For time duration stopping**: Reuse existing stopping mechanism pattern (similar to maxClicks)

### Files to Modify

1. `Sources/ClickIt/UI/Components/StatisticsView.swift` - Add elapsed time display
2. `Sources/ClickIt/Core/Click/ClickCoordinator.swift` - Add time duration support
3. `Sources/ClickIt/Core/Models/ClickSettings.swift` - Update configuration creation

### Testing Strategy

1. Test elapsed time display updates correctly during automation
2. Test time-based stopping works with various durations (1s, 30s, 2m)
3. Test UI correctly shows time limit configuration
4. Test integration with existing click count and unlimited modes

## Complexity Assessment

- **Low complexity**: Both features use existing patterns and infrastructure
- **Time estimate**: 1-2 hours total implementation
- **Risk level**: Low - no breaking changes to existing functionality