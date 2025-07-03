# Time Tracker - SwiftUI Native Version

A native macOS time tracking application built with SwiftUI.

## Features

- **Floating Button Interface** - Draggable circular button that shows tracking status
- **Project & Activity Tracking** - Organize time by projects and activities
- **Audio Notifications** - Chimes every 6 minutes during tracking
- **SQLite Database** - Local storage of time entries
- **CSV Export** - Export time data for reporting
- **Native macOS Integration** - No external dependencies required

## Requirements

- **macOS 13.0+** (Ventura or later)
- **No additional dependencies** - completely self-contained

## Building

### Option 1: Command Line Build
```bash
cd swiftui_app
./build.sh
```

### Option 2: Xcode Build
```bash
cd swiftui_app
open TimeTracker.xcodeproj
# Build in Xcode (⌘+B)
```

## Running

After building:
```bash
open "build/Time Tracker.app"
```

## Advantages over Qt Version

| Feature | SwiftUI Version | Qt Version |
|---------|----------------|------------|
| **Dependencies** | None | Qt 6.9.1 (~200MB) |
| **App Size** | ~2-5MB | 732KB + Qt |
| **Native Look** | ✅ Native macOS | ❌ Qt widgets |
| **Performance** | ✅ Native code | ⚠️ Framework overhead |
| **Distribution** | ✅ Self-contained | ❌ Requires Qt install |
| **Future Support** | ✅ Apple's framework | ⚠️ Third-party |

## Usage

1. **Start Tracking**: Click the red button, select project and activity
2. **View Progress**: Button shows project name and elapsed time
3. **Stop/Change**: Click while tracking to access options
4. **Preferences**: Right-click for settings and preferences
5. **Data Location**: Time data stored in `~/Documents/TimeTracker/`

## Data Compatibility

The SwiftUI version uses the same SQLite database format as the Qt version, so your data is fully compatible between both versions.

## Architecture

- **SwiftUI** - Modern declarative UI framework
- **SQLite3** - Direct C API for database operations
- **AVFoundation** - Native audio playback
- **UserDefaults** - Settings and preferences storage
- **FileManager** - File operations and CSV export 