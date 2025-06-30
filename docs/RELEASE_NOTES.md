# Release Notes

## Version 1.3.0 (June 30, 2024)

### Updates
- **Standardized Build Process**: Official version now uses `TimeTracker_CPP.app` with complete Qt bundling
- **Improved Self-Containment**: Updated to latest bundling approach with all dependencies included
- **File Organization**: Reorganized codebase structure for better maintainability
- **Distribution**: Updated Homebrew cask to point to latest build

### Technical Changes
- Moved from `TimeTracker_CPP_SelfContained_Complete.app.tar.gz` to `TimeTracker_CPP_Latest.app.tar.gz`
- Consolidated documentation and distribution files
- Updated build scripts for consistent self-contained builds

# IACLS Time Tracker v1.2.0 - Dual Architecture Support

## 🎉 New Features
- **Intel Mac Support**: Now available for both Apple Silicon (ARM64) and Intel (x86_64) Macs
- **Dual Architecture Builds**: Separate optimized builds for each architecture

## 📦 Downloads

### For Apple Silicon Macs (M1/M2/M3/M4)
- **Homebrew (Recommended)**: `brew install --cask iacls-time-tracker`
- **Direct Download**: `IACLS_Time_Tracker_macOS.zip` (ARM64)

### For Intel Macs
- **Direct Download**: `IACLS_Time_Tracker_macOS_x86_64.zip` (x86_64)

## 🔧 Installation Instructions

### Apple Silicon Macs (Recommended)
```bash
# Install via Homebrew (easiest)
brew install --cask iacls-time-tracker

# Or download and run the .app directly
```

### Intel Macs
1. Download `IACLS_Time_Tracker_macOS_x86_64.zip`
2. Extract and run "IACLS Time Tracker x86_64.app"
3. Allow in System Preferences > Security & Privacy if prompted

## ⚙️ Features
- Floating circular button for time tracking
- Visual status indicators (red = idle, green = tracking)
- Chime notifications for tracking events
- Data sync via Google Drive or local storage
- SketchyBar plugin integration
- Persistent state across app restarts

## 🏗️ Architecture Details
- **ARM64 version**: Optimized for Apple Silicon, distributed via Homebrew
- **x86_64 version**: Compatible with Intel Macs, direct download only
- Both versions use Qt6 framework for native macOS integration

## 📋 System Requirements
- **Apple Silicon**: macOS 11.0 (Big Sur) or later
- **Intel**: macOS 10.15 (Catalina) or later

## 🐛 Known Issues
- Intel version requires manual installation (not available via Homebrew)
- First launch may require security permission approval

## 🔗 Links
- [Repository](https://github.com/markwbennett/TimeTrackButton)
- [Issues](https://github.com/markwbennett/TimeTrackButton/issues)
- [SketchyBar Integration](https://github.com/markwbennett/TimeTrackButton#sketchybar-integration)

## 🙏 Support
If you encounter issues:
1. Check the architecture of your Mac: `uname -m` (arm64 = Apple Silicon, x86_64 = Intel)
2. Download the appropriate version
3. Report issues on GitHub with your Mac model and macOS version
