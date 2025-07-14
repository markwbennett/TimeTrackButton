#!/bin/bash

echo "CLICK SCRIPT EXECUTED at $(date)" >> /tmp/time_tracker_click_debug.log

# Configuration file to store data folder path
CONFIG_FILE="$HOME/.config/timetracker/config"

# Function to get data folder from config or prompt user
get_data_folder() {
    if [ -f "$CONFIG_FILE" ]; then
        # Read existing config
        DATA_FOLDER=$(cat "$CONFIG_FILE")
        echo "Using existing data folder: $DATA_FOLDER" >> /tmp/time_tracker_click_debug.log
    else
        # First run - prompt user to choose folder
        echo "First run - prompting for data folder" >> /tmp/time_tracker_click_debug.log
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
        echo "Saved data folder choice: $DATA_FOLDER" >> /tmp/time_tracker_click_debug.log
    fi
    
    echo "$DATA_FOLDER"
}

# Get data folder
DATA_FOLDER=$(get_data_folder)
DB_FILE="$DATA_FOLDER/.timetrack.db"
CSV_FILE="$DATA_FOLDER/time_entries.csv"
CHIME_PID_FILE="/tmp/time_tracker_chime.pid"
CHIME_LOCK_FILE="$HOME/.config/timetracker/chime.lock"

# Ensure directory exists
mkdir -p "$DATA_FOLDER"
mkdir -p "$(dirname "$CHIME_LOCK_FILE")"

# Function to play chime with lock to prevent double chiming
play_chime() {
    # Try to acquire lock (non-blocking)
    if (set -C; echo $$ > "$CHIME_LOCK_FILE") 2>/dev/null; then
        # Lock acquired, play chime
        # Try to find the sound file in common locations
        SOUND_FILE=""
        POSSIBLE_SOUND_PATHS=(
            "$(dirname "$0")/../bells-2-31725.mp3"
            "$DATA_FOLDER/bells-2-31725.mp3"
            "./bells-2-31725.mp3"
        )
        
        for path in "${POSSIBLE_SOUND_PATHS[@]}"; do
            if [ -f "$path" ]; then
                SOUND_FILE="$path"
                break
            fi
        done
        
        if [ -n "$SOUND_FILE" ]; then
            afplay -v 0.1 "$SOUND_FILE"
        fi
        # Keep lock for 2 seconds to prevent immediate double chiming
        sleep 2
        rm -f "$CHIME_LOCK_FILE"
    else
        # Lock is held by another process, skip chiming
        echo "Chime skipped - another process is chiming" >> /tmp/time_tracker_click_debug.log
    fi
}

# Function to export CSV with formatted dates and durations
export_csv() {
    echo "Exporting to CSV" >> /tmp/time_tracker_click_debug.log
    sqlite3 "$DB_FILE" <<EOF
.mode csv
.headers on
.output $CSV_FILE
SELECT 
    id as "ID",
    project as "Project",
    COALESCE(activity, '') as "Activity",
    datetime(start_time, 'unixepoch', 'localtime') as "Start Time",
    CASE 
        WHEN end_time IS NOT NULL THEN datetime(end_time, 'unixepoch', 'localtime')
        ELSE ''
    END as "End Time",
    CASE 
        WHEN end_time IS NOT NULL THEN 
            printf('%02d:%02d:%02d', 
                (end_time - start_time) / 3600,
                ((end_time - start_time) % 3600) / 60,
                (end_time - start_time) % 60
            )
        WHEN start_time IS NOT NULL THEN
            printf('%02d:%02d:%02d (ongoing)', 
                (strftime('%s', 'now') - start_time) / 3600,
                ((strftime('%s', 'now') - start_time) % 3600) / 60,
                (strftime('%s', 'now') - start_time) % 60
            )
        ELSE ''
    END as "Duration",
    CASE 
        WHEN end_time IS NOT NULL THEN 
            printf('%.1f', CAST((CAST((end_time - start_time) AS REAL) / 3600.0 * 10.0) + 0.9 AS INTEGER) / 10.0)
        WHEN start_time IS NOT NULL THEN
            printf('%.1f', CAST((CAST((strftime('%s', 'now') - start_time) AS REAL) / 3600.0 * 10.0) + 0.9 AS INTEGER) / 10.0)
        ELSE ''
    END as "Hours"
FROM time_entries;
EOF
}

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
    # First chime happens 6 minutes after tracking starts
    (
        sleep 360  # Wait 6 minutes for first chime
        play_chime
        while true; do
            sleep 360  # Then every 6 minutes thereafter
            play_chime
        done
    ) &
    
    # Save PID
    echo $! > "$CHIME_PID_FILE"
}

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS time_entries (id INTEGER PRIMARY KEY, project TEXT, activity TEXT, start_time TIMESTAMP, end_time TIMESTAMP);"
else
    # Add activity column if it doesn't exist (for existing databases)
    sqlite3 "$DB_FILE" "ALTER TABLE time_entries ADD COLUMN activity TEXT;" 2>/dev/null || true
