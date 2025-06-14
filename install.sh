#!/bin/bash

# IACLS Time Tracker Installation Script
# This script installs the Time Tracker and removes macOS quarantine attributes

set -e

echo "Installing IACLS Time Tracker..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Please do not run this script as root/sudo" 
   exit 1
fi

# Download and extract
echo "Downloading TimeTracker..."
curl -L -o /tmp/TimeTracker_CPP.app.tar.gz "https://github.com/markwbennett/TimeTrackButton/raw/main/TimeTracker_CPP.app.tar.gz"

echo "Extracting..."
cd /tmp
tar -xzf TimeTracker_CPP.app.tar.gz

# Remove quarantine attributes
echo "Removing quarantine attributes..."
xattr -dr com.apple.quarantine TimeTracker_CPP.app 2>/dev/null || true

# Move to Applications
echo "Installing to Applications folder..."
if [ -d "/Applications/IACLS Time Tracker.app" ]; then
    echo "Removing existing installation..."
    rm -rf "/Applications/IACLS Time Tracker.app"
fi

mv TimeTracker_CPP.app "/Applications/IACLS Time Tracker.app"

# Clean up
rm -f /tmp/TimeTracker_CPP.app.tar.gz

echo "✅ IACLS Time Tracker installed successfully!"
echo ""
echo "You can now:"
echo "  • Open it from Applications folder"
echo "  • Run: open '/Applications/IACLS Time Tracker.app'"
echo ""
echo "If macOS still shows security warnings, you may need to:"
echo "  1. Go to System Settings > Privacy & Security"
echo "  2. Click 'Open Anyway' next to the blocked app"
echo ""
echo "Data will be stored in ~/Documents/TimeTracker/" 