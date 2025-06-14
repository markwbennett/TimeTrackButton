#!/bin/bash

echo "🔨 Building C++ Time Tracker..."

# Check if Qt6 is installed
if ! command -v qmake6 &> /dev/null && ! command -v qmake &> /dev/null; then
    echo "❌ Qt6 not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Please install Homebrew first."
        exit 1
    fi
    brew install qt6
fi

# Create build directory
mkdir -p build_cpp
cd build_cpp

# Configure with CMake
echo "⚙️  Configuring build..."
if command -v cmake &> /dev/null; then
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(brew --prefix qt6)" ..
else
    echo "❌ CMake not found. Installing..."
    brew install cmake
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(brew --prefix qt6)" ..
fi

# Build the application
echo "🔧 Building application..."
make -j$(sysctl -n hw.ncpu)

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Move the app to the parent directory
    if [ -d "TimeTracker.app" ]; then
        echo "📦 Moving app bundle..."
        rm -rf "../TimeTracker_CPP.app"
        mv "TimeTracker.app" "../TimeTracker_CPP.app"
        
        # Show size comparison
        echo ""
        echo "📊 Size Comparison:"
        if [ -d "../IACLS Time Tracker.app" ]; then
            echo "Python version: $(du -sh "../IACLS Time Tracker.app" | cut -f1)"
        fi
        echo "C++ version:    $(du -sh "../TimeTracker_CPP.app" | cut -f1)"
        
        echo ""
        echo "🎉 C++ Time Tracker built successfully!"
        echo "Run with: open TimeTracker_CPP.app"
    else
        echo "❌ App bundle not found after build"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi 