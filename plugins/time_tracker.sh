#!/bin/bash

echo "time_tracker.sh started" >> /tmp/time_tracker_debug.log

# Configuration file to store data folder path
CONFIG_FILE="$HOME/.config/timetracker/config"

# Function to get data folder from config or prompt user
get_data_folder() {
    if [ -f "$CONFIG_FILE" ]; then
        # Read existing config
        DATA_FOLDER=$(cat "$CONFIG_FILE")
        echo "Using existing data folder: $DATA_FOLDER" >> /tmp/time_tracker_debug.log
    else
        # First run - prompt user to choose folder
        echo "First run - prompting for data folder" >> /tmp/time_tracker_debug.log
        DATA_FOLDER=$(osascript -e "
        try
            tell application \"System Events\"
                activate
                set chosenFolder to choose folder with prompt \"Choose a folder to store TimeTracker data:\" default location (path to documents folder)
                return POSIX path of chosenFolder
            end tell
        on error
            return \"$HOME/Documents/\"
        end try
        ")
        
        # Remove trailing slash - use selected folder directly
        DATA_FOLDER=$(echo "$DATA_FOLDER" | sed 's:/$::')
        
        # Create config directory and save choice
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "$DATA_FOLDER" > "$CONFIG_FILE"
        echo "Saved data folder choice: $DATA_FOLDER" >> /tmp/time_tracker_debug.log
    fi
    
    echo "$DATA_FOLDER"
}

# Get data folder
DATA_FOLDER=$(get_data_folder)
DB_FILE="$DATA_FOLDER/.timetrack.db"

# Ensure directory exists
mkdir -p "$DATA_FOLDER"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS time_entries (id INTEGER PRIMARY KEY, project TEXT, start_time TIMESTAMP, end_time TIMESTAMP);"
fi

# Create pause periods table if it doesn't exist
sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS pause_periods (
    id INTEGER PRIMARY KEY,
    time_entry_id INTEGER,
    pause_start INTEGER,
    pause_end INTEGER,
    reason TEXT,
    FOREIGN KEY (time_entry_id) REFERENCES time_entries(id)
);" 2>/dev/null || true

# Get current project (if any)
current_project=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")

if [ -n "$current_project" ]; then
    # Check if currently paused
    current_time_entry_id=$(sqlite3 "$DB_FILE" "SELECT id FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
    is_paused=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM pause_periods WHERE time_entry_id = $current_time_entry_id AND pause_end IS NULL;")
    
    if [ "$is_paused" -gt 0 ]; then
        # Currently paused - show orange with (Paused)
        sketchybar --set time_tracker \
            label="$current_project (Paused)" \
            icon="⏱" \
            icon.color=0xff000000 \
            label.color=0xff000000 \
            background.color=0xffff8000 \
            background.corner_radius=5 \
            background.height=20
    else
        # Currently tracking - show project and elapsed time
        start_time=$(sqlite3 "$DB_FILE" "SELECT start_time FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
        current_time=$(date +%s)
        
        # Calculate total paused time for this entry
        total_paused_seconds=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(pause_end - pause_start), 0) FROM pause_periods WHERE time_entry_id = $current_time_entry_id AND pause_end IS NOT NULL;")
        
        # Calculate elapsed time minus paused time
        elapsed_seconds=$((current_time - start_time - total_paused_seconds))
        
        # Convert to hours and minutes
        hours=$((elapsed_seconds / 3600))
        minutes=$(((elapsed_seconds % 3600) / 60))
        
        # Format time display
        if [ $hours -gt 0 ]; then
            time_display="${hours}:$(printf "%02d" $minutes)"
        else
            time_display="${minutes}m"
        fi
        
        sketchybar --set time_tracker \
            label="$current_project ($time_display)" \
            icon="⏱" \
            icon.color=0xff000000 \
            label.color=0xff000000 \
            background.color=0xff008000 \
            background.corner_radius=5 \
            background.height=20
    fi
else
    # Not tracking - show just red icon
    sketchybar --set time_tracker \
        label="" \
        icon="⏱" \
        icon.color=0xffff0000 \
        background.color=0x00000000
fi 