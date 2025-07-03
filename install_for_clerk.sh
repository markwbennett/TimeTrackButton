#!/bin/bash

# IACLS Time Tracker - Easy Installation Script
# Run this script to automatically install the time tracker app

echo "🚀 Installing IACLS Time Tracker..."
echo "======================================"

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script is for macOS only"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Homebrew is installed
if ! command_exists brew; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon Mac
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    echo "✅ Homebrew installed successfully"
else
    echo "✅ Homebrew is already installed"
fi

# Remove any old conflicting taps
echo "🧹 Cleaning up old taps..."
brew untap markwbennett/timetrackbutton --force 2>/dev/null || true

# Add the IACLS tap
echo "📋 Adding IACLS tap..."
brew tap markwbennett/iacls || {
    echo "❌ Failed to add IACLS tap"
    exit 1
}

# Install the Time Tracker app
echo "⬇️  Installing IACLS Time Tracker..."
brew install --cask markwbennett/iacls/iacls-time-tracker || {
    echo "❌ Failed to install IACLS Time Tracker"
    exit 1
}

echo "✅ IACLS Time Tracker installed successfully!"
echo ""
echo "🎉 Installation Complete!"
echo "========================="
echo ""
echo "The app has been installed to: /Applications/IACLS Time Tracker.app"
echo ""
echo "To launch the app:"
echo "1. Open Finder"
echo "2. Go to Applications"
echo "3. Double-click 'IACLS Time Tracker'"
echo ""
echo "Or run this command:"
echo "open '/Applications/IACLS Time Tracker.app'"
echo ""

# Ask if they want to launch the app now
read -p "Would you like to launch the app now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Launching IACLS Time Tracker..."
    open "/Applications/IACLS Time Tracker.app"
fi

echo ""
echo "📖 Usage Tips:"
echo "- Click the floating button to start/stop time tracking"
echo "- Right-click the button for options and settings"
echo "- Time data is saved to your Documents folder"
echo ""
echo "If you need help: https://github.com/markwbennett/TimeTrackButton" 