#!/bin/bash

echo "time_tracker.sh started" >> /tmp/time_tracker_debug.log

# Database file
DB_FILE="/Users/markbennett/github/TimeTrackButton/timetrack.db"
CHIME_PID_FILE="/tmp/time_tracker_chime.pid"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS time_entries (id INTEGER PRIMARY KEY, project TEXT, start_time TIMESTAMP, end_time TIMESTAMP);"
fi

# Function to start chime process
start_chime_process() {
    # Kill existing chime process if running
    if [ -f "$CHIME_PID_FILE" ]; then
        old_pid=$(cat "$CHIME_PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
        fi
        rm -f "$CHIME_PID_FILE"
    fi
    
    # Start new chime process in background
    (
        while true; do
            sleep 360  # 6 minutes = 360 seconds
            afplay -v 0.1 "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3"
        done
    ) &
    
    # Save PID
    echo $! > "$CHIME_PID_FILE"
}

# Check if chime process should be running
current_project=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
chime_should_run=false

# Check if we have any time entries (indicating tracking has been used)
entry_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM time_entries;")
if [ "$entry_count" -gt 0 ]; then
    chime_should_run=true
fi

# Start chime process if needed and not already running
if [ "$chime_should_run" = true ]; then
    if [ ! -f "$CHIME_PID_FILE" ] || ! kill -0 "$(cat "$CHIME_PID_FILE" 2>/dev/null)" 2>/dev/null; then
        start_chime_process
    fi
fi

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