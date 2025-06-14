#!/bin/bash

echo "CLICK SCRIPT EXECUTED at $(date)" >> /tmp/time_tracker_click_debug.log

# Database file
DB_FILE="/Users/markbennett/github/TimeTrackButton/timetrack.db"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS time_entries (id INTEGER PRIMARY KEY, project TEXT, start_time TIMESTAMP, end_time TIMESTAMP);"
fi

# Get current project
current_project=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
echo "Current project: '$current_project'" >> /tmp/time_tracker_click_debug.log

if [ -n "$current_project" ]; then
    # Stop tracking
    echo "Stopping tracking" >> /tmp/time_tracker_click_debug.log
    sqlite3 "$DB_FILE" "UPDATE time_entries SET end_time = strftime('%s', 'now') WHERE end_time IS NULL;"
    afplay "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3"
else
    # Start tracking with a test project
    echo "Starting tracking" >> /tmp/time_tracker_click_debug.log
    sqlite3 "$DB_FILE" "INSERT INTO time_entries (project, start_time) VALUES ('Test Project', strftime('%s', 'now'));"
    afplay "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3"
fi

# Update sketchybar immediately
sketchybar --update
sketchybar --trigger time_tracker
