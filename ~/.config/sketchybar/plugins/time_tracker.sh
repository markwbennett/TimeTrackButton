#!/bin/bash

echo "time_tracker.sh started" >> /tmp/time_tracker_debug.log

# Database file
DB_FILE="/Users/markbennett/github/TimeTrackButton/timetrack.db"

# Function to get current project
get_current_project() {
    local result=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;" | tr -d '\n' | xargs)
    echo "get_current_project result: '$result'" >> /tmp/time_tracker_debug.log
    echo "$result"
}

# Function to get elapsed time
get_elapsed_time() {
    local start_unix=$(sqlite3 "$DB_FILE" "SELECT start_time FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;" | tr -d '\n' | xargs)
    echo "start_unix: $start_unix" >> /tmp/time_tracker_debug.log
    if [ -n "$start_unix" ]; then
        local now_unix=$(date +%s)
        local elapsed_seconds=$((now_unix - start_unix))
        echo "now_unix: $now_unix, elapsed_seconds: $elapsed_seconds" >> /tmp/time_tracker_debug.log
        if [ "$elapsed_seconds" -ge 0 ]; then
            local hours=$((elapsed_seconds / 3600))
            local minutes=$(( (elapsed_seconds % 3600) / 60 ))
            echo "hours: $hours, minutes: $minutes" >> /tmp/time_tracker_debug.log
            printf "%02d:%02d" $hours $minutes
        else
            echo "00:00"
        fi
    else
        echo "00:00"
    fi
}

# Function to update sketchybar
update_sketchybar() {
    local current_project=$(get_current_project)
    if [ -n "$current_project" ]; then
        local elapsed=$(get_elapsed_time)
        sketchybar --set time_tracker icon="⏱" label="$current_project ($elapsed)" icon.color=0xff00ff00
    else
        sketchybar --set time_tracker icon="⏱" label="Not Tracking" icon.color=0xffff0000
    fi
}

# Update every minute
update_sketchybar 