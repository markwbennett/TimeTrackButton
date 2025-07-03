#!/bin/bash

echo "🔧 Making TimeTracker truly portable..."

APP_PATH="TimeTracker_Universal.app"
cd "$(dirname "$0")"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found: $APP_PATH"
    exit 1
fi

echo "📦 Converting symbolic links to actual framework copies..."

FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"

# Replace each symbolic link with actual framework copy
for framework_link in "$FRAMEWORKS_DIR"/*.framework; do
    if [ -L "$framework_link" ]; then
        framework_name=$(basename "$framework_link")
        echo "  → Converting $framework_name"
        
        # Get the target of the symbolic link
        target=$(readlink "$framework_link")
        
        # Remove the symbolic link
        rm "$framework_link"
        
        # Copy the actual framework
        if [[ "$target" = /* ]]; then
            # Absolute path
            cp -R "$target" "$framework_link"
        else
            # Relative path - resolve it
            cp -R "$(dirname "$framework_link")/$target" "$framework_link"
        fi
        
        # Clean up unnecessary files
        find "$framework_link" -name "Headers" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$framework_link" -name "*.prl" -delete 2>/dev/null || true
        find "$framework_link" -name "*_debug*" -delete 2>/dev/null || true
    fi
done

echo "🔧 Fixing library paths for standalone operation..."

# Fix framework internal references
for framework in "$FRAMEWORKS_DIR"/*.framework; do
    if [ -d "$framework" ]; then
        framework_name=$(basename "$framework" .framework)
        framework_binary="$framework/Versions/A/$framework_name"
        
        if [ -f "$framework_binary" ]; then
            echo "  → Fixing $framework_name"
            
            # Update framework's own ID
            install_name_tool -id "@executable_path/../Frameworks/$framework_name.framework/Versions/A/$framework_name" "$framework_binary" 2>/dev/null || true
            
            # Fix references to other Qt frameworks
            for other_framework in "$FRAMEWORKS_DIR"/*.framework; do
                other_name=$(basename "$other_framework" .framework)
                if [ "$framework_name" != "$other_name" ]; then
                    # Fix various possible path formats
                    install_name_tool -change "/opt/homebrew/opt/qt/lib/$other_name.framework/Versions/A/$other_name" \
                        "@executable_path/../Frameworks/$other_name.framework/Versions/A/$other_name" \
                        "$framework_binary" 2>/dev/null || true
                    install_name_tool -change "/opt/homebrew/lib/$other_name.framework/Versions/A/$other_name" \
                        "@executable_path/../Frameworks/$other_name.framework/Versions/A/$other_name" \
                        "$framework_binary" 2>/dev/null || true
                fi
            done
        fi
    fi
done

# Fix main executable
MAIN_EXECUTABLE="$APP_PATH/Contents/MacOS/TimeTracker_real"
if [ -f "$MAIN_EXECUTABLE" ]; then
    echo "  → Fixing main executable"
    for framework in "$FRAMEWORKS_DIR"/*.framework; do
        framework_name=$(basename "$framework" .framework)
        install_name_tool -change "/opt/homebrew/opt/qt/lib/$framework_name.framework/Versions/A/$framework_name" \
            "@executable_path/../Frameworks/$framework_name.framework/Versions/A/$framework_name" \
            "$MAIN_EXECUTABLE" 2>/dev/null || true
        install_name_tool -change "/opt/homebrew/lib/$framework_name.framework/Versions/A/$framework_name" \
            "@executable_path/../Frameworks/$framework_name.framework/Versions/A/$framework_name" \
            "$MAIN_EXECUTABLE" 2>/dev/null || true
    done
fi

echo "📊 Final app size:"
du -sh "$APP_PATH"

echo "✅ App is now truly portable!"
echo "📦 Ready for distribution" 