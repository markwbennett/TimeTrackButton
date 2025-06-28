#!/bin/bash

APP_PATH="TimeTracker_CPP.app"
LIBS_PATH="$APP_PATH/Contents/Libraries"
BINARY_PATH="$APP_PATH/Contents/MacOS/TimeTracker"

echo "🔧 Creating minimal Qt bundle..."

# Create Libraries directory
mkdir -p "$LIBS_PATH"

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

echo "🧹 Stripping debug symbols..."
for lib in "${QT_LIBS[@]}"; do
    lib_file="$LIBS_PATH/lib${lib}.dylib"
    if [ -f "$lib_file" ]; then
        strip -x "$lib_file" 2>/dev/null
    fi
done

# Strip the main binary
strip -x "$BINARY_PATH" 2>/dev/null

echo "📊 Bundle size:"
du -sh "$APP_PATH"

echo "✅ Minimal Qt bundle created!" 