# IACLS Time Tracker

A lightweight time tracking application with a floating button interface.

## Current Version: C++ Native App (584KB)

The project has been rewritten in C++ using Qt6 for optimal performance and minimal disk usage.

### Quick Start

```bash
cd cpp_app
./build_cpp.sh
open TimeTracker_CPP.app
```

## Project Structure

```
├── cpp_app/                 # Current C++ application
│   ├── main.cpp            # Main application source
│   ├── CMakeLists.txt      # Build configuration
│   ├── build_cpp.sh        # Build script
│   ├── icon.icns           # App icon
│   └── TimeTracker_CPP.app # Built application
├── python_legacy/          # Legacy Python implementation
│   ├── floating_button.py  # Original Python source
│   └── *.app               # Old app bundles
├── build_scripts/          # Build and deployment scripts
├── documentation/          # Project documentation
├── assets/                 # Icons, audio files, etc.
├── distributions/          # Release packages
├── docs/                   # Additional documentation
└── plugins/                # SketchyBar integration
```

## Features

- **Dynamic Button**: Small red circle when not tracking, expands to green when tracking
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
open TimeTracker_CPP.app
```

For complete installation options, see [INSTALL.md](INSTALL.md).

## License

See `documentation/LICENSE` 