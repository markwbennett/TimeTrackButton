# IACLS Time Tracker - Windows Installation Guide

## System Requirements

- **Windows**: 10 or later (64-bit recommended)
- **Python**: 3.8 or later (for manual installation)
- **Administrator privileges**: Required for initial setup

## Security Requirements

### Windows Defender and SmartScreen

Since IACLS Time Tracker is not signed with a Microsoft certificate, Windows may show security warnings:

1. **Windows Defender SmartScreen**:
   - Click "More info" when the warning appears
   - Click "Run anyway" to proceed
   - This creates a permanent exception for the app

2. **Windows Defender Antivirus**:
   - The executable may be quarantined initially
   - Add the installation folder to Windows Defender exclusions:
     - Open Windows Security
     - Go to Virus & threat protection
     - Click "Manage settings" under Virus & threat protection settings
     - Click "Add or remove exclusions"
     - Add the IACLS Time Tracker folder

3. **User Account Control (UAC)**:
   - Click "Yes" when prompted for administrator privileges
   - Required for initial file system access setup

### Firewall Configuration

The app doesn't require network access, but if Windows Firewall prompts:
- **Block network access** - the app works entirely offline
- No incoming or outgoing connections are needed

## Installation Methods

### Method 1: Standalone Executable (Recommended)