fi

# Create detailed tracking table if it doesn't exist
sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS detailed_tracking (
    id INTEGER PRIMARY KEY,
    time_entry_id INTEGER,
    timestamp INTEGER,
    active_app TEXT,
    document_url TEXT,
    idle_seconds INTEGER DEFAULT 0,
    is_locked INTEGER DEFAULT 0,
    FOREIGN KEY (time_entry_id) REFERENCES time_entries(id)
);" 2>/dev/null || true

# Create pause periods table if it doesn't exist
sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS pause_periods (
    id INTEGER PRIMARY KEY,
    time_entry_id INTEGER,
    pause_start INTEGER,
    pause_end INTEGER,
    reason TEXT,
    FOREIGN KEY (time_entry_id) REFERENCES time_entries(id)
);" 2>/dev/null || true

# Get current project
current_project=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
echo "Current project: '$current_project'" >> /tmp/time_tracker_click_debug.log

if [ -n "$current_project" ]; then
    # Check if currently paused
    current_time_entry_id=$(sqlite3 "$DB_FILE" "SELECT id FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1;")
    is_paused=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM pause_periods WHERE time_entry_id = $current_time_entry_id AND pause_end IS NULL;")
    
    if [ "$is_paused" -gt 0 ]; then
        # Currently paused - resume tracking directly
        echo "Resuming tracking directly" >> /tmp/time_tracker_click_debug.log
        sqlite3 "$DB_FILE" "UPDATE pause_periods SET pause_end = strftime('%s', 'now') WHERE time_entry_id = $current_time_entry_id AND pause_end IS NULL;"
        
        # Restart chime process when resuming
        echo "Restarting chime process for resume" >> /tmp/time_tracker_click_debug.log
        start_chime_process
        
        play_chime
    else
        # Currently tracking - auto-pause and show menu
        echo "Auto-pausing tracking and showing menu" >> /tmp/time_tracker_click_debug.log
        sqlite3 "$DB_FILE" "INSERT INTO pause_periods (time_entry_id, pause_start, reason) VALUES ($current_time_entry_id, strftime('%s', 'now'), 'Manual pause');"
        
        # Stop chime process when pausing
        if [ -f "$CHIME_PID_FILE" ]; then
            old_pid=$(cat "$CHIME_PID_FILE")
            if kill -0 "$old_pid" 2>/dev/null; then
                kill "$old_pid"
                echo "Stopped chime process for pause" >> /tmp/time_tracker_click_debug.log
            fi
            rm -f "$CHIME_PID_FILE"
        fi
        
        # Show tracking options menu (without pause option)
        tracking_action=$(osascript -e "
        try
            tell application \"System Events\"
                activate
                set actionChoices to {\"Change Activity\", \"Change Project\", \"Stop Tracking\"}
                set selectedAction to choose from list actionChoices with prompt \"Select action:\" default items {\"Stop Tracking\"} with title \"Tracking Options\" OK button name \"OK\" cancel button name \"Cancel\"
                if selectedAction is false then
                    return \"\"
                end if
                return item 1 of selectedAction
            end tell
        on error
            return \"\"
        end try
        ")
        
        echo "Selected tracking action: '$tracking_action'" >> /tmp/time_tracker_click_debug.log
        
        if [ -z "$tracking_action" ]; then
            # User cancelled - resume tracking
            echo "Menu cancelled - resuming tracking" >> /tmp/time_tracker_click_debug.log
            sqlite3 "$DB_FILE" "UPDATE pause_periods SET pause_end = strftime('%s', 'now') WHERE time_entry_id = $current_time_entry_id AND pause_end IS NULL;"
            
            # Restart chime process when resuming
            echo "Restarting chime process after cancel" >> /tmp/time_tracker_click_debug.log
            start_chime_process
        fi
    fi
    
    echo "Selected tracking action: '$tracking_action'" >> /tmp/time_tracker_click_debug.log
    
    if [ "$tracking_action" = "Change Activity" ]; then
        # Change activity for current session
        echo "Changing activity" >> /tmp/time_tracker_click_debug.log
        
        # Get activity selection (reuse the activity selection code)
        selected_activity=$(osascript -e "
        try
            tell application \"System Events\"
                activate
                
                -- Load custom activities from file
                set customActivitiesFile to (path to home folder as string) & \".config:timetracker:custom_activities\"
                set customActivities to {}
                try
                    set customActivitiesText to read file customActivitiesFile
                    set customActivities to paragraphs of customActivitiesText
                    -- Remove empty lines
                    set cleanCustomActivities to {}
                    repeat with activity in customActivities
                        if activity is not \"\" then
                            set end of cleanCustomActivities to activity
                        end if
                    end repeat
                    set customActivities to cleanCustomActivities
                on error
                    set customActivities to {}
                end try
                
                -- Base activities
                set baseActivities to {\"Legal research\", \"Investigation\", \"Discovery Review\", \"File Review\", \"Client Communication\"}
                
                -- Combine base and custom activities, then add Other
                set allActivities to baseActivities & customActivities & {\"Other\"}
                
                set selectedActivity to choose from list allActivities with prompt \"Select new activity type:\" default items {\"Legal research\"} with title \"Change Activity\" OK button name \"Change\" cancel button name \"Cancel\"
                if selectedActivity is false then
                    return \"\"
                end if
                
                set chosenActivity to item 1 of selectedActivity
                
                -- Handle \"Other\" selection
                if chosenActivity is \"Other\" then
                    set customActivityDialog to display dialog \"Enter custom activity type:\" default answer \"\" with title \"Custom Activity\"
                    set customActivity to text returned of customActivityDialog
                    if customActivity is \"\" then
                        return \"\"
                    end if
                    
                    -- Save custom activity to file
                    try
                        set customActivitiesText to read file customActivitiesFile
                        -- Check if activity already exists
                        if customActivitiesText does not contain customActivity then
                            set customActivitiesText to customActivitiesText & customActivity & return
                            set fileRef to open for access file customActivitiesFile with write permission
                            set eof of fileRef to 0
                            write customActivitiesText to fileRef
                            close access fileRef
                        end if
                    on error
                        -- Create new file
                        try
                            set fileRef to open for access file customActivitiesFile with write permission
                            write customActivity & return to fileRef
                            close access fileRef
                        on error
                            -- Ignore file write errors
                        end try
                    end try
                    
                    return customActivity
                end if
                
                return chosenActivity
            end tell
        on error
             return \"Legal research\"
        end try
        ")
        
        if [ -n "$selected_activity" ]; then
            echo "Changing activity to: $selected_activity" >> /tmp/time_tracker_click_debug.log
            sqlite3 "$DB_FILE" "UPDATE time_entries SET activity = '$selected_activity' WHERE end_time IS NULL;"
            # Regenerate CSV after activity change
            export_csv
            
            # Resume tracking after changing activity
            echo "Resuming tracking after activity change" >> /tmp/time_tracker_click_debug.log
            sqlite3 "$DB_FILE" "UPDATE pause_periods SET pause_end = strftime('%s', 'now') WHERE time_entry_id = $current_time_entry_id AND pause_end IS NULL;"
            
            # Restart chime process
            echo "Restarting chime process after activity change" >> /tmp/time_tracker_click_debug.log
            start_chime_process
        fi
        
    elif [ "$tracking_action" = "Change Project" ]; then
        # Change project for current session
        echo "Changing project" >> /tmp/time_tracker_click_debug.log
        
        # Get existing projects
        existing_projects=$(sqlite3 "$DB_FILE" "SELECT DISTINCT project FROM time_entries WHERE project NOT LIKE '[HIDDEN]%' GROUP BY project ORDER BY MAX(start_time) DESC;")
        
        selected_project=$(osascript -e "
        try
            tell application \"System Events\"
                activate
                
                -- Build project list
                set projectList to \"$existing_projects\"
                set projectArray to paragraphs of projectList
                set projectChoices to {}
                
                repeat with p in projectArray
                    if p is not \"\" then
                        set end of projectChoices to p
                    end if
                end repeat
                
                -- Add new project option
                set end of projectChoices to \"[New Project]\"
                
                set selectedProject to choose from list projectChoices with prompt \"Select new project:\" default items {item 1 of projectChoices} with title \"Change Project\" OK button name \"Change\" cancel button name \"Cancel\"
                if selectedProject is false then
                    return \"\"
                end if
                
                set chosenProject to item 1 of selectedProject
                
                -- Handle new project creation
                if chosenProject is \"[New Project]\" then
                    set newProjectDialog to display dialog \"Enter new project name:\" default answer \"\" with title \"New Project\"
                    set newProject to text returned of newProjectDialog
                    if newProject is \"\" then
                        return \"\"
                    end if
                    return newProject
                end if
                
                -- Handle project management
                if chosenProject is \"[Manage Projects]\" then
                    repeat
                        -- Show projects for management
                        set projectsToManage to choose from list projectArray with prompt \"Select projects to manage:\" with title \"Manage Projects\" with multiple selections allowed OK button name \"Manage\" cancel button name \"Close\"
                        if projectsToManage is false then
                            -- User clicked Close - return to project selection
                            return \"RETURN_TO_SELECTION\"
                        end if
                        
                        if projectsToManage is not false then
                            set confirmDialog to display dialog \"Remove selected projects from future selections?\" & return & return & \"Choose action:\" buttons {\"Cancel\", \"Remove from list only\", \"Delete all time entries\"} default button \"Remove from list only\" with title \"Confirm Action\"
                            set buttonChoice to button returned of confirmDialog
                            if buttonChoice is \"Remove from list only\" then
                                repeat with proj in projectsToManage
                                    return \"HIDE:\" & proj
                                end repeat
                            else if buttonChoice is \"Delete all time entries\" then
                                repeat with proj in projectsToManage
                                    return \"DELETE:\" & proj
                                end repeat
                            end if
                            -- If Cancel was clicked, continue the loop to show manage dialog again
                        end if
                    end repeat
                end if
                
                return chosenProject
            end tell
        on error
            return \"\"
        end try
        ")
        
        if [ -n "$selected_project" ]; then
            echo "Changing project to: $selected_project" >> /tmp/time_tracker_click_debug.log
            
            # Also prompt for activity when changing project
            selected_activity=$(osascript -e "
            try
                tell application \"System Events\"
                    activate
                    
                    -- Load custom activities from file
                    set customActivitiesFile to (path to home folder as string) & \".config:timetracker:custom_activities\"
                    set customActivities to {}
                    try
                        set customActivitiesText to read file customActivitiesFile
                        set customActivities to paragraphs of customActivitiesText
                        -- Remove empty lines
                        set cleanCustomActivities to {}
                        repeat with activity in customActivities
                            if activity is not \"\" then
                                set end of cleanCustomActivities to activity
                            end if
                        end repeat
                        set customActivities to cleanCustomActivities
                    on error
                        set customActivities to {}
                    end try
                    
                    -- Base activities
                    set baseActivities to {\"Legal research\", \"Investigation\", \"Discovery Review\", \"File Review\", \"Client Communication\"}
                    
                    -- Combine base and custom activities, then add Other
                    set allActivities to baseActivities & customActivities & {\"Other\"}
                    
                    set selectedActivity to choose from list allActivities with prompt \"Select activity type for new project:\" default items {\"Legal research\"} with title \"Change Project Activity\" OK button name \"Change\" cancel button name \"Cancel\"
                    if selectedActivity is false then
                        return \"\"
                    end if
                    
                    set chosenActivity to item 1 of selectedActivity
                    
                    -- Handle \"Other\" selection
                    if chosenActivity is \"Other\" then
                        set customActivityDialog to display dialog \"Enter custom activity type:\" default answer \"\" with title \"Custom Activity\"
                        set customActivity to text returned of customActivityDialog
                        if customActivity is \"\" then
                            return \"\"
                        end if
                        
                        -- Save custom activity to file
                        try
                            set customActivitiesText to read file customActivitiesFile
                            -- Check if activity already exists
                            if customActivitiesText does not contain customActivity then
                                set customActivitiesText to customActivitiesText & customActivity & return
                                set fileRef to open for access file customActivitiesFile with write permission
                                set eof of fileRef to 0
                                write customActivitiesText to fileRef
                                close access fileRef
                            end if
                        on error
                            -- Create new file
                            try
                                set fileRef to open for access file customActivitiesFile with write permission
                                write customActivity & return to fileRef
                                close access fileRef
                            on error
                                -- Ignore file write errors
                            end try
                        end try
                        
                        return customActivity
                    end if
                    
                    return chosenActivity
                end tell
            on error
                 return \"Legal research\"
            end try
            ")
            
            if [ -n "$selected_activity" ]; then
                echo "Changing project to: $selected_project and activity to: $selected_activity" >> /tmp/time_tracker_click_debug.log
                sqlite3 "$DB_FILE" "UPDATE time_entries SET project = '$selected_project', activity = '$selected_activity' WHERE end_time IS NULL;"
                # Regenerate CSV after project and activity change
                export_csv
                
                # Resume tracking after changing project
                echo "Resuming tracking after project change" >> /tmp/time_tracker_click_debug.log
                sqlite3 "$DB_FILE" "UPDATE pause_periods SET pause_end = strftime('%s', 'now') WHERE time_entry_id = $current_time_entry_id AND pause_end IS NULL;"
                
                # Restart chime process
                echo "Restarting chime process after project change" >> /tmp/time_tracker_click_debug.log
                start_chime_process
            fi
        fi
        
    elif [ "$tracking_action" = "Stop Tracking" ]; then
        # Stop tracking
        echo "Stopping tracking" >> /tmp/time_tracker_click_debug.log
        sqlite3 "$DB_FILE" "UPDATE time_entries SET end_time = strftime('%s', 'now') WHERE end_time IS NULL;"
        
        # Stop chime process when tracking stops
        if [ -f "$CHIME_PID_FILE" ]; then
            old_pid=$(cat "$CHIME_PID_FILE")
            if kill -0 "$old_pid" 2>/dev/null; then
                kill "$old_pid"
                echo "Stopped chime process" >> /tmp/time_tracker_click_debug.log
            fi
            rm -f "$CHIME_PID_FILE"
        fi
        
        # Export to CSV with formatted dates and durations
        export_csv
        
        play_chime
    fi
else
    # Start tracking - show project selection dialog
    echo "Starting tracking - showing project selection" >> /tmp/time_tracker_click_debug.log
    
    while true; do
        # Get existing projects and last used project (only from active/incomplete entries)
        existing_projects=$(sqlite3 "$DB_FILE" "SELECT DISTINCT project FROM time_entries WHERE project NOT LIKE '[HIDDEN]%' GROUP BY project ORDER BY MAX(start_time) DESC;")
        last_project=$(sqlite3 "$DB_FILE" "SELECT project FROM time_entries ORDER BY start_time DESC LIMIT 1;")
        
        echo "Existing projects: $existing_projects" >> /tmp/time_tracker_click_debug.log
        echo "Last project: $last_project" >> /tmp/time_tracker_click_debug.log
        
        # Create project selection dialog with dropdown and management option
        selected_project=$(osascript -e "
        try
            tell application \"System Events\"
                activate
                
                -- Build project list
                set projectList to \"$existing_projects\"
                set projectArray to paragraphs of projectList
                set projectChoices to {}
                
                repeat with p in projectArray
                    if p is not \"\" then
                        set end of projectChoices to p
                    end if
                end repeat
                
                -- Add management options at the end
                set end of projectChoices to \"[New Project]\"
                set end of projectChoices to \"[Manage Projects]\"
                
                -- Set default selection (most recent project or New Project)
                set defaultChoice to \"[New Project]\"
                if \"$last_project\" is not \"\" and \"$last_project\" is not \"[HIDDEN]\" then
                    set defaultChoice to \"$last_project\"
                end if
                
                -- Show selection dialog with immediate execution
                set selectedProject to choose from list projectChoices with prompt \"Select project to start tracking:\" default items {defaultChoice} with title \"Time Tracker\" OK button name \"Start\" cancel button name \"Cancel\"
                if selectedProject is false then
                    return \"\"
                end if
                
                set chosenProject to item 1 of selectedProject
                
                -- Handle new project creation
                if chosenProject is \"[New Project]\" then
                    set newProjectDialog to display dialog \"Enter new project name:\" default answer \"\" with title \"New Project\"
                    set newProject to text returned of newProjectDialog
                    if newProject is \"\" then
                        return \"\"
                    end if
                    return newProject
                end if
                
                -- Handle project management
                if chosenProject is \"[Manage Projects]\" then
                    repeat
                        -- Show projects for management
                        set projectsToManage to choose from list projectArray with prompt \"Select projects to manage:\" with title \"Manage Projects\" with multiple selections allowed OK button name \"Manage\" cancel button name \"Close\"
                        if projectsToManage is false then
                            -- User clicked Close - return to project selection
                            return \"RETURN_TO_SELECTION\"
                        end if
                        
                        if projectsToManage is not false then
                            set confirmDialog to display dialog \"Remove selected projects from future selections?\" & return & return & \"Choose action:\" buttons {\"Cancel\", \"Remove from list only\", \"Delete all time entries\"} default button \"Remove from list only\" with title \"Confirm Action\"
                            set buttonChoice to button returned of confirmDialog
                            if buttonChoice is \"Remove from list only\" then
                                repeat with proj in projectsToManage
                                    return \"HIDE:\" & proj
                                end repeat
                            else if buttonChoice is \"Delete all time entries\" then
                                repeat with proj in projectsToManage
                                    return \"DELETE:\" & proj
                                end repeat
                            end if
                            -- If Cancel was clicked, continue the loop to show manage dialog again
                        end if
                    end repeat
                end if
                
                return chosenProject
            end tell
        on error
            return \"\"
        end try
        ")
        
        echo "Selected project: '$selected_project'" >> /tmp/time_tracker_click_debug.log
        
        # Handle project management actions
        if [[ "$selected_project" == HIDE:* ]]; then
            project_to_hide="${selected_project#HIDE:}"
            echo "Hiding project from list: $project_to_hide" >> /tmp/time_tracker_click_debug.log
            # Mark project as hidden by adding a special marker to project name
            sqlite3 "$DB_FILE" "UPDATE time_entries SET project = '[HIDDEN]' || project WHERE project = '$project_to_hide';"
            echo "Project hidden from future selections" >> /tmp/time_tracker_click_debug.log
            # Continue loop to show project selection again
            continue
            
        elif [[ "$selected_project" == DELETE:* ]]; then
            project_to_delete="${selected_project#DELETE:}"
            echo "Deleting project and all entries: $project_to_delete" >> /tmp/time_tracker_click_debug.log
            sqlite3 "$DB_FILE" "DELETE FROM time_entries WHERE project = '$project_to_delete';"
            
            # Export updated CSV
            export_csv
            echo "Project and all entries deleted, CSV updated" >> /tmp/time_tracker_click_debug.log
            # Continue loop to show project selection again
            continue
            
        elif [ "$selected_project" = "MANAGE_CANCELLED" ]; then
            echo "Project management cancelled" >> /tmp/time_tracker_click_debug.log
            # Continue loop to show project selection again
            continue
            
        elif [ "$selected_project" = "RETURN_TO_SELECTION" ]; then
            echo "Returning to project selection" >> /tmp/time_tracker_click_debug.log
            # Continue loop to show project selection again
            continue
            
        elif [ -n "$selected_project" ]; then
            echo "Starting tracking for project: $selected_project" >> /tmp/time_tracker_click_debug.log
            
                        # Prompt for activity type
            selected_activity=$(osascript -e "
            try
                tell application \"System Events\"
                    activate
                    
                    -- Load custom activities from file
                    set customActivitiesFile to (path to home folder as string) & \".config:timetracker:custom_activities\"
                    set customActivities to {}
                    try
                        set customActivitiesText to read file customActivitiesFile
                        set customActivities to paragraphs of customActivitiesText
                        -- Remove empty lines
                        set cleanCustomActivities to {}
                        repeat with activity in customActivities
                            if activity is not \"\" then
                                set end of cleanCustomActivities to activity
                            end if
                        end repeat
                        set customActivities to cleanCustomActivities
                    on error
                        set customActivities to {}
                    end try
                    
                    -- Base activities
                    set baseActivities to {\"Legal research\", \"Investigation\", \"Discovery Review\", \"File Review\", \"Client Communication\"}
                    
                    -- Combine base and custom activities, then add Other
                    set allActivities to baseActivities & customActivities & {\"Other\"}
                    
                    set selectedActivity to choose from list allActivities with prompt \"Select activity type:\" default items {\"Legal research\"} with title \"Activity Type\" OK button name \"Start\" cancel button name \"Cancel\"
                    if selectedActivity is false then
                        return \"\"
                    end if
                    
                    set chosenActivity to item 1 of selectedActivity
                    
                    -- Handle \"Other\" selection
                    if chosenActivity is \"Other\" then
                        set customActivityDialog to display dialog \"Enter custom activity type:\" default answer \"\" with title \"Custom Activity\"
                        set customActivity to text returned of customActivityDialog
                        if customActivity is \"\" then
                            return \"\"
                        end if
                        
                        -- Save custom activity to file
                        try
                            set customActivitiesText to read file customActivitiesFile
                            -- Check if activity already exists
                            if customActivitiesText does not contain customActivity then
                                set customActivitiesText to customActivitiesText & customActivity & return
                                set fileRef to open for access file customActivitiesFile with write permission
                                set eof of fileRef to 0
                                write customActivitiesText to fileRef
                                close access fileRef
                            end if
                        on error
                            -- Create new file
                            try
                                set fileRef to open for access file customActivitiesFile with write permission
                                write customActivity & return to fileRef
                                close access fileRef
                            on error
                                -- Ignore file write errors
                            end try
                        end try
                        
                        return customActivity
                    end if
                    
                    return chosenActivity
                end tell
            on error
                 return \"Legal research\"
            end try
            ")
            
            if [ -n "$selected_activity" ]; then
                echo "Starting tracking for project: $selected_project, activity: $selected_activity" >> /tmp/time_tracker_click_debug.log
                
                # Start chime process every time tracking begins
                echo "Starting chime process for tracking session" >> /tmp/time_tracker_click_debug.log
                start_chime_process
                
                sqlite3 "$DB_FILE" "INSERT INTO time_entries (project, activity, start_time) VALUES ('$selected_project', '$selected_activity', strftime('%s', 'now'));"
                play_chime
                break
            else
                echo "No activity selected, cancelling" >> /tmp/time_tracker_click_debug.log
                break
            fi
        else
            echo "No project selected, cancelling" >> /tmp/time_tracker_click_debug.log
            break
        fi
    done
fi

# Update sketchybar immediately
sketchybar --update
sketchybar --trigger time_tracker
