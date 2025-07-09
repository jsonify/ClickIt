# Clickit - Product Requirements Document

## Overview
A lightweight, native macOS auto-clicker application designed for efficient task automation, supporting both Intel and Apple Silicon architectures. Clickit provides precise, configurable mouse control for any application that requires repetitive clicking actions.

## Core Requirements

### Functional Requirements

#### Click Functionality
- **Single Point Clicking**: Click at one user-defined coordinate (small tolerance acceptable)
- **Click Types**: Left click and right click support
- **Timing Options**:
  - Constant interval (default mode)
  - Variable interval: Randomly varies between (Base CPS - N) and (Base CPS + N)
  - Example: 5 CPS ± 2 = random variation between 3-7 CPS
- **Mouse Only**: No keyboard input simulation required

#### User Interface
- **Platform**: Native macOS application using SwiftUI
- **Design**: Simple, clean interface optimized for ease of use
- **Click Point Selection**: Click-to-set point mechanism
- **Visual Feedback**: Small circle overlay showing selected click point (visible during setup and active clicking)
- **Target Window Display**: Shows name of currently targeted application window
- **Configuration Panel**: Settings for:
  - Click interval (milliseconds)
  - Number of clicks or duration
  - Click type (left/right)
  - Variable timing patterns

#### Automation Controls
- **Duration Control**: Time-based stopping mechanism
- **Hotkey Support**: ESC key to start/stop/pause operations
- **Background Operation**: Clicks on target application window without requiring foreground focus
- **Window Targeting**: Automatically detects and targets application windows when clicked
- **Minimized Window Support**: Continues clicking even when target window is minimized/hidden

#### Advanced Features
- **Preset Configurations**: 5 user-named presets for different clicking patterns with custom naming
- **Conditional Logic**: Support for screen content-based clicking decisions
- **Randomization**: Human-like click timing variations

### Technical Requirements

#### Platform Support
- **macOS Version**: 15.0 or later
- **Architecture**: Universal binary (Intel x64 + Apple Silicon)
- **Development Stack**: 
  - Swift/SwiftUI for UI
  - Native macOS APIs for mouse events
  - Combine for reactive programming

#### Performance
- **Resource Usage**: Lightweight, minimal CPU/memory footprint
- **Responsiveness**: Sub-10ms click timing accuracy
- **Stability**: No interference with target applications

#### Distribution
- **Primary**: Personal use
- **Secondary**: Potential Homebrew distribution
- **Code Signing**: Basic signing for personal use

## User Experience Flow

### Initial Setup
1. Launch application
2. Position over Roblox game
3. Click to set target point
4. Configure click parameters
5. Start automation with ESC key

### Configuration Management
1. Access settings panel
2. Adjust timing, click type, duration
3. Save as preset for future use
4. Load existing presets

### Operation Control
1. ESC key toggles start/stop/pause
2. Visual feedback shows active status
3. Background operation continues without focus
4. Automatic stop when duration reached

## Technical Architecture

### Core Components
- **Click Engine**: Native macOS mouse event generation with window targeting
- **UI Layer**: SwiftUI-based configuration interface with target window display
- **Hotkey Handler**: Global keyboard event monitoring
- **Preset Manager**: 5-slot configuration save/load system with custom naming
- **Timer System**: Precise interval management with CPS range randomization
- **Window Manager**: Roblox window detection and targeting system (supports minimized windows)

### Security Considerations
- **Accessibility Permissions**: Required for mouse event simulation
- **Screen Recording**: Required for window detection and visual overlay
- **Window Management**: Required for clicking on minimized/background windows
- **Sandboxing**: Minimal permissions for personal use

### APIs and Frameworks
- **Core Graphics**: Mouse event generation and window targeting
- **Carbon**: Global hotkey registration
- **SwiftUI**: User interface
- **Combine**: Reactive state management
- **ApplicationServices**: Window detection and management

## Technical Implementation Notes

### Window Targeting Implementation
- **Window Detection**: Use `CGWindowListCopyWindowInfo` to detect and enumerate application windows
- **Background Clicking**: Implement `CGEventCreateMouseEvent` with `CGEventPostToPid` to send clicks to specific processes
- **Minimized Window Support**: Target process ID rather than window focus to enable clicking on minimized/hidden windows

### CPS Randomization Implementation
- **Timer System**: Implement dynamic timer that recalculates intervals based on randomized CPS values
- **Range Calculation**: `minCPS = baseCPS - variation` and `maxCPS = baseCPS + variation`
- **Random Interval**: Generate random values within range using `random(minCPS, maxCPS)` for each click cycle

### Persistent Visual Overlay Implementation
- **Overlay Window**: Use `NSWindow` with `NSWindowLevel.floating` to create transparent overlay
- **Circle Rendering**: Custom view with Core Graphics circle drawing that remains visible during operation
- **Window Coordination**: Ensure overlay stays positioned correctly relative to target window

### Custom Preset Management Implementation
- **Data Structure**: Store presets as dictionary with user-provided keys and configuration values
- **Persistence**: Use `UserDefaults` or Core Data for preset storage and retrieval
- **Validation**: Implement name validation and duplicate handling for custom preset names

### Required macOS Permissions
- **Accessibility**: Required for mouse event simulation and global hotkey registration
- **Screen Recording**: Required for window detection, enumeration, and visual overlay rendering
- **Window Management**: Required for clicking on minimized/background windows

## Success Metrics

### Performance Targets
- **Click Accuracy**: ±1 pixel precision
- **Timing Precision**: ±5ms interval accuracy
- **Resource Usage**: <50MB RAM, <5% CPU at idle
- **Response Time**: <100ms UI responsiveness

### User Experience Goals
- **Setup Time**: <30 seconds from launch to first click
- **Learning Curve**: Intuitive for non-technical users
- **Stability**: 99.9% uptime during gaming sessions

## Development Phases

### Phase 1: Core Functionality
- Basic click point selection
- Left/right click support
- Constant interval timing
- ESC key control

### Phase 2: Enhanced Features
- Variable timing patterns
- Visual feedback improvements
- Duration-based stopping
- Basic preset system

### Phase 3: Advanced Capabilities
- Conditional logic support
- Randomization features
- Enhanced preset management
- Performance optimizations

## Risk Mitigation

### Technical Risks
- **macOS Permission Changes**: Plan for accessibility API updates
- **Performance Impact**: Continuous monitoring and optimization
- **Compatibility**: Regular testing on both architectures

### User Experience Risks
- **Complexity Creep**: Maintain simple, focused interface
- **Reliability**: Comprehensive error handling and recovery

## Future Considerations

### Potential Enhancements
- **Pattern Recording**: Record and replay click sequences
- **Multi-Point Support**: Sequential clicking at multiple points
- **Application Integration**: Application-specific optimizations
- **Cloud Sync**: Configuration backup and sync

### Distribution Evolution
- **App Store**: Potential future distribution channel
- **Open Source**: Community contribution possibilities
- **Plugin System**: Extensible architecture for application-specific features
