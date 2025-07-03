# IACLS Time Tracker v1.2.0 - Installation Instructions

## Overview
Version 1.2.0 is **completely self-contained** and requires **NO external dependencies**. It will work on any macOS system regardless of what software is or isn't installed.

## What's New in v1.2.0
- **Zero Dependencies**: No need for Homebrew, Qt, or any other software
- **Universal Compatibility**: Works on any macOS system out of the box
- **Complete Bundle**: All required libraries (Qt, ICU, glib, etc.) are included
- **Optimized Size**: 60MB uncompressed, 25MB download
- **Fully Signed**: Proper code signing prevents all crashes

## Installation Methods

### Method 1: Homebrew (Recommended)
```bash
# Install via Homebrew tap
brew install --cask markwbennett/iacls/iacls-time-tracker
```

The app will be installed as "IACLS Time Tracker" in your Applications folder.

### Method 2: Manual Installation
1. Download: https://github.com/markwbennett/TimeTrackButton/raw/fe09348/cpp_app/TimeTracker_CPP_SelfContained_Complete.app.tar.gz
2. Extract the downloaded .tar.gz file
3. Move `TimeTracker_CPP.app` to your Applications folder
4. Rename to "IACLS Time Tracker.app" if desired

## First Run Setup
1. **Data Folder Selection**: On first launch, the app will ask you to select a folder for storing time tracking data
   - Choose any folder you prefer (e.g., Documents, Desktop, or a dedicated folder)
   - The app will use your selected folder directly (no subfolders created)
   - This only happens once - subsequent launches use the same folder

2. **Preferences**: Access via the app menu to:
   - Change the data folder location
   - Adjust other settings

## Features
- **Round Button Interface**: Small red circle when not tracking, expands to green when tracking
- **Data Storage**: SQLite database in your chosen folder
- **CSV Export**: Export time entries to CSV format
- **6-minute Chimes**: Audio alerts during active time tracking
- **State Synchronization**: Multiple app instances stay in sync

## Technical Details
- **Size**: 60MB uncompressed, 25MB compressed download
- **Dependencies**: All bundled (Qt6, ICU, glib, freetype, harfbuzz, etc.)
- **Compatibility**: macOS 10.15+ (all Apple Silicon and Intel Macs)
- **Code Signed**: Prevents "Code Signature Invalid" crashes
- **SHA256**: `3004d45b081bcfe8c04dc3ad895c533c74125d3b4456a319df75d497ef05ee4b`

## Troubleshooting
- **No issues expected**: This version is completely self-contained
- **If you have problems**: This version eliminates all previous dependency-related crashes
- **Quarantine**: macOS may show a security warning on first run - click "Open" to proceed

## Uninstallation
```bash
# Via Homebrew
brew uninstall --cask iacls-time-tracker

# Manual
rm -rf "/Applications/IACLS Time Tracker.app"
rm -rf "~/Documents/TimeTracker"  # or your chosen data folder
```

## Support
- GitHub: https://github.com/markwbennett/TimeTrackButton
- This version: Commit `fe09348`
- Version: 1.2.0 (Complete Self-Contained) 