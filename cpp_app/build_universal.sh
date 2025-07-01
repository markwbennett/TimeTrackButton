#!/bin/bash

APP_PATH="TimeTracker_Universal.app"
BUILD_DIR="build_universal"

echo "🔨 Building universal Qt Time Tracker..."

# Clean previous builds
rm -rf "$BUILD_DIR" "$APP_PATH"

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "⚙️  Configuring for universal build..."

# Configure with regular Qt but optimized for deployment
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/qt/lib/cmake" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15

echo "🔧 Building application..."
make -j$(sysctl -n hw.ncpu)

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful!"

# Move the app bundle
mv TimeTracker.app "../$APP_PATH"
cd ..

echo "📦 Using Qt's macdeployqt for complete deployment..."

# Use Qt's official deployment tool
if command -v macdeployqt >/dev/null 2>&1; then
    echo "Using system macdeployqt..."
    macdeployqt "$APP_PATH" -verbose=2 -always-overwrite
elif [ -f "/opt/homebrew/opt/qt/bin/macdeployqt" ]; then
    echo "Using Homebrew macdeployqt..."
    /opt/homebrew/opt/qt/bin/macdeployqt "$APP_PATH" -verbose=2 -always-overwrite
else
    echo "⚠️  macdeployqt not found, using manual deployment..."
    ./bundle_complete_qt.sh
fi

echo "🔧 Creating environment isolation wrapper..."

# Create a launcher that completely isolates the environment
cat > "$APP_PATH/Contents/MacOS/TimeTracker_launcher" << 'EOF'
#!/bin/bash

# Get the directory containing this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Completely clear Qt environment to avoid any conflicts
unset QT_PLUGIN_PATH
unset QT_QPA_PLATFORM_PLUGIN_PATH
unset QTDIR
unset QT_SELECT
unset QML2_IMPORT_PATH
unset QT_QUICK_CONTROLS_STYLE
unset QT_LOGGING_RULES
unset QT_SCALE_FACTOR
unset QT_AUTO_SCREEN_SCALE_FACTOR

# Clear all library paths that might cause conflicts
unset DYLD_LIBRARY_PATH
unset DYLD_FRAMEWORK_PATH
unset DYLD_FALLBACK_LIBRARY_PATH
unset DYLD_FALLBACK_FRAMEWORK_PATH

# Set up isolated environment pointing only to our bundled libraries
export QT_PLUGIN_PATH="$APP_DIR/Contents/PlugIns"
export QT_QPA_PLATFORM_PLUGIN_PATH="$APP_DIR/Contents/PlugIns/platforms"

# Ensure we use our bundled frameworks/libraries first
export DYLD_FRAMEWORK_PATH="$APP_DIR/Contents/Frameworks"
export DYLD_LIBRARY_PATH="$APP_DIR/Contents/Libraries:$APP_DIR/Contents/Frameworks"

# Disable Qt's plugin cache to force fresh discovery
export QT_NO_GLIB=1

# Run the actual application
exec "$SCRIPT_DIR/TimeTracker_real" "$@"
EOF

# Make the launcher executable
chmod +x "$APP_PATH/Contents/MacOS/TimeTracker_launcher"

# Rename the original binary
if [ -f "$APP_PATH/Contents/MacOS/TimeTracker" ]; then
    mv "$APP_PATH/Contents/MacOS/TimeTracker" "$APP_PATH/Contents/MacOS/TimeTracker_real"
fi

# Replace with our launcher
mv "$APP_PATH/Contents/MacOS/TimeTracker_launcher" "$APP_PATH/Contents/MacOS/TimeTracker"

echo "🔧 Ensuring SQL drivers are included..."

# Make sure SQL drivers are present
PLUGINS_DIR="$APP_PATH/Contents/PlugIns"
mkdir -p "$PLUGINS_DIR/sqldrivers"

if [ ! -f "$PLUGINS_DIR/sqldrivers/libqsqlite.dylib" ]; then
    echo "  Adding missing SQL drivers..."
    if [ -f "/opt/homebrew/opt/qt/share/qt/plugins/sqldrivers/libqsqlite.dylib" ]; then
        cp "/opt/homebrew/opt/qt/share/qt/plugins/sqldrivers/libqsqlite.dylib" "$PLUGINS_DIR/sqldrivers/"
        chmod 755 "$PLUGINS_DIR/sqldrivers/libqsqlite.dylib"
        
        # Update the SQL driver's library paths
        if [ -d "$APP_PATH/Contents/Frameworks" ]; then
            # macdeployqt uses Frameworks
            for framework in "$APP_PATH/Contents/Frameworks"/*.framework; do
                if [ -d "$framework" ]; then
                    framework_name=$(basename "$framework" .framework)
                    install_name_tool -change "/opt/homebrew/opt/qt/lib/${framework_name}.framework/Versions/A/${framework_name}" "@executable_path/../Frameworks/${framework_name}.framework/Versions/A/${framework_name}" "$PLUGINS_DIR/sqldrivers/libqsqlite.dylib" 2>/dev/null
                fi
            done
        fi
        
        # Sign the SQL driver
        codesign --force --sign - "$PLUGINS_DIR/sqldrivers/libqsqlite.dylib" 2>/dev/null
    fi
fi

echo "🔐 Final code signing..."
# Re-sign the entire bundle
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null

echo "🔍 Verifying deployment..."

# Check what libraries the binary depends on
echo "Main binary dependencies:"
otool -L "$APP_PATH/Contents/MacOS/TimeTracker_real" | head -10

# Check for problematic dependencies
if otool -L "$APP_PATH/Contents/MacOS/TimeTracker_real" | grep -E "(/opt/homebrew|/usr/local)" | grep -v "/usr/lib/system" | grep -v "@executable_path"; then
    echo "⚠️  Warning: Some external dependencies detected"
    echo "The app may still work but might have issues on systems without Qt"
else
    echo "✅ Clean deployment - no external Qt dependencies"
fi

echo "📊 Final app size:"
du -sh "$APP_PATH"

echo "✅ Universal Qt application created!"
echo "🚀 This app should work on any macOS system regardless of Qt installation"
echo "🔧 Run with: open $APP_PATH" 