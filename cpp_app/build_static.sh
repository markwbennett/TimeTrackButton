#!/bin/bash

APP_PATH="TimeTracker_Static.app"
BUILD_DIR="build_static"

echo "🔨 Building completely static Qt Time Tracker..."

# Clean previous builds
rm -rf "$BUILD_DIR" "$APP_PATH"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "⚙️  Configuring for static build..."

# Configure with static Qt
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/qt/lib/cmake" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15 \
    -DQT_FEATURE_static=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_CXX_FLAGS="-stdlib=libc++ -static-libgcc -static-libstdc++" \
    -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++"

echo "🔧 Building static application..."
make -j$(sysctl -n hw.ncpu)

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful!"

# Move the app bundle
mv TimeTracker.app "../$APP_PATH"
cd ..

echo "📦 Creating completely isolated bundle..."

# Create a wrapper script that sets up isolated environment
cat > "$APP_PATH/Contents/MacOS/TimeTracker_wrapper" << 'EOF'
#!/bin/bash

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$(dirname "$DIR")")"

# Clear all Qt-related environment variables to avoid conflicts
unset QT_PLUGIN_PATH
unset QT_QPA_PLATFORM_PLUGIN_PATH
unset QTDIR
unset QT_SELECT
unset QML2_IMPORT_PATH
unset QT_QUICK_CONTROLS_STYLE

# Set environment to use only bundled libraries
export DYLD_LIBRARY_PATH="$APP_DIR/Contents/Libraries"
export DYLD_FRAMEWORK_PATH=""
export QT_PLUGIN_PATH="$APP_DIR/Contents/PlugIns"
export QT_QPA_PLATFORM_PLUGIN_PATH="$APP_DIR/Contents/PlugIns/platforms"

# Run the actual binary
exec "$DIR/TimeTracker_real" "$@"
EOF

# Make wrapper executable
chmod +x "$APP_PATH/Contents/MacOS/TimeTracker_wrapper"

# Rename original binary
mv "$APP_PATH/Contents/MacOS/TimeTracker" "$APP_PATH/Contents/MacOS/TimeTracker_real"

# Make wrapper the main executable
mv "$APP_PATH/Contents/MacOS/TimeTracker_wrapper" "$APP_PATH/Contents/MacOS/TimeTracker"

echo "🔧 Bundling all dependencies with complete isolation..."

# Use the enhanced bundling script
./bundle_isolated_qt.sh "$APP_PATH"

echo "🔍 Verifying complete isolation..."

# Check for any external dependencies
echo "Checking for external Qt dependencies:"
if otool -L "$APP_PATH/Contents/MacOS/TimeTracker_real" | grep -E "(homebrew|usr/local)" | grep -v "usr/lib/system"; then
    echo "⚠️  Warning: External dependencies found"
else
    echo "✅ No external dependencies found"
fi

echo "📊 Final app size:"
du -sh "$APP_PATH"

echo "✅ Completely isolated Qt application created!"
echo "🚀 Run with: open $APP_PATH" 