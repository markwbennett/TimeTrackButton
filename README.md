# IACLS Time Tracker

A lightweight time tracking application with a floating button interface.

## Current Version: C++ Native App v1.3.0 (584KB)

The project has been rewritten in C++ using Qt6 for optimal performance and minimal disk usage.

### Quick Start

```bash
cd cpp_app
./build_cpp.sh
./bundle_complete_qt.sh  # Makes it self-contained
open TimeTracker_CPP.app
```

## Project Structure

```
├── cpp_app/                 # Current C++ application
│   ├── main.cpp            # Main application source
│   ├── CMakeLists.txt      # Build configuration
│   ├── build_cpp.sh        # Build script (auto-bundles)
│   ├── bundle_complete_qt.sh # Self-contained bundling
│   ├── icon.icns           # App icon
│   ├── test_qt.cpp         # Qt test file
│   ├── TimeTracker_CPP.app # Built application
│   └── TimeTracker_CPP_Latest.app.tar.gz # Distribution version
├── python_legacy/          # Legacy Python implementation
│   ├── floating_button.py  # Original Python source
│   └── *.app               # Old app bundles
├── build_scripts/          # Build and deployment scripts
├── scripts/                # Installation and configuration scripts
│   ├── install.sh          # Installation script
│   └── example_sketchybarrc # SketchyBar configuration
├── docs/                   # All project documentation
│   ├── README.md           # Detailed documentation
│   ├── INSTALL.md          # Installation guide
│   ├── INSTALLATION_v1.2.0.md # Version-specific install
│   ├── RELEASE_NOTES.md    # Release history
│   ├── LICENSE             # Project license
│   ├── macOS_Installation_Guide.md
│   ├── Windows_Installation_Guide.md
│   └── *.md                # Other documentation
├── releases/               # Release packages and distributions
│   ├── dist_macos/         # macOS distribution
│   ├── dist_windows_package/ # Windows distribution
│   ├── dist_macos_x86/     # x86 macOS distribution
│   └── *.zip               # Release archives
├── archive/                # Archived builds and obsolete files
│   ├── *.app.tar.gz        # Old app bundles
│   ├── dist_*/             # Legacy distributions
│   ├── *.zip               # Old release packages
│   └── build artifacts     # Obsolete build files
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
./bundle_complete_qt.sh  # Makes it self-contained
open TimeTracker_CPP.app
```

For complete installation options, see [INSTALL.md](INSTALL.md).

## License

See `docs/LICENSE` 