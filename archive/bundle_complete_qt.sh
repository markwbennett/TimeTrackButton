#!/bin/bash

APP_PATH="TimeTracker_CPP.app"
LIBS_PATH="$APP_PATH/Contents/Libraries"
PLUGINS_PATH="$APP_PATH/Contents/PlugIns"
BINARY_PATH="$APP_PATH/Contents/MacOS/TimeTracker"

echo "🔧 Creating completely self-contained Qt bundle..."

# Create Libraries and PlugIns directories
mkdir -p "$LIBS_PATH"
mkdir -p "$PLUGINS_PATH/platforms"
mkdir -p "$PLUGINS_PATH/sqldrivers"

# Qt libraries we need
QT_LIBS=(
    "QtCore"
    "QtGui" 
    "QtWidgets"
    "QtSql"
    "QtMultimedia"
    "QtNetwork"
)

# Additional dependencies that Qt libraries need
HOMEBREW_DEPS=(
    "/opt/homebrew/opt/icu4c@77/lib/libicui18n.77.dylib"
    "/opt/homebrew/opt/icu4c@77/lib/libicuuc.77.dylib"
    "/opt/homebrew/opt/icu4c@77/lib/libicudata.77.dylib"
    "/opt/homebrew/opt/glib/lib/libglib-2.0.0.dylib"
    "/opt/homebrew/opt/double-conversion/lib/libdouble-conversion.3.dylib"
    "/opt/homebrew/opt/libb2/lib/libb2.1.dylib"
    "/opt/homebrew/opt/pcre2/lib/libpcre2-16.0.dylib"
    "/opt/homebrew/opt/zstd/lib/libzstd.1.dylib"
    "/opt/homebrew/opt/glib/lib/libgthread-2.0.0.dylib"
    "/opt/homebrew/opt/pcre2/lib/libpcre2-8.0.dylib"
    "/opt/homebrew/opt/gettext/lib/libintl.8.dylib"
    "/opt/homebrew/opt/freetype/lib/libfreetype.6.dylib"
    "/opt/homebrew/opt/libpng/lib/libpng16.16.dylib"
    "/opt/homebrew/opt/harfbuzz/lib/libharfbuzz.0.dylib"
    "/opt/homebrew/opt/graphite2/lib/libgraphite2.3.dylib"
    "/opt/homebrew/opt/brotli/lib/libbrotlidec.1.dylib"
    "/opt/homebrew/opt/brotli/lib/libbrotlicommon.1.dylib"
    "/opt/homebrew/opt/md4c/lib/libmd4c.0.dylib"
    "/opt/homebrew/opt/dbus/lib/libdbus-1.3.dylib"
)

# Copy Qt libraries
for lib in "${QT_LIBS[@]}"; do
    src_dylib="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
    if [ -f "$src_dylib" ]; then
        echo "📦 Copying $lib..."
        cp "$src_dylib" "$LIBS_PATH/lib${lib}.dylib"
        chmod 755 "$LIBS_PATH/lib${lib}.dylib"
    fi
done

# Copy all Homebrew dependencies
echo "📦 Copying dependencies..."
for dep in "${HOMEBREW_DEPS[@]}"; do
    if [ -f "$dep" ]; then
        dep_name=$(basename "$dep")
        echo "  Copying $dep_name..."
        cp "$dep" "$LIBS_PATH/"
        chmod 755 "$LIBS_PATH/$dep_name"
    fi
done

# Copy Qt plugins
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

# Copy SQL drivers
echo "📦 Copying SQL drivers..."
SQL_DRIVERS=(
    "/opt/homebrew/opt/qt/share/qt/plugins/sqldrivers/libqsqlite.dylib"
)

for driver_src in "${SQL_DRIVERS[@]}"; do
    if [ -f "$driver_src" ]; then
        driver_name=$(basename "$driver_src")
        echo "  Copying $driver_name..."
        cp "$driver_src" "$PLUGINS_PATH/sqldrivers/"
        chmod 755 "$PLUGINS_PATH/sqldrivers/$driver_name"
    fi
done

# Create qt.conf
echo "📝 Creating qt.conf..."
cat > "$APP_PATH/Contents/Resources/qt.conf" << EOF
[Paths]
Plugins = PlugIns
Libraries = Libraries
EOF

echo "🔗 Updating library paths..."

# Function to update library paths
update_library_paths() {
    local target_file="$1"
    local file_type="$2"
    
    if [ ! -f "$target_file" ]; then
        return
    fi
    
    echo "  Updating $file_type: $(basename "$target_file")"
    
    # Update Qt library paths
    for lib in "${QT_LIBS[@]}"; do
        old_path="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
        new_path="@executable_path/../Libraries/lib${lib}.dylib"
        install_name_tool -change "$old_path" "$new_path" "$target_file" 2>/dev/null
    done
    
    # Update dependency paths
    for dep in "${HOMEBREW_DEPS[@]}"; do
        dep_name=$(basename "$dep")
        new_path="@executable_path/../Libraries/$dep_name"
        install_name_tool -change "$dep" "$new_path" "$target_file" 2>/dev/null
    done
    
    # Update the library's own ID if it's a library
    if [[ "$target_file" == *.dylib ]]; then
        lib_name=$(basename "$target_file")
        install_name_tool -id "@executable_path/../Libraries/$lib_name" "$target_file" 2>/dev/null
    fi
}

# Update main binary
update_library_paths "$BINARY_PATH" "binary"

# Update all Qt libraries
for lib in "${QT_LIBS[@]}"; do
    lib_file="$LIBS_PATH/lib${lib}.dylib"
    update_library_paths "$lib_file" "Qt library"
done

# Update all dependency libraries
for dep in "${HOMEBREW_DEPS[@]}"; do
    dep_name=$(basename "$dep")
    dep_file="$LIBS_PATH/$dep_name"
    update_library_paths "$dep_file" "dependency"
done

# Update plugins
for plugin_file in "$PLUGINS_PATH/platforms"/*.dylib; do
    update_library_paths "$plugin_file" "plugin"
done

# Update SQL drivers
for driver_file in "$PLUGINS_PATH/sqldrivers"/*.dylib; do
    update_library_paths "$driver_file" "SQL driver"
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
for file in "$PLUGINS_PATH/platforms"/*.dylib; do
    if [ -f "$file" ]; then
        echo "  Signing $(basename "$file")..."
        codesign --force --sign - "$file" 2>/dev/null
    fi
done

# Sign SQL drivers
for file in "$PLUGINS_PATH/sqldrivers"/*.dylib; do
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

echo "✅ Completely self-contained Qt bundle created!"
echo "🔍 Verifying no external dependencies..."

# Verify no Homebrew dependencies remain
if otool -L "$BINARY_PATH" | grep -q "/opt/homebrew"; then
    echo "⚠️  Warning: Binary still has Homebrew dependencies"
    otool -L "$BINARY_PATH" | grep "/opt/homebrew"
else
    echo "✅ Binary is clean of Homebrew dependencies"
fi 