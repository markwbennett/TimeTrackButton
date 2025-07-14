#!/bin/bash

# Universal build script for TimeTracker with minimal Qt bundling
cd "$(dirname "$0")"

echo "🔨 Building TimeTracker with minimal dependencies..."

# Create build directory
mkdir -p build_universal
cd build_universal

# Configure with CMake for universal binary
cmake .. \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0

# Build the application
make -j$(sysctl -n hw.ncpu)

# Create the app bundle directory structure
APP_NAME="TimeTracker_Universal.app"
rm -rf "../$APP_NAME"
mkdir -p "../$APP_NAME/Contents/"{MacOS,Resources,Frameworks,PlugIns}

# Copy the executable
cp TimeTracker "../$APP_NAME/Contents/MacOS/TimeTracker_real"

# Create minimal Info.plist
cat > "../$APP_NAME/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TimeTracker</string>
    <key>CFBundleIdentifier</key>
    <string>org.iacls.timetracker</string>
    <key>CFBundleName</key>
    <string>IACLS Time Tracker</string>
    <key>CFBundleVersion</key>
    <string>2.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Copy resources
cp ../../assets/bells-2-31725.mp3 "../$APP_NAME/Contents/Resources/"
cp ../icon.icns "../$APP_NAME/Contents/Resources/" 2>/dev/null || echo "⚠️  icon.icns not found, skipping"

echo "📦 Bundling only required Qt components..."

# Function to get Qt installation path
get_qt_path() {
    if [ -d "/opt/homebrew/lib" ]; then
        echo "/opt/homebrew"
    elif [ -d "/usr/local/lib" ]; then
        echo "/usr/local"
    else
        echo "❌ Qt installation not found" >&2
        exit 1
    fi
}

QT_PATH=$(get_qt_path)
FRAMEWORKS_DIR="../$APP_NAME/Contents/Frameworks"
PLUGINS_DIR="../$APP_NAME/Contents/PlugIns"

# Only bundle frameworks actually used by the application
REQUIRED_FRAMEWORKS=(
    "QtCore"
    "QtGui" 
    "QtWidgets"
    "QtSql"
    "QtMultimedia"
    "QtNetwork"  # Required by QtMultimedia
)

echo "🔗 Bundling required Qt frameworks..."
for framework in "${REQUIRED_FRAMEWORKS[@]}"; do
    framework_path="$QT_PATH/lib/$framework.framework"
    if [ -d "$framework_path" ]; then
        echo "  → $framework"
        cp -R "$framework_path" "$FRAMEWORKS_DIR/"
        
        # Clean up unnecessary files from framework
        find "$FRAMEWORKS_DIR/$framework.framework" -name "Headers" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$FRAMEWORKS_DIR/$framework.framework" -name "*_debug*" -delete 2>/dev/null || true
    else
        echo "⚠️  Framework $framework not found at $framework_path"
    fi
done

# Bundle only essential Qt plugins
echo "🔌 Bundling essential Qt plugins..."

# Platform plugin (required)
mkdir -p "$PLUGINS_DIR/platforms"
if [ -f "$QT_PATH/plugins/platforms/libqcocoa.dylib" ]; then
    cp "$QT_PATH/plugins/platforms/libqcocoa.dylib" "$PLUGINS_DIR/platforms/"
    echo "  → Platform: Cocoa"
else
    echo "❌ Critical: libqcocoa.dylib not found"
    exit 1
fi

# SQL driver (required for SQLite)
mkdir -p "$PLUGINS_DIR/sqldrivers"
if [ -f "$QT_PATH/plugins/sqldrivers/libqsqlite.dylib" ]; then
    cp "$QT_PATH/plugins/sqldrivers/libqsqlite.dylib" "$PLUGINS_DIR/sqldrivers/"
    echo "  → SQL: SQLite driver"
else
    echo "❌ Critical: libqsqlite.dylib not found"
    exit 1
fi

# Audio plugin (required for multimedia)
mkdir -p "$PLUGINS_DIR/multimedia"
if [ -f "$QT_PATH/plugins/multimedia/libdarwinmediaplugin.dylib" ]; then
    cp "$QT_PATH/plugins/multimedia/libdarwinmediaplugin.dylib" "$PLUGINS_DIR/multimedia/"
    echo "  → Multimedia: Darwin media plugin"
fi

echo "🔧 Fixing library paths..."

