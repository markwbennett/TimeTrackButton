#!/bin/bash

APP_PATH="${1:-TimeTracker_Static.app}"
LIBS_PATH="$APP_PATH/Contents/Libraries"
PLUGINS_PATH="$APP_PATH/Contents/PlugIns"
BINARY_PATH="$APP_PATH/Contents/MacOS/TimeTracker_real"

echo "🔧 Creating completely isolated Qt bundle for $APP_PATH..."

# Create directories
mkdir -p "$LIBS_PATH"
mkdir -p "$PLUGINS_PATH/platforms"
mkdir -p "$PLUGINS_PATH/sqldrivers"
mkdir -p "$PLUGINS_PATH/imageformats"

# Qt libraries we need - using a specific naming scheme to avoid conflicts
QT_LIBS=(
    "QtCore"
    "QtGui" 
    "QtWidgets"
    "QtSql"
    "QtMultimedia"
    "QtNetwork"
)

echo "📦 Copying and renaming Qt libraries to avoid conflicts..."
for lib in "${QT_LIBS[@]}"; do
    src_dylib="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
    if [ -f "$src_dylib" ]; then
        echo "  Copying $lib..."
        # Use a unique prefix to avoid conflicts
        cp "$src_dylib" "$LIBS_PATH/libTimeTracker${lib}.dylib"
        chmod 755 "$LIBS_PATH/libTimeTracker${lib}.dylib"
        # Update the library ID immediately
        install_name_tool -id "@executable_path/../Libraries/libTimeTracker${lib}.dylib" "$LIBS_PATH/libTimeTracker${lib}.dylib"
    fi
done

# Copy essential dependencies only
ESSENTIAL_DEPS=(
    "/opt/homebrew/opt/icu4c@77/lib/libicui18n.77.dylib"
    "/opt/homebrew/opt/icu4c@77/lib/libicuuc.77.dylib"
    "/opt/homebrew/opt/icu4c@77/lib/libicudata.77.dylib"
    "/opt/homebrew/opt/pcre2/lib/libpcre2-16.0.dylib"
    "/opt/homebrew/opt/zstd/lib/libzstd.1.dylib"
    "/opt/homebrew/opt/double-conversion/lib/libdouble-conversion.3.dylib"
    "/opt/homebrew/opt/libb2/lib/libb2.1.dylib"
)

echo "📦 Copying essential dependencies..."
for dep in "${ESSENTIAL_DEPS[@]}"; do
    if [ -f "$dep" ]; then
        dep_name=$(basename "$dep")
        echo "  Copying $dep_name..."
        cp "$dep" "$LIBS_PATH/libTimeTracker_$dep_name"
        chmod 755 "$LIBS_PATH/libTimeTracker_$dep_name"
        # Update library ID
        install_name_tool -id "@executable_path/../Libraries/libTimeTracker_$dep_name" "$LIBS_PATH/libTimeTracker_$dep_name"
    fi
done

# Copy Qt plugins with renaming
echo "📦 Copying Qt plugins..."
PLUGIN_SOURCES=(
    "/opt/homebrew/opt/qt/share/qt/plugins/platforms/libqcocoa.dylib"
)

for plugin_src in "${PLUGIN_SOURCES[@]}"; do
    if [ -f "$plugin_src" ]; then
        plugin_name=$(basename "$plugin_src")
        echo "  Copying platform plugin $plugin_name..."
        cp "$plugin_src" "$PLUGINS_PATH/platforms/libTimeTracker_$plugin_name"
        chmod 755 "$PLUGINS_PATH/platforms/libTimeTracker_$plugin_name"
    fi
done

# Copy SQL drivers
echo "📦 Copying SQL drivers..."
SQL_DRIVERS=(
    "/opt/homebrew/opt/qt/share/qt/plugins/sqldrivers/libqsqlite.dylib"
)

for driver_src in "${SQL_DRIVERS[@]}"; do
    if [ -f "$driver_src" ]; then
        driver_name=$(basename "$driver_src")
        echo "  Copying SQL driver $driver_name..."
        cp "$driver_src" "$PLUGINS_PATH/sqldrivers/libTimeTracker_$driver_name"
        chmod 755 "$PLUGINS_PATH/sqldrivers/libTimeTracker_$driver_name"
    fi
done

# Create qt.conf with explicit paths
echo "📝 Creating isolated qt.conf..."
cat > "$APP_PATH/Contents/Resources/qt.conf" << EOF
[Paths]
Plugins = PlugIns
Libraries = Libraries
Imports = Resources/qml
Qml2Imports = Resources/qml
EOF

