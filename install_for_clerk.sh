#!/bin/bash

# IACLS Time Tracker - Easy Installation Script
# Run this script to automatically install the time tracker app

echo "🚀 Installing IACLS Time Tracker..."
echo "======================================"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "✅ Homebrew is already installed"

# Install Qt dependency
echo "📦 Installing Qt dependency..."
brew install qt

# Remove any existing installations
echo "🧹 Removing any existing installations..."
rm -rf "/Applications/IACLS Time Tracker.app"
rm -rf "/Applications/Time Tracker.app"
rm -rf "/Applications/TimeTracker.app"

# Download and install the app directly
echo "⬇️  Downloading IACLS Time Tracker..."
cd /tmp
curl -L "https://github.com/markwbennett/TimeTrackButton/raw/main/releases/TimeTracker_CPP_Latest.app.tar.gz" -o TimeTracker_CPP_Latest.app.tar.gz

if [ ! -f "TimeTracker_CPP_Latest.app.tar.gz" ]; then
    echo "❌ Download failed!"
    exit 1
fi

echo "📦 Extracting and installing..."
tar -xzf TimeTracker_CPP_Latest.app.tar.gz
mv "Time Tracker.app" "/Applications/IACLS Time Tracker.app"

# Clean up
rm -f TimeTracker_CPP_Latest.app.tar.gz

# Verify installation
if [ -d "/Applications/IACLS Time Tracker.app" ]; then
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
    echo "📖 Usage Tips:"
    echo "- Click the floating button to start/stop time tracking"
    echo "- Right-click the button for options and settings"
    echo "- Time data is saved to your Documents folder"
    echo ""
    echo "If you need help: https://github.com/markwbennett/TimeTrackButton"
else
    echo "❌ Installation failed!"
    exit 1
fi 