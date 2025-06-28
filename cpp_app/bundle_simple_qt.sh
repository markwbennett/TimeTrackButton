#!/bin/bash

APP_PATH="TimeTracker_CPP.app"
LIBS_PATH="$APP_PATH/Contents/Libraries"
PLUGINS_PATH="$APP_PATH/Contents/PlugIns"
BINARY_PATH="$APP_PATH/Contents/MacOS/TimeTracker"

echo "🔧 Creating minimal Qt bundle..."

# Create Libraries and PlugIns directories
mkdir -p "$LIBS_PATH"
mkdir -p "$PLUGINS_PATH/platforms"

# Qt libraries we need (just the dylib files)
QT_LIBS=(
    "QtCore"
    "QtGui" 
    "QtWidgets"
    "QtSql"
    "QtMultimedia"
    "QtNetwork"
)

# Copy just the dylib files
for lib in "${QT_LIBS[@]}"; do
    src_dylib="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
    if [ -f "$src_dylib" ]; then
        echo "📦 Copying $lib..."
        cp "$src_dylib" "$LIBS_PATH/lib${lib}.dylib"
        chmod 755 "$LIBS_PATH/lib${lib}.dylib"
    fi
done

# Copy essential Qt plugins
echo "📦 Copying Qt plugins..."
PLUGIN_SOURCES=(
    "/opt/homebrew/opt/qt/share/qt/plugins/platforms/libqcocoa.dylib"
)

for plugin_src in "${PLUGIN_SOURCES[@]}"; do
    if [ -f "$plugin_src" ]; then
        plugin_name=$(basename "$plugin_src")
        echo "  Copying $plugin_name..."
        cp "$plugin_src" "$PLUGINS_PATH/platforms/"
        chmod 755 "$PLUGINS_PATH/platforms/$plugin_name"
    fi
done

# Create qt.conf to tell Qt where to find plugins and libraries
echo "📝 Creating qt.conf..."
cat > "$APP_PATH/Contents/Resources/qt.conf" << EOF
[Paths]
Plugins = PlugIns
Libraries = Libraries
EOF

echo "🔗 Updating library paths..."

# Update the binary to use bundled libraries
for lib in "${QT_LIBS[@]}"; do
    old_path="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
    new_path="@executable_path/../Libraries/lib${lib}.dylib"
    
    # Update the main binary
    install_name_tool -change "$old_path" "$new_path" "$BINARY_PATH" 2>/dev/null
    
    # Update inter-library dependencies
    for other_lib in "${QT_LIBS[@]}"; do
        if [ "$lib" != "$other_lib" ]; then
            lib_file="$LIBS_PATH/lib${lib}.dylib"
            if [ -f "$lib_file" ]; then
                old_dep="/opt/homebrew/opt/qt/lib/${other_lib}.framework/Versions/A/${other_lib}"
                new_dep="@executable_path/../Libraries/lib${other_lib}.dylib"
                install_name_tool -change "$old_dep" "$new_dep" "$lib_file" 2>/dev/null
            fi
        fi
    done
done

# Update plugin dependencies
echo "🔗 Updating plugin paths..."
for plugin_file in "$PLUGINS_PATH/platforms"/*.dylib; do
    if [ -f "$plugin_file" ]; then
        plugin_name=$(basename "$plugin_file")
        echo "  Updating $plugin_name..."
        
        for lib in "${QT_LIBS[@]}"; do
            old_path="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
            new_path="@executable_path/../Libraries/lib${lib}.dylib"
            install_name_tool -change "$old_path" "$new_path" "$plugin_file" 2>/dev/null
        done
    fi
done

echo "🧹 Stripping debug symbols..."
for lib in "${QT_LIBS[@]}"; do
    lib_file="$LIBS_PATH/lib${lib}.dylib"
    if [ -f "$lib_file" ]; then
        strip -x "$lib_file" 2>/dev/null
    fi
done

# Strip plugins
for plugin_file in "$PLUGINS_PATH/platforms"/*.dylib; do
    if [ -f "$plugin_file" ]; then
        strip -x "$plugin_file" 2>/dev/null
    fi
done

# Strip the main binary
strip -x "$BINARY_PATH" 2>/dev/null

echo "🔐 Code signing all libraries and plugins..."
# Sign each Qt library
for lib in "${QT_LIBS[@]}"; do
    lib_file="$LIBS_PATH/lib${lib}.dylib"
    if [ -f "$lib_file" ]; then
        echo "  Signing lib${lib}.dylib..."
        codesign --force --sign - "$lib_file" 2>/dev/null
    fi
done

# Sign plugins
for plugin_file in "$PLUGINS_PATH/platforms"/*.dylib; do
    if [ -f "$plugin_file" ]; then
        plugin_name=$(basename "$plugin_file")
        echo "  Signing $plugin_name..."
        codesign --force --sign - "$plugin_file" 2>/dev/null
    fi
done

# Sign the main binary
echo "  Signing main binary..."
codesign --force --sign - "$BINARY_PATH" 2>/dev/null

# Sign the entire app bundle with --deep to ensure all components are signed
echo "  Signing app bundle..."
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null

echo "📊 Bundle size:"
du -sh "$APP_PATH"

echo "✅ Minimal Qt bundle created and signed!" 