echo "🔗 Updating all library paths for complete isolation..."

# Function to update library paths with our renamed libraries
update_isolated_library_paths() {
    local target_file="$1"
    local file_type="$2"
    
    if [ ! -f "$target_file" ]; then
        return
    fi
    
    echo "  Updating $file_type: $(basename "$target_file")"
    
    # Update Qt library paths to our renamed versions
    for lib in "${QT_LIBS[@]}"; do
        old_path="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
        new_path="@executable_path/../Libraries/libTimeTracker${lib}.dylib"
        install_name_tool -change "$old_path" "$new_path" "$target_file" 2>/dev/null
        
        # Also handle any references to the renamed libs
        old_renamed="@executable_path/../Libraries/lib${lib}.dylib"
        install_name_tool -change "$old_renamed" "$new_path" "$target_file" 2>/dev/null
    done
    
    # Update dependency paths to our renamed versions
    for dep in "${ESSENTIAL_DEPS[@]}"; do
        dep_name=$(basename "$dep")
        new_path="@executable_path/../Libraries/libTimeTracker_$dep_name"
        install_name_tool -change "$dep" "$new_path" "$target_file" 2>/dev/null
        
        # Handle shortened names too
        short_name="${dep_name#lib}"
        install_name_tool -change "/opt/homebrew/lib/$short_name" "$new_path" "$target_file" 2>/dev/null
    done
}

# Update main binary
update_isolated_library_paths "$BINARY_PATH" "main binary"

# Update all Qt libraries
for lib in "${QT_LIBS[@]}"; do
    lib_file="$LIBS_PATH/libTimeTracker${lib}.dylib"
    update_isolated_library_paths "$lib_file" "Qt library $lib"
done

# Update all dependency libraries
for dep in "${ESSENTIAL_DEPS[@]}"; do
    dep_name=$(basename "$dep")
    dep_file="$LIBS_PATH/libTimeTracker_$dep_name"
    update_isolated_library_paths "$dep_file" "dependency $dep_name"
done

# Update plugins
for plugin_file in "$PLUGINS_PATH/platforms"/libTimeTracker_*.dylib; do
    if [ -f "$plugin_file" ]; then
        update_isolated_library_paths "$plugin_file" "platform plugin"
    fi
done

# Update SQL drivers
for driver_file in "$PLUGINS_PATH/sqldrivers"/libTimeTracker_*.dylib; do
    if [ -f "$driver_file" ]; then
        update_isolated_library_paths "$driver_file" "SQL driver"
    fi
done

echo "🧹 Stripping debug symbols..."
# Strip all libraries and plugins
for file in "$LIBS_PATH"/*.dylib "$PLUGINS_PATH/platforms"/*.dylib "$PLUGINS_PATH/sqldrivers"/*.dylib "$BINARY_PATH"; do
    if [ -f "$file" ]; then
        strip -x "$file" 2>/dev/null
    fi
done

echo "🔐 Code signing all components..."
# Sign all libraries
for file in "$LIBS_PATH"/*.dylib; do
    if [ -f "$file" ]; then
        echo "  Signing $(basename "$file")..."
        codesign --force --sign - "$file" 2>/dev/null
    fi
done

# Sign plugins
for file in "$PLUGINS_PATH/platforms"/*.dylib "$PLUGINS_PATH/sqldrivers"/*.dylib; do
    if [ -f "$file" ]; then
        echo "  Signing $(basename "$file")..."
        codesign --force --sign - "$file" 2>/dev/null
    fi
done

# Sign main binary
echo "  Signing main binary..."
codesign --force --sign - "$BINARY_PATH" 2>/dev/null

# Sign entire app bundle
echo "  Signing app bundle..."
codesign --force --deep --sign - "$APP_PATH" 2>/dev/null

echo "📊 Bundle size:"
du -sh "$APP_PATH"

echo "✅ Completely isolated Qt bundle created!"

# Verify isolation
echo "🔍 Verifying complete isolation..."
if otool -L "$BINARY_PATH" | grep -E "(homebrew|usr/local)" | grep -v "usr/lib/system"; then
    echo "⚠️  Warning: External dependencies still found:"
    otool -L "$BINARY_PATH" | grep -E "(homebrew|usr/local)" | grep -v "usr/lib/system"
else
    echo "✅ Binary is completely isolated!"
fi 