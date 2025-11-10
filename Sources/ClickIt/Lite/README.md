# ClickIt Lite

**The simple auto-clicker for macOS**

## What is ClickIt Lite?

ClickIt Lite is a dramatically simplified version of ClickIt, designed for users who just want basic auto-clicking without the complexity of the full application.

### Philosophy

**Do one thing well** - Click automatically at a specified location with a configurable interval. That's it.

## Features

✅ **Core Features Only:**
- Click at a fixed location (set from mouse position)
- Configurable click interval (0.1 - 10 seconds)
- Left and right click support
- Start/Stop with big buttons
- ESC key emergency stop (works globally)
- Simple status display showing click count
- Basic permission management

❌ **What's NOT Included:**
- No presets/saved configurations
- No scheduling system
- No statistics tracking
- No performance monitoring
- No window targeting
- No active target mode
- No location randomization
- No duration limits
- No pause/resume
- No advanced configuration

## File Count

**ClickIt Lite: 7 files** (vs 139 in full version)

1. `ClickItLiteApp.swift` - App entry point
2. `SimplifiedMainView.swift` - Single-window UI
3. `SimpleViewModel.swift` - State management
4. `SimpleClickEngine.swift` - Core clicking
5. `SimplePermissionManager.swift` - Basic permissions
6. `SimpleHotkeyManager.swift` - ESC key only
7. `README.md` - This file

**90% file reduction from full version!**

## How to Use

### 1. Grant Permissions
On first launch, click "Grant Permission" to allow ClickIt Lite to control your mouse.

### 2. Set Click Location
1. Move your mouse to where you want clicks to happen
2. Click "Set from Mouse" button
3. The X,Y coordinates will update

### 3. Configure Interval
Use the slider to set how often to click (in seconds).

### 4. Choose Click Type
Select "Left Click" or "Right Click" from the segmented control.

### 5. Start Clicking
Click the big green "START CLICKING" button.

### 6. Stop Clicking
- Click the red "STOP CLICKING" button, OR
- Press ESC key anywhere (emergency stop)

## Requirements

- macOS 13.0 or later
- Accessibility permission

## Building from Source

To build ClickIt Lite as a standalone app:

1. Comment out the original `@main` in `ClickItApp.swift`
2. Ensure `ClickItLiteApp.swift` has `@main` annotation
3. Build with: `swift build -c release`

## Comparison to Full ClickIt

| Feature | ClickIt Lite | ClickIt Full |
|---------|-------------|--------------|
| Files | 7 | 139 |
| UI Tabs | 1 window | 5 tabs |
| Click Types | 2 (L/R) | 2 (L/R) |
| Presets | ❌ | ✅ |
| Scheduling | ❌ | ✅ |
| Statistics | Simple count | Full analytics |
| Window Targeting | ❌ | ✅ |
| Randomization | ❌ | ✅ |
| Performance Monitoring | ❌ | ✅ |
| Emergency Stop Keys | ESC only | 8 options |
| Duration Modes | Unlimited only | 3 modes |
| Pause/Resume | ❌ | ✅ |
| Import/Export | ❌ | ✅ |

## Target Audience

ClickIt Lite is perfect for:
- ✅ First-time auto-clicker users
- ✅ Simple, one-off clicking tasks
- ✅ Gamers who need basic clicking
- ✅ Anyone who finds full ClickIt overwhelming
- ✅ Users who value simplicity over features

Use full ClickIt if you need:
- ❌ Saved presets and configurations
- ❌ Scheduled automation
- ❌ Detailed statistics and reporting
- ❌ Advanced targeting and randomization
- ❌ Professional automation workflows

## License

Same as ClickIt main project.

## Feedback

If ClickIt Lite is too simple or missing a critical feature, please let us know! The goal is to find the sweet spot between simplicity and functionality.
