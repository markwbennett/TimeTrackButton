# IACLS Time Tracker - Clean Installation Instructions

## Step 1: Remove Old Version and Clear Cache

**Run these commands in Terminal (one at a time):**

```bash
# Remove the old app
sudo rm -rf "/Applications/IACLS Time Tracker.app"

# Clear Homebrew cache
brew cleanup --prune=all

# Remove old tap (if exists)
brew untap markwbennett/timetrackbutton --force 2>/dev/null || true

# Update Homebrew
brew update

# Clear any cached downloads
rm -rf ~/Library/Caches/Homebrew/downloads/*iacls* 2>/dev/null || true
rm -rf ~/Library/Caches/Homebrew/downloads/*timetrack* 2>/dev/null || true
```

## Step 2: Install Fresh Version

**Option A: Use the automated installer (Recommended)**

```bash
curl -o install_for_clerk.sh https://raw.githubusercontent.com/markwbennett/TimeTrackButton/main/install_for_clerk.sh
chmod +x install_for_clerk.sh
./install_for_clerk.sh
```

**Option B: Manual installation**

```bash
# Add the IACLS tap
brew tap markwbennett/iacls

# Install the app
brew install --cask markwbennett/iacls/iacls-time-tracker
```

## Step 3: Launch the App

**Try launching the app:**

```bash
open "/Applications/IACLS Time Tracker.app"
```

**If macOS blocks the app (security warning):**

1. Go to **System Preferences** → **Privacy & Security**
2. Look for a message about "IACLS Time Tracker" being blocked
3. Click **"Open Anyway"**

**Alternative method if needed:**

```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine "/Applications/IACLS Time Tracker.app"

# Then try launching again
open "/Applications/IACLS Time Tracker.app"
```

## Step 4: Verify Installation

The app should:
- ✅ Launch without crashing
- ✅ Show a red floating button saying "Not Tracking"
- ✅ Allow you to click it to start tracking
- ✅ Not show any "QtDBus" error messages

## Troubleshooting

**If the app still crashes:**

1. Check Console.app for crash logs
2. Look for any error messages mentioning missing frameworks
3. Send the crash log back for analysis

**If Homebrew has issues:**

```bash
# Reset Homebrew completely
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## What's Fixed

This new version:
- ✅ Includes all required Qt frameworks (including QtDBus)
- ✅ Uses proper cross-platform deployment
- ✅ Works without requiring Qt to be installed on your system
- ✅ Size: 68MB (includes all dependencies)
- ✅ Tested and verified working

## Support

If you encounter any issues, please:
1. Run the app from Terminal to see error messages: `"/Applications/IACLS Time Tracker.app/Contents/MacOS/TimeTracker"`
2. Check Console.app for crash logs
3. Send the error details back for further assistance 