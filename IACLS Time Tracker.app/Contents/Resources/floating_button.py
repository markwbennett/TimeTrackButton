#!/usr/bin/env python3

import sys
import sqlite3
import pandas as pd
from datetime import datetime
import os
import json
import fcntl
import time
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QPushButton, QComboBox, QDialog, QVBoxLayout, QLineEdit, QDialogButtonBox, QWidget, QHBoxLayout
from PyQt6.QtCore import Qt, QPoint, QTimer, QUrl
from PyQt6.QtGui import QColor, QPainter, QPen, QPainterPath, QBrush
from PyQt6.QtMultimedia import QMediaPlayer, QAudioOutput

class StateManager:
    """Manages shared state between different time tracking apps with file locking"""
    
    def __init__(self, data_folder):
        self.data_folder = Path(data_folder)
        self.state_file = self.data_folder / ".app_state.json"
        self.lock_file = self.data_folder / ".app_state.lock"
        self.db_file = self.data_folder / ".timetrack.db"
        
    def acquire_lock(self, timeout=5):
        """Acquire exclusive lock on state file"""
        try:
            self.lock_fd = open(self.lock_file, 'w')
            # Try to acquire lock with timeout
            start_time = time.time()
            while time.time() - start_time < timeout:
                try:
                    fcntl.flock(self.lock_fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                    return True
                except IOError:
                    time.sleep(0.1)
            return False
        except Exception:
            return False
    
    def release_lock(self):
        """Release the lock"""
        try:
            if hasattr(self, 'lock_fd'):
                fcntl.flock(self.lock_fd.fileno(), fcntl.LOCK_UN)
                self.lock_fd.close()
                delattr(self, 'lock_fd')
        except Exception:
            pass
    
    def get_current_state(self):
        """Get current tracking state from database"""
        try:
            conn = sqlite3.connect(str(self.db_file))
            cursor = conn.cursor()
            cursor.execute("SELECT project, activity, start_time FROM time_entries WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1")
            result = cursor.fetchone()
            conn.close()
            
            if result:
                return {
                    'is_tracking': True,
                    'project': result[0],
                    'activity': result[1] if len(result) > 1 else '',
                    'start_time': result[2] if len(result) > 2 else result[1],
                    'last_updated': int(time.time())
                }
            else:
                return {
                    'is_tracking': False,
                    'project': None,
                    'activity': None,
                    'start_time': None,
                    'last_updated': int(time.time())
                }
        except Exception:
            return None
    
    def save_state(self, state):
        """Save current state to file with locking"""
        if self.acquire_lock():
            try:
                state['last_updated'] = int(time.time())
                with open(self.state_file, 'w') as f:
                    json.dump(state, f)
                return True
            except Exception:
                return False
            finally:
                self.release_lock()
        return False
    
    def load_state(self):
        """Load state from file with locking"""
        if self.acquire_lock():
            try:
                if self.state_file.exists():
                    with open(self.state_file, 'r') as f:
                        state = json.load(f)
                    return state
                return None
            except Exception:
                return None
            finally:
                self.release_lock()
        return None
    
    def sync_with_database(self):
        """Synchronize state file with database state"""
        db_state = self.get_current_state()
        if db_state:
            self.save_state(db_state)
            return db_state
        return None

class DraggableHandle(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedSize(140, 140)  # Square container for circular button
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint | Qt.WindowType.WindowStaysOnTopHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.old_pos = None
        
        layout = QHBoxLayout()
        layout.setContentsMargins(10, 10, 10, 10)
        self.button = FloatingButton()
        layout.addWidget(self.button)
        self.setLayout(layout)
        
        # Set default position and load saved position
        self.set_default_position()
        self.load_position()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        # Draw outer black border as a circle
        pen = QPen(QColor(0, 0, 0, 255))  # Solid black
        pen.setWidth(4)
        painter.setPen(pen)
        painter.setBrush(QColor(0, 0, 0, 0))  # Transparent fill
        
        # Calculate the circle - black border should be immediately outside white border
        # Button has 4px white border, so black border starts at the edge of that
        button_rect = self.button.geometry()
        # Expand by 2px (half the black border width) to center the 4px black border line
        # on the outer edge of the white border
        border_rect = button_rect.adjusted(-2, -2, 2, 2)
        painter.drawEllipse(border_rect)

    def mousePressEvent(self, event):
        # Check if click is in the border area (drag handle) or inner button area
        button_rect = self.button.geometry()
        click_pos = event.position().toPoint()
        
        # Calculate distances from center for circular button
        button_center = button_rect.center()
        click_distance = ((click_pos.x() - button_center.x()) ** 2 + (click_pos.y() - button_center.y()) ** 2) ** 0.5
        
        # Inner circle radius (excluding 4px white border)
        inner_radius = (button_rect.width() / 2) - 4
        
        # If click is in the inner circle, let button handle it
        # If click is in the border area, start dragging
        if click_distance <= inner_radius:
            self.old_pos = None  # Let button handle the click
        else:
            self.old_pos = event.globalPosition().toPoint()  # Start dragging

    def mouseMoveEvent(self, event):
        if self.old_pos:
            delta = event.globalPosition().toPoint() - self.old_pos
            self.move(self.x() + delta.x(), self.y() + delta.y())
            self.old_pos = event.globalPosition().toPoint()

    def mouseReleaseEvent(self, event):
        # End dragging and save position
        if self.old_pos is not None:
            self.save_position()
        self.old_pos = None
    
    def set_default_position(self):
        """Set default position: half inch down from top right corner"""
        from PyQt6.QtGui import QGuiApplication
        screen = QGuiApplication.primaryScreen()
        screen_geometry = screen.availableGeometry()
        
        # Half inch = 36 pixels (assuming 72 DPI)
        margin = 36
        x = screen_geometry.width() - self.width() - margin
        y = margin
        
        self.move(x, y)
    
    def save_position(self):
        """Save current position to config file"""
        try:
            config_file = Path.home() / ".config" / "timetracker" / "position"
            config_file.parent.mkdir(parents=True, exist_ok=True)
            
            pos = self.pos()
            with open(config_file, 'w') as f:
                f.write(f"{pos.x()},{pos.y()}")
        except Exception as e:
            print(f"Error saving position: {e}")
    
    def load_position(self):
        """Load saved position from config file"""
        try:
            config_file = Path.home() / ".config" / "timetracker" / "position"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    x, y = map(int, f.read().strip().split(','))
                    self.move(x, y)
        except Exception as e:
            print(f"Error loading position: {e}")
            # Keep default position if loading fails

class ProjectDialog(QDialog):
    def __init__(self, projects, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Select Project")
        layout = QVBoxLayout()
        
        self.combo = QComboBox()
        self.combo.addItem("New Project")
        self.combo.addItems(projects)
        self.combo.setEditable(True)
        self.combo.setInsertPolicy(QComboBox.InsertPolicy.InsertAtBottom)
        layout.addWidget(self.combo)
        
        self.new_project_input = QLineEdit()
        self.new_project_input.setPlaceholderText("Enter new project name")
        self.new_project_input.setVisible(False)
        layout.addWidget(self.new_project_input)
        
        self.combo.currentTextChanged.connect(self.on_project_changed)
        
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        
        self.setLayout(layout)
    
    def on_project_changed(self, text):
        self.new_project_input.setVisible(text == "New Project")
    
    def get_selected_project(self):
        if self.combo.currentText() == "New Project":
            return self.new_project_input.text()
        return self.combo.currentText()

class ActivityDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Select Activity Type")
        layout = QVBoxLayout()
        
        # Base legal work activity types
        base_activities = [
            "Legal research", "Investigation", "Discovery Review", 
            "File Review", "Client Communication"
        ]
        
        # Load custom activities from file
        custom_activities = self.load_custom_activities()
        
        # Combine base and custom activities, then add "Other"
        all_activities = base_activities + custom_activities + ["Other"]
        
        self.combo = QComboBox()
        self.combo.addItems(all_activities)
        self.combo.setEditable(False)  # Disable editing to force "Other" selection
        layout.addWidget(self.combo)
        
        # Text input for custom activity (initially hidden)
        self.custom_input = QLineEdit()
        self.custom_input.setPlaceholderText("Enter custom activity type")
        self.custom_input.setVisible(False)
        layout.addWidget(self.custom_input)
        
        # Connect combo box change to show/hide custom input
        self.combo.currentTextChanged.connect(self.on_activity_changed)
        
        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        
        self.setLayout(layout)
    
    def on_activity_changed(self, text):
        """Show custom input when 'Other' is selected"""
        self.custom_input.setVisible(text == "Other")
        if text == "Other":
            self.custom_input.setFocus()
    
    def load_custom_activities(self):
        """Load custom activities from config file"""
        try:
            config_file = Path.home() / ".config" / "timetracker" / "custom_activities"
            if config_file.exists():
                with open(config_file, 'r') as f:
                    return [line.strip() for line in f.readlines() if line.strip()]
            return []
        except Exception:
            return []
    
    def save_custom_activity(self, activity):
        """Save a new custom activity to config file"""
        try:
            config_file = Path.home() / ".config" / "timetracker" / "custom_activities"
            config_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Load existing activities
            existing = self.load_custom_activities()
            
            # Add new activity if not already present
            if activity not in existing:
                existing.append(activity)
                with open(config_file, 'w') as f:
                    for act in existing:
                        f.write(f"{act}\n")
        except Exception as e:
            print(f"Error saving custom activity: {e}")
    
    def get_activity(self):
        """Get the selected activity, handling custom activities"""
        selected = self.combo.currentText()
        if selected == "Other":
            custom_activity = self.custom_input.text().strip()
            if custom_activity:
                # Save the custom activity for future use
                self.save_custom_activity(custom_activity)
                return custom_activity
            else:
                return ""  # No custom activity entered
        return selected

class TrackingMenuDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Tracking Options")
        self.selected_action = None
        
        layout = QVBoxLayout()
        
        # Create buttons for each option
        change_activity_btn = QPushButton("Change Activity")
        change_project_btn = QPushButton("Change Project")
        stop_tracking_btn = QPushButton("Stop Tracking")
        
        # Connect buttons to actions
        change_activity_btn.clicked.connect(lambda: self.select_action("change_activity"))
        change_project_btn.clicked.connect(lambda: self.select_action("change_project"))
        stop_tracking_btn.clicked.connect(lambda: self.select_action("stop_tracking"))
        
        layout.addWidget(change_activity_btn)
        layout.addWidget(change_project_btn)
        layout.addWidget(stop_tracking_btn)
        
        # Cancel button
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        layout.addWidget(cancel_btn)
        
        self.setLayout(layout)
    
    def select_action(self, action):
        self.selected_action = action
        self.accept()
    
    def get_selected_action(self):
        return self.selected_action

class FloatingButton(QPushButton):
    def __init__(self):
        super().__init__()
        self.setFixedSize(120, 120)  # Circular button
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.is_tracking = False
        self.current_project = None
        self.current_activity = None
        self.start_time = None
        self.last_known_session_start = None  # Track when we last knew a session started
        
        # Setup data folder and state manager
        self.data_folder = self.get_data_folder()
        self.state_manager = StateManager(self.data_folder)
        
        self.setup_database()
        self.setup_sound()
        
        # Load initial state from database/state file
        self.sync_state()
        self.update_appearance()
        
        # Setup timers
        self.chime_timer = QTimer()
        self.chime_timer.timeout.connect(self.check_chime_time)
        self.chime_timer.setInterval(1000)  # Check every second for precise timing
        
        # State sync timer - check for external changes every 2 seconds
        self.sync_timer = QTimer()
        self.sync_timer.timeout.connect(self.sync_state)
        self.sync_timer.start(2000)  # 2 seconds
        
        # Display update timer - update time display every second when tracking
        self.display_timer = QTimer()
        self.display_timer.timeout.connect(self.update_appearance)
        self.display_timer.start(1000)  # 1 second

    def get_data_folder(self):
        config_file = Path.home() / ".config" / "timetracker" / "config"
        
        if config_file.exists():
            # Read existing config
            data_folder = config_file.read_text().strip()
        else:
            # First run - use default location
            data_folder = str(Path.home() / "Documents" / "TimeTracker")
            # Create config directory and save choice
            config_file.parent.mkdir(parents=True, exist_ok=True)
            config_file.write_text(data_folder)
        
        # Ensure data directory exists
        Path(data_folder).mkdir(parents=True, exist_ok=True)
        return data_folder

    def setup_sound(self):
        self.player = QMediaPlayer()
        self.audio_output = QAudioOutput()
        self.player.setAudioOutput(self.audio_output)
        self.audio_output.setVolume(0.5)
        
        # Try to find the sound file in the project directory
        possible_paths = [
            Path(__file__).parent / "bells-2-31725.mp3",
            Path(self.data_folder) / "bells-2-31725.mp3"
        ]
        
        sound_path = None
        for path in possible_paths:
            if path.exists():
                sound_path = path
                break
        
        if sound_path:
            self.player.setSource(QUrl.fromLocalFile(str(sound_path)))

    def play_chime(self):
        """Play chime sound with lock to prevent double chiming"""
        try:
            # Use a lock file to prevent multiple interfaces from chiming simultaneously
            lock_file = Path.home() / ".config" / "timetracker" / "chime.lock"
            lock_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Try to acquire lock (non-blocking)
            try:
                with open(lock_file, 'w') as f:
                    fcntl.flock(f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                    
                    self.player.setPosition(0)
                    self.player.play()
                    
                    # Keep lock for 2 seconds to prevent immediate double chiming
                    time.sleep(2)
                    
            except (IOError, OSError):
                # Lock is held by another process, skip chiming
                pass
                
        except Exception as e:
            print(f"Error playing chime: {e}")

    def check_chime_time(self):
        """Check if it's time to chime (every 6 minutes from start time)"""
        if not self.is_tracking or not self.start_time:
            return
            
        try:
            # Calculate elapsed time since tracking started
            elapsed = datetime.now() - self.start_time
            elapsed_seconds = int(elapsed.total_seconds())
            
            # Check if we're at a 6-minute mark (360 seconds)
            if elapsed_seconds > 0 and elapsed_seconds % 360 == 0:
                # We're exactly at a 6-minute mark - play chime
                self.play_chime()
                
        except Exception as e:
            print(f"Error checking chime time: {e}")

    def setup_database(self):
        db_path = Path(self.data_folder) / ".timetrack.db"
        self.csv_path = Path(self.data_folder) / "time_entries.csv"
        
        self.conn = sqlite3.connect(str(db_path))
        self.cursor = self.conn.cursor()
        self.cursor.execute('''
            CREATE TABLE IF NOT EXISTS time_entries (
                id INTEGER PRIMARY KEY,
                project TEXT,
                activity TEXT,
                start_time TIMESTAMP,
                end_time TIMESTAMP
            )
        ''')
        
        # Add activity column if it doesn't exist (for existing databases)
        try:
            self.cursor.execute('ALTER TABLE time_entries ADD COLUMN activity TEXT')
            self.conn.commit()
        except sqlite3.OperationalError:
            # Column already exists
            pass
        self.conn.commit()

    def sync_state(self):
        """Synchronize state with other apps"""
        try:
            # Get current state from database
            db_state = self.state_manager.get_current_state()
            if not db_state:
                return
            
            # Check if state has changed
            state_changed = False
            if db_state['is_tracking'] != self.is_tracking:
                state_changed = True
            elif db_state['is_tracking'] and db_state['project'] != self.current_project:
                state_changed = True
            
            if state_changed:
                # Check if we're starting tracking from external source
                was_tracking = self.is_tracking
                
                # Update our internal state
                self.is_tracking = db_state['is_tracking']
                self.current_project = db_state['project']
                self.current_activity = db_state.get('activity', '')
                if db_state['start_time']:
                    self.start_time = datetime.fromtimestamp(db_state['start_time'])
                else:
                    self.start_time = None
                
                # Update chime timer and play chimes for state changes
                if self.is_tracking and not was_tracking:
                    # Check if this is a new session (different start time) or just app startup
                    session_start_time = db_state['start_time']
                    if self.last_known_session_start != session_start_time:
                        # This is a new tracking session - play chime and start timer
                        self.play_chime()
                        self.last_known_session_start = session_start_time
                    # Always ensure timer is running when tracking
                    self.chime_timer.start()
                elif not self.is_tracking and was_tracking:
                    # Stopped tracking externally - play chime and stop timer
                    self.play_chime()
                    self.chime_timer.stop()
                    self.last_known_session_start = None
                elif self.is_tracking and not self.chime_timer.isActive():
                    # Already tracking but timer not active - start it (no chime)
                    self.chime_timer.start()
                elif not self.is_tracking and self.chime_timer.isActive():
                    # Not tracking but timer still active - stop it
                    self.chime_timer.stop()
                
                # Update appearance
                self.update_appearance()
            
            # Save current state to state file
            self.state_manager.save_state(db_state)
            
        except Exception as e:
            print(f"Error syncing state: {e}")

    def get_projects(self):
        self.cursor.execute('SELECT DISTINCT project FROM time_entries WHERE project NOT LIKE "[HIDDEN]%" ORDER BY project')
        projects = [row[0] for row in self.cursor.fetchall()]
        return projects

    def update_appearance(self):
        color = "red" if not self.is_tracking else "green"
        if self.is_tracking and self.current_project:
            # Calculate elapsed time
            if self.start_time:
                elapsed = datetime.now() - self.start_time
                hours = int(elapsed.total_seconds() // 3600)
                minutes = int((elapsed.total_seconds() % 3600) // 60)
                if hours > 0:
                    time_str = f"{hours}:{minutes:02d}"
                else:
                    time_str = f"{minutes}m"
                
                # Truncate project name to 13 characters
                project_name = self.current_project[:13] if len(self.current_project) > 13 else self.current_project
                text = f"{project_name}\n{time_str}"
            else:
                project_name = self.current_project[:13] if len(self.current_project) > 13 else self.current_project
                text = project_name
        else:
            text = "Not\nTracking"
            
        # Create circular button with white border
        border_color = "white"
        self.setStyleSheet(f"""
            QPushButton {{
                background-color: {color};
                border-radius: 60px;
                border: 4px solid {border_color};
                color: white;
                font-weight: bold;
                text-align: center;
            }}
        """)
        self.setText(text)

    def mousePressEvent(self, event):
        # Only accept the event if it's in the inner circle (excluding white border)
        # This allows white border clicks to pass through to the parent for dragging
        button_rect = self.rect()
        click_pos = event.position().toPoint()
        
        # Calculate distance from center for circular button
        button_center = button_rect.center()
        click_distance = ((click_pos.x() - button_center.x()) ** 2 + (click_pos.y() - button_center.y()) ** 2) ** 0.5
        
        # Inner circle radius (excluding 4px white border)
        inner_radius = (button_rect.width() / 2) - 4
        
        if click_distance <= inner_radius:
            event.accept()  # Handle button click
        else:
            event.ignore()  # Let parent handle border drag (including white border)

    def mouseMoveEvent(self, event):
        event.ignore()  # Always let parent handle mouse moves for dragging

    def mouseReleaseEvent(self, event):
        # Only handle the release if it's in the inner circle
        button_rect = self.rect()
        click_pos = event.position().toPoint()
        
        # Calculate distance from center for circular button
        button_center = button_rect.center()
        click_distance = ((click_pos.x() - button_center.x()) ** 2 + (click_pos.y() - button_center.y()) ** 2) ** 0.5
        
        # Inner circle radius (excluding 4px white border)
        inner_radius = (button_rect.width() / 2) - 4
        
        # Only process tracking changes if the release is in the inner circle
        if click_distance <= inner_radius:
            if not self.is_tracking:
                dialog = ProjectDialog(self.get_projects(), self)
                if dialog.exec() == QDialog.DialogCode.Accepted:
                    project = dialog.get_selected_project()
                    if project:  # Only start tracking if a project name was provided
                        # Prompt for activity type
                        activity_dialog = ActivityDialog(self)
                        if activity_dialog.exec() == QDialog.DialogCode.Accepted:
                            activity = activity_dialog.get_activity()
                            self.start_tracking(project, activity)
            else:
                # Show tracking options menu
                self.show_tracking_menu()

    def show_tracking_menu(self):
        """Show menu with tracking options"""
        menu_dialog = TrackingMenuDialog(self)
        if menu_dialog.exec() == QDialog.DialogCode.Accepted:
            action = menu_dialog.get_selected_action()
            if action == "change_activity":
                self.change_activity()
            elif action == "change_project":
                self.change_project()
            elif action == "stop_tracking":
                self.stop_tracking()

    def change_activity(self):
        """Change the activity for current tracking session"""
        activity_dialog = ActivityDialog(self)
        if activity_dialog.exec() == QDialog.DialogCode.Accepted:
            new_activity = activity_dialog.get_activity()
            if new_activity:
                # Update the current activity in the database
                self.cursor.execute('''
                    UPDATE time_entries 
                    SET activity = ? 
                    WHERE end_time IS NULL
                ''', (new_activity,))
                self.conn.commit()
                
                # Update internal state
                self.current_activity = new_activity
                
                # Update state file
                state = {
                    'is_tracking': True,
                    'project': self.current_project,
                    'activity': new_activity,
                    'start_time': int(self.start_time.timestamp()) if self.start_time else None
                }
                self.state_manager.save_state(state)
                
                # Regenerate CSV
                self.export_to_csv()
                
                self.update_appearance()

    def change_project(self):
        """Change the project for current tracking session"""
        dialog = ProjectDialog(self.get_projects(), self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            new_project = dialog.get_selected_project()
            if new_project:
                # Also prompt for activity when changing project
                activity_dialog = ActivityDialog(self)
                if activity_dialog.exec() == QDialog.DialogCode.Accepted:
                    new_activity = activity_dialog.get_activity()
                    if new_activity:
                        # Update both project and activity in the database
                        self.cursor.execute('''
                            UPDATE time_entries 
                            SET project = ?, activity = ? 
                            WHERE end_time IS NULL
                        ''', (new_project, new_activity))
                        self.conn.commit()
                        
                        # Update internal state
                        self.current_project = new_project
                        self.current_activity = new_activity
                        
                        # Update state file
                        state = {
                            'is_tracking': True,
                            'project': new_project,
                            'activity': new_activity,
                            'start_time': int(self.start_time.timestamp()) if self.start_time else None
                        }
                        self.state_manager.save_state(state)
                        
                        # Regenerate CSV
                        self.export_to_csv()
                        
                        self.update_appearance()

    def start_tracking(self, project, activity):
        """Start tracking a project with activity"""
        try:
            self.current_project = project
            self.current_activity = activity
            self.is_tracking = True
            self.start_time = datetime.now()
            
            # Insert into database
            self.cursor.execute('''
                INSERT INTO time_entries (project, activity, start_time)
                VALUES (?, ?, ?)
            ''', (project, activity, int(self.start_time.timestamp())))
            self.conn.commit()
            
            # Update state file
            state = {
                'is_tracking': True,
                'project': project,
                'activity': activity,
                'start_time': int(self.start_time.timestamp())
            }
            self.state_manager.save_state(state)
            
            # Play initial chime and start 6-minute chime timer
            self.play_chime()
            self.chime_timer.start()  # Will chime every 6 minutes
            self.last_known_session_start = int(self.start_time.timestamp())
            
            self.update_appearance()
            
        except Exception as e:
            print(f"Error starting tracking: {e}")

    def stop_tracking(self):
        """Stop tracking"""
        try:
            if not self.is_tracking:
                return
                
            end_time = datetime.now()
            
            # Update database
            self.cursor.execute('''
                UPDATE time_entries 
                SET end_time = ? 
                WHERE end_time IS NULL
            ''', (int(end_time.timestamp()),))
            self.conn.commit()
            
            # Export to CSV
            self.export_to_csv()
            
            # Update state
            self.is_tracking = False
            self.current_project = None
            self.current_activity = None
            self.start_time = None
            self.last_known_session_start = None
            
            # Update state file
            state = {
                'is_tracking': False,
                'project': None,
                'activity': None,
                'start_time': None
            }
            self.state_manager.save_state(state)
            
            # Play final chime and stop chime timer
            self.play_chime()
            self.chime_timer.stop()
            
            self.update_appearance()
            
        except Exception as e:
            print(f"Error stopping tracking: {e}")

    def export_to_csv(self):
        try:
            self.cursor.execute('SELECT id, project, activity, start_time, end_time FROM time_entries')
            rows = self.cursor.fetchall()
            
            # Process data for CSV with local times and durations
            csv_data = []
            for row in rows:
                id_val, project, activity, start_time, end_time = row
                
                # Convert timestamps to local datetime strings
                start_dt = datetime.fromtimestamp(start_time) if start_time else None
                end_dt = datetime.fromtimestamp(end_time) if end_time else None
                
                start_str = start_dt.strftime('%Y-%m-%d %H:%M:%S') if start_dt else ''
                end_str = end_dt.strftime('%Y-%m-%d %H:%M:%S') if end_dt else ''
                
                # Calculate duration
                duration_str = ''
                if start_dt and end_dt:
                    duration = end_dt - start_dt
                    total_seconds = int(duration.total_seconds())
                    hours = total_seconds // 3600
                    minutes = (total_seconds % 3600) // 60
                    seconds = total_seconds % 60
                    duration_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
                elif start_dt and not end_dt:
                    # Currently tracking
                    duration = datetime.now() - start_dt
                    total_seconds = int(duration.total_seconds())
                    hours = total_seconds // 3600
                    minutes = (total_seconds % 3600) // 60
                    seconds = total_seconds % 60
                    duration_str = f"{hours:02d}:{minutes:02d}:{seconds:02d} (ongoing)"
                
                csv_data.append({
                    'ID': id_val,
                    'Project': project or '',
                    'Activity': activity or '',
                    'Start Time': start_str,
                    'End Time': end_str,
                    'Duration': duration_str
                })
            
            df = pd.DataFrame(csv_data)
            df.to_csv(self.csv_path, index=False)
        except Exception as e:
            print(f"Error exporting CSV: {e}")

def main():
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)  # Keep app running when window is closed
    
    handle = DraggableHandle()
    handle.show()
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main() 