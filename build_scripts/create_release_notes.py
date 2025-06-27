#!/usr/bin/env python3
"""
Create release notes for IACLS Time Tracker dual-architecture release
"""

def create_release_notes():
    """Generate release notes for the dual-architecture release"""
    
    version = "1.2.0"  # Increment version for dual-architecture support
    
    release_notes = f"""# IACLS Time Tracker v{version} - Dual Architecture Support

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
"""

    return release_notes

def main():
    """Generate and save release notes"""
    notes = create_release_notes()
    
    with open("RELEASE_NOTES.md", "w") as f:
        f.write(notes)
    
    print("✅ Release notes created: RELEASE_NOTES.md")
    print("\n📋 Next steps:")
    print("1. Review the release notes")
    print("2. Create a GitHub release with tag v1.2.0")
    print("3. Upload both ZIP files as release assets")
    print("4. Update Homebrew cask version to 1.2.0")

if __name__ == "__main__":
    main() 