# IACLS Time Tracker Installation

## Homebrew Installation (Recommended)

### Option 1: Install from this repository
```bash
brew install --cask ./Casks/iacls-time-tracker.rb
```

### Option 2: Add as a tap (for easier updates)
```bash
brew tap markwbennett/timetracker https://github.com/markwbennett/TimeTrackButton
brew install --cask iacls-time-tracker
```

## Manual Installation

1. Download the latest `TimeTracker_CPP.app.tar.gz` from the repository
2. Extract the archive:
   ```bash
   tar -xzf TimeTracker_CPP.app.tar.gz
   ```
3. Move the app to your Applications folder:
   ```bash
   mv TimeTracker_CPP.app /Applications/
   ```
4. Run the app:
   ```bash
   open /Applications/TimeTracker_CPP.app
   ```

## Usage

- The app creates a floating circular button on your screen
- Click to start/stop time tracking
- Right-click or long-press for options (change project, activity, etc.)
- Access preferences via the menu bar: TimeTracker → Preferences
- Data is stored in `~/Documents/TimeTracker/`

## Features

- **Time Tracking**: Start/stop tracking with visual feedback
- **Projects & Activities**: Organize work by project and activity type
- **Audio Chimes**: Optional 6-minute interval chimes during tracking
- **Data Export**: Automatic CSV export to `~/Documents/TimeTracker/`
- **Multi-Computer Sync**: Projects and activities sync across computers when using shared storage
- **Preferences**: Adjust chime volume, manage projects and activities

## About

This time tracker was developed for the Institute for Advanced Criminal Law Studies (IACLS). If you find it useful, please consider supporting IACLS at https://iacls.org/donate 