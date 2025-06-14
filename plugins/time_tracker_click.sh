#!/bin/bash

echo "CLICK SCRIPT EXECUTED at $(date)" >> /tmp/time_tracker_click_debug.log

# Database file
DB_FILE="/Users/markbennett/github/TimeTrackButton/timetrack.db"
CSV_FILE="/Users/markbennett/github/TimeTrackButton/time_entries.csv"
CHIME_PID_FILE="/tmp/time_tracker_chime.pid"

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
    
    # Export to CSV
    echo "Exporting to CSV" >> /tmp/time_tracker_click_debug.log
    sqlite3 "$DB_FILE" <<EOF
.mode csv
.output $CSV_FILE
SELECT * FROM time_entries;
EOF
    
    afplay -v 0.1 "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3"
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
            sqlite3 "$DB_FILE" <<EOF
.mode csv
.output $CSV_FILE
SELECT * FROM time_entries;
EOF
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
            
            # Check if this is the first time tracking (no entries exist)
            entry_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM time_entries;")
            if [ "$entry_count" -eq 0 ]; then
                echo "First time tracking - starting chime process" >> /tmp/time_tracker_click_debug.log
                start_chime_process
            fi
            
            sqlite3 "$DB_FILE" "INSERT INTO time_entries (project, start_time) VALUES ('$selected_project', strftime('%s', 'now'));"
            afplay -v 0.1 "/Users/markbennett/github/TimeTrackButton/bells-2-31725.mp3"
            break
        else
            echo "No project selected, cancelling" >> /tmp/time_tracker_click_debug.log
            break
        fi
    done
fi

# Update sketchybar immediately
sketchybar --update
sketchybar --trigger time_tracker
