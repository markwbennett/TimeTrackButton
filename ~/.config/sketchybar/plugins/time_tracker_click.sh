#!/bin/bash
echo "Script executed at $(date)" > /tmp/time_tracker_test.log

echo "Script started" > /tmp/time_tracker_debug.log

# Database file
DB_FILE="/Users/markbennett/github/TimeTrackButton/timetrack.db"
CSV_FILE="$HOME/github/TimeTrackButton/time_entries.csv"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo "Creating database at $DB_FILE" >> /tmp/time_tracker_debug.log
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS time_entries (id INTEGER PRIMARY KEY, project TEXT, start_time TIMESTAMP, end_time TIMESTAMP);" || {
        echo "Failed to create database" >> /tmp/time_tracker_debug.log
        exit 1
    }
fi

# Function to get current project
get_current_project() {
    echo "Getting current project" >> /tmp/time_tracker_debug.log
    local project
    project=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;") || {
        echo "Failed to query database" >> /tmp/time_tracker_debug.log
        return 1
    }
    echo "Current project: $project" >> /tmp/time_tracker_debug.log
    echo "$project"
}

# Function to start tracking
start_tracking() {
    echo "Starting tracking" >> /tmp/time_tracker_debug.log
    
    # Get list of existing projects
    local projects
    projects=$(sqlite3 "$DB_FILE" "SELECT DISTINCT project FROM time_entries ORDER BY project;") || {
        echo "Failed to get project list" >> /tmp/time_tracker_debug.log
        return 1
    }
    
    # Create AppleScript with proper quoting
    local script="tell application \"System Events\"
        try
            set projectList to {}
            set projectList to \"$projects\"
            set projectArray to paragraphs of projectList
            
            set projectChoices to {\"New Project\"}
            repeat with p in projectArray
                if p is not \"\" then
                    set end of projectChoices to p
                end if
            end repeat
            
            set selectedProject to choose from list projectChoices with prompt \"Select Project\" default items {\"New Project\"}
            if selectedProject is false then
                return \"\"
            end if
            
            if item 1 of selectedProject is \"New Project\" then
                set newProject to text returned of (display dialog \"Enter new project name:\" default answer \"\")
                if newProject is \"\" then
                    return \"\"
                end if
                return newProject
            end if
            
            return item 1 of selectedProject
        on error errMsg
            display dialog \"Error: \" & errMsg
            return \"\"
        end try
    end tell"
    
    echo "Running osascript" >> /tmp/time_tracker_debug.log
    local project
    project=$(osascript -e "$script") || {
        echo "Failed to run AppleScript" >> /tmp/time_tracker_debug.log
        return 1
    }
    
    echo "Project selected: $project" >> /tmp/time_tracker_debug.log
    
    if [ -n "$project" ]; then
        echo "Inserting project into database" >> /tmp/time_tracker_debug.log
        sqlite3 "$DB_FILE" "INSERT INTO time_entries (project, start_time) VALUES ('$project', strftime('%s', 'now'));" || {
            echo "Failed to insert project" >> /tmp/time_tracker_debug.log
            return 1
        }
        afplay "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3" || echo "Failed to play sound" >> /tmp/time_tracker_debug.log
    fi
}

# Function to stop tracking
stop_tracking() {
    echo "Stopping tracking" >> /tmp/time_tracker_debug.log
    local current_project
    current_project=$(get_current_project) || return 1
    
    if [ -n "$current_project" ]; then
        echo "Updating database to stop tracking" >> /tmp/time_tracker_debug.log
        sqlite3 "$DB_FILE" "UPDATE time_entries SET end_time = strftime('%s', 'now') WHERE end_time IS NULL;" || {
            echo "Failed to update end time" >> /tmp/time_tracker_debug.log
            return 1
        }
        
        # Export to CSV properly
        sqlite3 "$DB_FILE" <<EOF
.mode csv
.output $CSV_FILE
SELECT * FROM time_entries;
EOF
        [ $? -eq 0 ] || {
            echo "Failed to export CSV" >> /tmp/time_tracker_debug.log
            return 1
        }
        
        afplay "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3" || echo "Failed to play sound" >> /tmp/time_tracker_debug.log
    fi
}

echo "Checking if currently tracking" >> /tmp/time_tracker_debug.log
if [ -n "$(get_current_project)" ]; then
    stop_tracking
else
    start_tracking
fi

echo "Updating sketchybar" >> /tmp/time_tracker_debug.log
sketchybar --update 