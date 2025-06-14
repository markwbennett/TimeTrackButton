#!/bin/bash

echo "time_tracker.sh started" >> /tmp/time_tracker_debug.log

# Database file
DB_FILE="/Users/markbennett/github/TimeTrackButton/timetrack.db"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS time_entries (id INTEGER PRIMARY KEY, project TEXT, start_time TIMESTAMP, end_time TIMESTAMP);"
fi

# Get current project (if any)
current_project=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")

if [ -n "$current_project" ]; then
    # Currently tracking - show project and elapsed time
    start_time=$(sqlite3 "$DB_FILE" "SELECT start_time FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
    current_time=$(date +%s)
    elapsed_seconds=$((current_time - start_time))
    
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
else
    # Not tracking - show just red icon
    sketchybar --set time_tracker \
        label="" \
        icon="⏱" \
        icon.color=0xffff0000 \
        background.color=0x00000000
fi 