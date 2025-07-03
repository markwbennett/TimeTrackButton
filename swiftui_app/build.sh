#!/bin/bash

# SwiftUI Time Tracker Build Script
cd "$(dirname "$0")"

echo "🔨 Building SwiftUI Time Tracker..."

# Clean previous build
rm -rf build
mkdir -p build

# Build the app
swiftc TimeTrackerSimple.swift \
    -target arm64-apple-macos13.0 \
    -framework SwiftUI \
    -framework Foundation \
    -framework AppKit \
    -framework AVFoundation \
    -framework UniformTypeIdentifiers \
    -lsqlite3 \
    -parse-as-library \
    -O \
    -o build/TimeTracker

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Create app bundle
    APP_NAME="Time Tracker.app"
    rm -rf "build/$APP_NAME"
    mkdir -p "build/$APP_NAME/Contents/"{MacOS,Resources}
    
    # Copy executable
    cp build/TimeTracker "build/$APP_NAME/Contents/MacOS/Time Tracker"
    
    # Copy resources
    cp Info.plist "build/$APP_NAME/Contents/"
    cp bells-2-31725.mp3 "build/$APP_NAME/Contents/Resources/"
    cp icon.icns "build/$APP_NAME/Contents/Resources/"
    
    # Make executable
    chmod +x "build/$APP_NAME/Contents/MacOS/Time Tracker"
    
    echo "📦 App bundle created: build/$APP_NAME"
    echo "🚀 Run with: open \"build/$APP_NAME\""
    
    # Show size comparison
    echo ""
    echo "📊 Size Comparison:"
    du -sh "build/$APP_NAME"
    echo "SwiftUI version: $(du -sh "build/$APP_NAME" | cut -f1)"
    if [ -d "../cpp_app/Time Tracker.app" ]; then
        echo "Qt version:      $(du -sh "../cpp_app/Time Tracker.app" | cut -f1) (+ Qt frameworks)"
    fi
    
else
    echo "❌ Build failed!"
    exit 1
fi 