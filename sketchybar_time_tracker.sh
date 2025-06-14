#!/bin/bash

# Database file
DB_FILE="$HOME/github/TimeTrackButton/timetrack.db"
CSV_FILE="$HOME/github/TimeTrackButton/time_entries.csv"

# Create database if it doesn't exist
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE time_entries (id INTEGER PRIMARY KEY, project TEXT, start_time TIMESTAMP, end_time TIMESTAMP);"
fi

# Function to get current project
get_current_project() {
    sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;"
}

# Function to get elapsed time
get_elapsed_time() {
    local start_time=$(sqlite3 "$DB_FILE" "SELECT start_time FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
    if [ -n "$start_time" ]; then
        local elapsed=$(( $(date +%s) - $(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" +%s) ))
        local hours=$((elapsed / 3600))
        local minutes=$(( (elapsed % 3600) / 60 ))
        printf "%02d:%02d" $hours $minutes
    fi
}

# Function to start tracking
start_tracking() {
    local project=$(osascript -e 'tell application "System Events"
        set projectList to {}
        set projectList to do shell script "sqlite3 '"$DB_FILE"' \"SELECT DISTINCT project FROM time_entries ORDER BY project;\""
        set projectArray to paragraphs of projectList
        
        set projectChoices to {"New Project"}
        repeat with p in projectArray
            if p is not "" then
                set end of projectChoices to p
            end if
        end repeat
        
        set selectedProject to choose from list projectChoices with prompt "Select Project" default items {"New Project"}
        if selectedProject is false then
            return ""
        end if
        
        if item 1 of selectedProject is "New Project" then
            set newProject to text returned of (display dialog "Enter new project name:" default answer "")
            if newProject is "" then
                return ""
            end if
            return newProject
        end if
        
        return item 1 of selectedProject
    end tell')
    
    if [ -n "$project" ]; then
        sqlite3 "$DB_FILE" "INSERT INTO time_entries (project, start_time) VALUES ('$project', datetime('now'));"
        afplay "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3"
    fi
}

# Function to stop tracking
stop_tracking() {
    local current_project=$(get_current_project)
    if [ -n "$current_project" ]; then
        sqlite3 "$DB_FILE" "UPDATE time_entries SET end_time = datetime('now') WHERE end_time IS NULL;"
        sqlite3 "$DB_FILE" ".mode csv" ".output $CSV_FILE" "SELECT * FROM time_entries;"
        afplay "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3"
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

# Handle click events
case "$SENDER" in
    "mouse.clicked")
        if [ -n "$(get_current_project)" ]; then
            stop_tracking
        else
            start_tracking
        fi
        update_sketchybar
        ;;
esac

# Update every minute
update_sketchybar 