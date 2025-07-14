#!/usr/bin/env python3
"""
Create release notes for IACLS Time Tracker dual-architecture release
"""

def create_release_notes():
    """Generate release notes for the dual-architecture release"""
    
    version = "2.0.0"  # Major version increment for pause tracking functionality
    
    release_notes = f"""# IACLS Time Tracker v{version} - Pause Tracking & Inactivity Detection

## 🎉 New Features
- **Pause Tracking**: Manually pause and resume tracking sessions with button click
- **Auto-Pause**: Automatically pauses tracking after 5 minutes of inactivity  
- **Smart Time Calculation**: Elapsed time excludes paused periods for accurate billing
- **Visual State Indicators**: 
  - Green: Actively tracking
  - Orange: Paused (shows "(Paused)" text)  
  - Red: Not tracking
- **Seamless Resume**: Click button when paused to instantly resume tracking

## 🔧 Technical Improvements
- **Enhanced Database**: New pause_periods table tracks all pause/resume events
- **Idle Detection**: Uses macOS system APIs to monitor user activity
- **State Persistence**: Pause state synchronized across all app instances
- **SketchyBar Integration**: Status bar shows paused state with orange background

## 📦 Installation

### Homebrew (Recommended)
```bash
brew install --cask iacls-time-tracker
```

### Manual Installation
1. Download the latest release from GitHub
2. Extract and move to Applications folder
3. Run the app and follow setup instructions

## 🚀 Usage

### Pause/Resume Tracking
- **While tracking**: Click button → Select "Pause Tracking" from menu
- **While paused**: Click button → Automatically resumes tracking
- **Auto-pause**: Tracking automatically pauses after 5 minutes of inactivity

### SketchyBar Integration
- Green background: Actively tracking with elapsed time
- Orange background: Paused state with "(Paused)" indicator
- Red icon: Not tracking

## 🐛 Troubleshooting

If you encounter issues:
1. Ensure you have macOS 11.0 or later
2. Check that accessibility permissions are granted
3. Report issues on GitHub with your Mac model and macOS version

## 📝 Release Notes
- Major version increment due to significant new pause/resume functionality
- Database schema updated with pause_periods table
- Enhanced UI with visual state indicators
- Improved time accuracy by excluding paused periods"""

    return release_notes

def main():
    """Generate and save release notes"""
    notes = create_release_notes()
    
    with open("RELEASE_NOTES.md", "w") as f:
        f.write(notes)
    
    print("✅ Release notes created: RELEASE_NOTES.md")
    print("\n📋 Next steps:")
    print("1. Review the release notes")
    print("2. Create a GitHub release with tag v2.0.0")
    print("3. Upload both ZIP files as release assets")
    print("4. Update Homebrew cask version to 2.0.0")

if __name__ == "__main__":
    main() 