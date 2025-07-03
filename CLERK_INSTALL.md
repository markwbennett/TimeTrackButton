# IACLS Time Tracker - Installation for Mac

## Quick Install (One Command)

Open Terminal and run this single command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && brew tap markwbennett/iacls && brew install --cask iacls-time-tracker && open "/Applications/IACLS Time Tracker.app"
```

This will:
1. Install Homebrew (if not already installed)
2. Add the IACLS tap
3. Install the Time Tracker app
4. Launch the app

## Step-by-Step Instructions

### 1. Open Terminal
- Press `Cmd + Space` to open Spotlight
- Type "Terminal" and press Enter

### 2. Install Homebrew (if not already installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- Enter your password when prompted
- Wait for installation to complete

### 3. Install IACLS Time Tracker
```bash
brew tap markwbennett/iacls
brew install --cask iacls-time-tracker
```

### 4. Launch the App
```bash
open "/Applications/IACLS Time Tracker.app"
```

Or find "IACLS Time Tracker" in your Applications folder and double-click it.

## Security Note

When you first run the app, macOS may show a security warning. If this happens:
1. Right-click on the app in Applications
2. Select "Open" from the menu
3. Click "Open" in the dialog that appears

## Usage

- The app creates a small floating button on your screen
- Click the button to start/stop time tracking
- Right-click for options (change project, settings, etc.)
- Time data is saved to your Documents folder

## Support

If you need help: https://github.com/markwbennett/TimeTrackButton/issues 