1. **Download** the latest Windows release from GitHub
2. **Extract** the ZIP file to your desired location (e.g., `C:\Program Files\IACLS Time Tracker\`)
3. **Run** `IACLS_Time_Tracker.exe`
4. **Handle security warnings** as described above
5. **Choose data folder** when prompted on first run

### Method 2: Python Installation

1. **Install Python 3.8+** from python.org
2. **Download** the source code from GitHub
3. **Install dependencies**:
   ```cmd
   pip install PyQt6 pandas
   ```
4. **Run** the application:
   ```cmd
   python floating_button_windows.py
   ```

### Method 3: Build from Source

1. **Install Python 3.8+** and pip
2. **Clone** the repository:
   ```cmd
   git clone https://github.com/markwbennett/TimeTrackButton.git
   cd TimeTrackButton
   ```
3. **Install build dependencies**:
   ```cmd
   pip install -r requirements_windows.txt
   ```
4. **Build executable**:
   ```cmd
   python build_windows.py
   ```
5. **Find executable** in `dist_windows/` folder

## First Run Setup

1. **Launch** `IACLS_Time_Tracker.exe`
2. **Handle security warnings**:
   - Click "More info" → "Run anyway" for SmartScreen
   - Click "Yes" for UAC prompt
3. **Choose data folder**:
   - A folder selection dialog will appear
   - Choose where to store your time tracking data
   - Default: Documents\TimeTracker
   - The app will create necessary subfolders

## Usage

### Starting Time Tracking

1. **Click the floating button** (appears in top-right corner)
2. **Select a project** from the dropdown or create new
3. **Choose activity type**:
   - Legal research
   - Investigation
   - Discovery Review
   - File Review
   - Client Communication
   - Custom activities (via "Other")
4. **Tracking begins** with audio confirmation

### Managing the Floating Button

- **Move the button**: Drag the outer border area
- **Click to track**: Click the inner colored circle
- **Position saving**: Button remembers its position between sessions

### Project Management

- **Create new projects**: Type in the project selection field
- **Manage existing projects**: Select [Manage Projects] option
- **Hide or delete projects**: Use the management interface

### Tracking Options

When tracking is active, clicking the button shows options:
- **Change Activity**: Switch activity type without stopping
- **Change Project**: Switch to different project
- **Stop Tracking**: End current session

### Data Export

- **Automatic CSV export**: Updates in real-time
- **File location**: `[YourFolder]\TimeTracker\time_entries.csv`
- **Format**: ID, Project, Activity, Start Time, End Time, Duration
- **Excel compatible**: Can be opened directly in Excel

## File Locations

### Application Files
- **Executable**: Where you extracted the ZIP file
- **Sound file**: `bells-2-31725.mp3` (in same folder as executable)

### User Data
- **Configuration**: `%USERPROFILE%\.config\timetracker\config`
- **Database**: `[YourFolder]\TimeTracker\.timetrack.db` (hidden)
- **CSV Export**: `[YourFolder]\TimeTracker\time_entries.csv`
- **Position**: `%USERPROFILE%\.config\timetracker\position`
- **Custom Activities**: `%USERPROFILE%\.config\timetracker\custom_activities`

## Troubleshooting

### App Won't Start

1. **Check Windows version**: Requires Windows 10 or later
2. **Run as Administrator**:
   - Right-click `IACLS_Time_Tracker.exe`
   - Select "Run as administrator"
3. **Check antivirus exclusions**:
   - Add the app folder to Windows Defender exclusions
   - Temporarily disable third-party antivirus for testing
4. **Install Visual C++ Redistributables**:
   - Download from Microsoft's website
   - Install both x86 and x64 versions

### Security Warnings Keep Appearing

1. **Create permanent exception**:
   - Right-click the executable
   - Select "Properties"
   - Check "Unblock" if present
   - Click "Apply"

2. **Add to Windows Defender exclusions**:
   - Windows Security → Virus & threat protection
   - Manage settings → Add or remove exclusions
   - Add the entire application folder

### Audio Issues

1. **Check sound file**:
   - Ensure `bells-2-31725.mp3` is in the same folder as the executable
   - Test by double-clicking the sound file

2. **Check Windows audio**:
   - Verify system volume is not muted
   - Check default audio device settings
   - Test with other applications

3. **Audio codec issues**:
   - Install Windows Media Feature Pack if on Windows N/KN editions
   - Update audio drivers

### Button Not Visible

1. **Check display scaling**:
   - Right-click desktop → Display settings
   - Adjust scaling if using high-DPI displays
   - Restart the application after changes

2. **Multiple monitors**:
   - Button may appear on secondary monitor
   - Check all connected displays
   - Delete position file to reset: `%USERPROFILE%\.config\timetracker\position`

### Database Issues

1. **Check data folder permissions**:
   - Ensure write access to chosen data folder
   - Try running as administrator
   - Choose a different data folder if needed

2. **Reset configuration**:
   ```cmd
   del "%USERPROFILE%\.config\timetracker\config"
   ```
   - App will prompt for new folder on next launch

3. **Corrupted database**:
   - Backup your CSV file first
   - Delete `.timetrack.db` file
   - App will recreate database on next launch

### Performance Issues

1. **Close unnecessary applications**
2. **Check available disk space** in data folder
3. **Disable Windows visual effects** if needed:
   - System Properties → Advanced → Performance Settings
   - Select "Adjust for best performance"

## Creating Desktop Shortcut

1. **Right-click** on `IACLS_Time_Tracker.exe`
2. **Select** "Create shortcut"
3. **Move shortcut** to Desktop
4. **Rename** if desired
5. **Right-click shortcut** → Properties to customize icon

## Startup Configuration

To start automatically with Windows:

1. **Press** `Win + R`
2. **Type** `shell:startup` and press Enter
3. **Copy** the executable or create a shortcut in this folder
4. **Restart** Windows to test

## Uninstallation

### Standalone Installation

1. **Close** the application
2. **Delete** the application folder
3. **Remove data** (optional):
   ```cmd
   rmdir /s "%USERPROFILE%\.config\timetracker"
   rmdir /s "[YourDataFolder]\TimeTracker"
   ```
4. **Remove shortcuts** from Desktop/Start Menu

### Python Installation

1. **Close** the application
2. **Uninstall Python packages** (optional):
   ```cmd
   pip uninstall PyQt6 pandas
   ```
3. **Delete** source code folder
4. **Remove data** (same as above)

## Support

- **GitHub Issues**: https://github.com/markwbennett/TimeTrackButton/issues
- **Documentation**: https://github.com/markwbennett/TimeTrackButton
- **Developer**: iacls.org

## License

MIT License - See LICENSE file for details.

## Windows-Specific Notes

- **File paths**: Use backslashes (`\`) in Windows paths
- **Case sensitivity**: Windows is case-insensitive for file names
- **Long path support**: Enable if using very long folder names
- **Antivirus compatibility**: Most antivirus software is compatible, but may require exclusions
- **Windows updates**: Keep Windows updated for best compatibility 