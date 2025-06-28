#!/bin/bash

APP_PATH="TimeTracker_CPP.app"
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"
BINARY_PATH="$APP_PATH/Contents/MacOS/TimeTracker"

echo "🔧 Creating minimal Qt bundle..."

# Remove any existing frameworks directory
rm -rf "$FRAMEWORKS_PATH"

# Create Frameworks directory
mkdir -p "$FRAMEWORKS_PATH"

# Qt frameworks we need
QT_LIBS=(
    "QtCore"
    "QtGui" 
    "QtWidgets"
    "QtSql"
    "QtMultimedia"
    "QtNetwork"
)

# Copy only the essential dylib files from each framework
for lib in "${QT_LIBS[@]}"; do
    src_framework="/opt/homebrew/opt/qt/lib/${lib}.framework"
    if [ -d "$src_framework" ]; then
        echo "📦 Processing $lib..."
        
        # Create minimal framework structure
        framework_path="$FRAMEWORKS_PATH/${lib}.framework/Versions/A"
        mkdir -p "$framework_path"
        
        # Copy only the main dylib
        cp "$src_framework/Versions/A/$lib" "$framework_path/"
        
        # Make sure we have write permissions
        chmod 755 "$framework_path/$lib"
        
        # Create version symlinks
        cd "$FRAMEWORKS_PATH/${lib}.framework"
        ln -sf "Versions/A/$lib" "$lib"
        cd "Versions"
        ln -sf "A" "Current"
        cd - > /dev/null
    fi
done

echo "🔗 Updating library paths..."

# Update the binary to use bundled libraries
for lib in "${QT_LIBS[@]}"; do
    old_path="/opt/homebrew/opt/qt/lib/${lib}.framework/Versions/A/${lib}"
    new_path="@executable_path/../Frameworks/${lib}.framework/Versions/A/${lib}"
    
    # Update the main binary
    install_name_tool -change "$old_path" "$new_path" "$BINARY_PATH" 2>/dev/null
    
    # Update inter-framework dependencies
    for other_lib in "${QT_LIBS[@]}"; do
        if [ "$lib" != "$other_lib" ]; then
            framework_dylib="$FRAMEWORKS_PATH/${lib}.framework/Versions/A/${lib}"
            if [ -f "$framework_dylib" ]; then
                old_dep="/opt/homebrew/opt/qt/lib/${other_lib}.framework/Versions/A/${other_lib}"
                new_dep="@executable_path/../Frameworks/${other_lib}.framework/Versions/A/${other_lib}"
                install_name_tool -change "$old_dep" "$new_dep" "$framework_dylib" 2>/dev/null
            fi
        fi
    done
done

echo "🧹 Stripping debug symbols..."
for lib in "${QT_LIBS[@]}"; do
    framework_dylib="$FRAMEWORKS_PATH/${lib}.framework/Versions/A/${lib}"
    if [ -f "$framework_dylib" ]; then
        strip -x "$framework_dylib" 2>/dev/null
    fi
done

# Strip the main binary
if [ -f "$BINARY_PATH" ]; then
    strip -x "$BINARY_PATH" 2>/dev/null
fi

echo "📊 Bundle size:"
if [ -d "$APP_PATH" ]; then
    du -sh "$APP_PATH"
else
    echo "App not found!"
fi

echo "✅ Minimal Qt bundle created!" 