# IACLS Time Tracker - macOS Installation Guide

## System Requirements

- **macOS**: 10.15 (Catalina) or later
- **Python**: 3.8 or later (included with macOS)
- **Homebrew**: Recommended for easy installation

## Security Requirements

### Gatekeeper and Code Signing

Since IACLS Time Tracker is not signed with an Apple Developer certificate, you'll need to bypass Gatekeeper:

1. **First Launch Security Override**:
   - Right-click on `IACLS Time Tracker.app`
   - Select "Open" from the context menu
   - Click "Open" in the security dialog
   - This creates a permanent exception for the app

2. **Alternative Method**:
   ```bash
   # Remove quarantine attribute
   xattr -d com.apple.quarantine "IACLS Time Tracker.app"
   ```

3. **System Preferences Method**:
   - Go to System Preferences → Security & Privacy
   - Click "Open Anyway" if the app was blocked
   - Enter your administrator password

### Privacy Permissions

The app may request the following permissions:

- **Accessibility**: For global hotkeys and window management
- **Files and Folders**: To save time tracking data
- **Microphone**: Not used, can be denied

Grant permissions in System Preferences → Security & Privacy → Privacy.

## Installation Methods

### Method 1: Easy Installer (Recommended for Beginners)

1. **Download the latest release** from GitHub
2. **Extract the ZIP file**
3. **Double-click** `Easy_Installer.app`
4. **Follow the prompts**:
   - Click "OK" to start installation
   - Enter your password when prompted (for Homebrew)
   - Wait for installation to complete
   - Click "Launch App" when finished

The Easy Installer will:
- Install Homebrew if not already present
- Add the IACLS tap to Homebrew
- Install IACLS Time Tracker
- Offer to launch the app immediately

### Method 2: Homebrew (For Existing Homebrew Users)

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Add the IACLS tap**:
   ```bash
   brew tap markwbennett/iacls
   ```

3. **Install IACLS Time Tracker**:
   ```bash
   brew install --cask iacls-time-tracker
   ```

4. **Launch the app**:
   ```bash
   open "/Applications/IACLS Time Tracker.app"
   ```

### Method 3: Manual Installation

1. **Download the latest release** from GitHub
2. **Extract the archive** and move `IACLS Time Tracker.app` to your Applications folder
3. **Launch the app**:
   ```bash
   open "/Applications/IACLS Time Tracker.app"
   ```

### SketchyBar Integration (Advanced Users)

For SketchyBar menu bar integration, clone the full repository:

```bash
git clone https://github.com/markwbennett/TimeTrackButton.git
cd TimeTrackButton

# Set up SketchyBar plugins
mkdir -p ~/.config/sketchybar/plugins
ln -sf "$(pwd)/plugins/time_tracker.sh" ~/.config/sketchybar/plugins/
ln -sf "$(pwd)/plugins/time_tracker_click.sh" ~/.config/sketchybar/plugins/

# Add to SketchyBar configuration
echo 'sketchybar --add item time_tracker right \
          --set time_tracker update_freq=10 \
                script="$PLUGIN_DIR/time_tracker.sh" \
                click_script="$PLUGIN_DIR/time_tracker_click.sh"' >> ~/.config/sketchybar/sketchybarrc

# Reload SketchyBar
sketchybar --reload
```

## First Run Setup

1. **Launch the app**:
   - Double-click `IACLS Time Tracker.app`

2. **Choose data folder**:
   - A folder selection dialog will appear
   - Choose where to store your time tracking data
   - Default: Documents folder
   - A "TimeTracker" subfolder will be created

3. **Security prompts**:
   - Grant necessary permissions when prompted
   - The app will remember your choices

## Usage

### Starting Time Tracking

1. **Click the floating button** (or SketchyBar icon if installed)
2. **Select a project** from the dropdown or create new
3. **Choose activity type** (Legal research, Investigation, etc.)
4. **Tracking begins** with audio confirmation

### Managing Projects

- **Create new projects** by typing in the project field
- **Manage existing projects** via the [Manage Projects] option
- **Hide or delete** projects you no longer need

### Stopping Tracking

- **Click the tracking button** to show options menu
- **Select "Stop Tracking"** or choose to change project/activity
- **Data automatically saved** to CSV file

### Data Export

- **Automatic CSV export** to your chosen data folder
- **File location**: `[YourFolder]/TimeTracker/time_entries.csv`
- **Format**: Project, Activity, Start Time, End Time, Duration

## Troubleshooting

### App Won't Launch

1. **Check Gatekeeper settings**:
   ```bash
   spctl --assess --verbose "IACLS Time Tracker.app"
   ```

2. **Remove quarantine**:
   ```bash
   xattr -d com.apple.quarantine "IACLS Time Tracker.app"
   ```

3. **Check permissions**:
   - System Preferences → Security & Privacy
   - Grant required permissions

### SketchyBar Integration Issues

1. **Verify SketchyBar is running**:
   ```bash
   pgrep sketchybar
   ```

2. **Check plugin permissions**:
   ```bash
   chmod +x ~/.config/sketchybar/plugins/time_tracker*.sh
   ```

3. **View debug logs**:
   ```bash
   tail -f /tmp/time_tracker_click_debug.log
   ```

### Audio Issues

1. **Check sound file**:
   ```bash
   ls -la "IACLS Time Tracker.app/Contents/Resources/bells-2-31725.mp3"
   ```

2. **Test audio**:
   ```bash
   afplay -v 0.1 "IACLS Time Tracker.app/Contents/Resources/bells-2-31725.mp3"
   ```

3. **Check system volume** and audio output settings

### Database Issues

1. **Check data folder**:
   ```bash
   cat ~/.config/timetracker/config
   ```

2. **Verify database file**:
   ```bash
   ls -la [YourDataFolder]/TimeTracker/.timetrack.db
   ```

3. **Reset configuration** (if needed):
   ```bash
   rm ~/.config/timetracker/config
   # App will prompt for new folder on next launch
   ```

## Uninstallation

### Homebrew Installation

```bash
# Remove the app
brew uninstall --cask iacls-time-tracker

# Remove the tap (optional)
brew untap markwbennett/iacls
```

### Manual Installation

1. **Remove the app**:
   ```bash
   rm -rf "/Applications/IACLS Time Tracker.app"
   ```

2. **Remove SketchyBar plugins**:
   ```bash
   rm ~/.config/sketchybar/plugins/time_tracker*.sh
   ```

3. **Remove configuration** (optional):
   ```bash
   rm -rf ~/.config/timetracker
   ```

4. **Remove data** (optional):
   ```bash
   # Check your data folder first
   cat ~/.config/timetracker/config
   # Then remove if desired
   rm -rf [YourDataFolder]/TimeTracker
   ```

## Support

- **GitHub Issues**: https://github.com/markwbennett/TimeTrackButton/issues
- **Documentation**: https://github.com/markwbennett/TimeTrackButton
- **Developer**: iacls.org

## License

MIT License - See LICENSE file for details. 