# IACLS Time Tracker

A lightweight time tracking application with a floating button interface.

## Current Version: C++ Native App v1.3.0 (584KB)

The project has been rewritten in C++ using Qt6 for optimal performance and minimal disk usage.

### Quick Start

```bash
cd cpp_app
./build_cpp.sh
open TimeTracker_Universal.app
```

## Project Structure

```
├── cpp_app/                 # Current C++ application
│   ├── main.cpp            # Main application source
│   ├── CMakeLists.txt      # Build configuration
│   ├── build_cpp.sh        # Build script
│   ├── build_universal.sh  # Universal binary build script
│   ├── icon.icns           # App icon
│   └── TimeTracker_Universal.app # Built application
├── python_legacy/          # Legacy Python implementation
├── build_scripts/          # Build and deployment scripts
├── scripts/                # Installation and configuration scripts
├── docs/                   # All project documentation
├── releases/               # Current release packages
│   └── TimeTracker_CPP_Fixed.app.tar.gz # Current working release
├── archive/                # Archived builds and obsolete files
│   ├── build_*/            # Old build directories
│   ├── *.app.tar.gz        # Old app bundles
│   ├── dist_*/             # Legacy distributions
│   └── obsolete scripts    # Outdated build files
├── assets/                 # Icons, audio files, etc.
├── plugins/                # SketchyBar integration
└── Casks/                  # Homebrew cask definition
```

## Features

- **Floating Button**: Draggable circular button with visual status
- **Project Tracking**: Select projects and activities
- **Audio Chimes**: 6-minute interval notifications
- **CSV Export**: Automatic time entry export
- **Multi-App Sync**: State synchronization between instances
- **Native Performance**: Fast startup, low memory usage

## Size Comparison

- **Python version**: 49MB
- **C++ version**: 584KB (98.8% reduction)

## Requirements

- macOS 10.15+
- Qt6 (auto-installed via Homebrew)
- CMake (auto-installed via Homebrew)

## Installation

### Homebrew (Recommended)
```bash
brew tap markwbennett/iacls
brew install --cask iacls-time-tracker
```

### Manual Build
```bash
cd cpp_app
./build_cpp.sh
open TimeTracker_Universal.app
```

For complete installation options, see [INSTALL.md](INSTALL.md).

## License

See `docs/LICENSE` 