# Fix framework internal paths
for framework in "${REQUIRED_FRAMEWORKS[@]}"; do
    framework_binary="$FRAMEWORKS_DIR/$framework.framework/$framework"
    if [ -f "$framework_binary" ]; then
        # Update framework's internal references
        install_name_tool -id "@executable_path/../Frameworks/$framework.framework/$framework" "$framework_binary" 2>/dev/null || true
        
        # Fix references to other Qt frameworks
        for dep_framework in "${REQUIRED_FRAMEWORKS[@]}"; do
            if [ "$framework" != "$dep_framework" ]; then
                install_name_tool -change "$QT_PATH/lib/$dep_framework.framework/Versions/*//$dep_framework" \
                    "@executable_path/../Frameworks/$dep_framework.framework/$dep_framework" \
                    "$framework_binary" 2>/dev/null || true
                install_name_tool -change "$QT_PATH/lib/$dep_framework.framework/$dep_framework" \
                    "@executable_path/../Frameworks/$dep_framework.framework/$dep_framework" \
                    "$framework_binary" 2>/dev/null || true
            fi
        done
    fi
done

# Fix main executable paths
MAIN_EXECUTABLE="../$APP_NAME/Contents/MacOS/TimeTracker_real"
for framework in "${REQUIRED_FRAMEWORKS[@]}"; do
    install_name_tool -change "$QT_PATH/lib/$framework.framework/Versions/*/$framework" \
        "@executable_path/../Frameworks/$framework.framework/$framework" \
        "$MAIN_EXECUTABLE" 2>/dev/null || true
    install_name_tool -change "$QT_PATH/lib/$framework.framework/$framework" \
        "@executable_path/../Frameworks/$framework.framework/$framework" \
        "$MAIN_EXECUTABLE" 2>/dev/null || true
done

# Fix plugin paths
find "$PLUGINS_DIR" -name "*.dylib" -exec install_name_tool -change "$QT_PATH/lib/QtCore.framework/Versions/*/QtCore" "@executable_path/../Frameworks/QtCore.framework/QtCore" {} \; 2>/dev/null || true
find "$PLUGINS_DIR" -name "*.dylib" -exec install_name_tool -change "$QT_PATH/lib/QtGui.framework/Versions/*/QtGui" "@executable_path/../Frameworks/QtGui.framework/QtGui" {} \; 2>/dev/null || true
find "$PLUGINS_DIR" -name "*.dylib" -exec install_name_tool -change "$QT_PATH/lib/QtWidgets.framework/Versions/*/QtWidgets" "@executable_path/../Frameworks/QtWidgets.framework/QtWidgets" {} \; 2>/dev/null || true

# Create qt.conf for plugin discovery
cat > "../$APP_NAME/Contents/Resources/qt.conf" << 'EOF'
[Paths]
Plugins = PlugIns
EOF

# Create launcher script that ensures clean Qt environment
cat > "../$APP_NAME/Contents/MacOS/TimeTracker" << 'EOF'
#!/bin/bash

# Get the directory containing this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Clear Qt environment to avoid conflicts
unset QT_PLUGIN_PATH
unset QT_QPA_PLATFORM_PLUGIN_PATH
unset QTDIR
unset DYLD_LIBRARY_PATH
unset DYLD_FRAMEWORK_PATH

# Set up isolated environment pointing only to our bundled libraries
export QT_PLUGIN_PATH="$APP_DIR/Contents/PlugIns"
export QT_QPA_PLATFORM_PLUGIN_PATH="$APP_DIR/Contents/PlugIns/platforms"
export DYLD_FRAMEWORK_PATH="$APP_DIR/Contents/Frameworks"

# Run the actual application
exec "$SCRIPT_DIR/TimeTracker_real" "$@"
EOF

chmod +x "../$APP_NAME/Contents/MacOS/TimeTracker"

echo "📊 Bundle size analysis:"
du -sh "../$APP_NAME"
echo ""
echo "Framework sizes:"
du -sh "../$APP_NAME/Contents/Frameworks/"* 2>/dev/null | sort -hr || echo "No frameworks bundled"

echo ""
echo "✅ Minimal TimeTracker bundle created at: $APP_NAME"
echo "🎯 Only essential Qt components included:"
echo "   • QtCore, QtGui, QtWidgets (UI)"
echo "   • QtSql (SQLite database)"  
echo "   • QtMultimedia + QtNetwork (audio)"
echo "   • Essential plugins only"
echo ""
echo "🚫 Excluded unnecessary components:"
echo "   • QtDBus (not used)"
echo "   • Development headers"
echo "   • Debug libraries"
echo "   • Optional plugins" 